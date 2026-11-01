import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/meter_reading_service.dart';
import '../../../../core/utils/media_helper.dart';
import 'meter_widgets.dart';

enum _OcrState { idle, running, done, failed, timeout }

/// UC70 + UC71: form khai báo chỉ số một dịch vụ (điện hoặc nước) kèm ảnh đồng hồ.
/// Dùng chung cho Khách thuê (gửi → PENDING) và Quản lý tự chốt số (luồng 4a/4b).
class MeterSubmitScreen extends StatefulWidget {
  final int roomId;
  final String roomLabel;
  final int serviceId;
  final String serviceName;
  final String? unit;

  /// Khóa tháng `yyyy-MM`.
  final String monthKey;

  /// Chỉ số cũ đã biết (từ lịch sử). Màn hình vẫn hỏi lại backend để lấy số chính xác.
  final double? knownOldReading;

  /// Bản ghi hiện có của kỳ này (chờ duyệt / bị từ chối) nếu gửi lại.
  final MeterReading? existing;
  final bool isManager;

  const MeterSubmitScreen({
    super.key,
    required this.roomId,
    required this.roomLabel,
    required this.serviceId,
    required this.serviceName,
    required this.monthKey,
    this.unit,
    this.knownOldReading,
    this.existing,
    this.isManager = false,
  });

  @override
  State<MeterSubmitScreen> createState() => _MeterSubmitScreenState();
}

class _MeterSubmitScreenState extends State<MeterSubmitScreen> {
  final _newCtrl = TextEditingController();
  final _newFocus = FocusNode();

  double? _oldReading;
  bool _loadingOld = true;

  PickedImage? _image;
  bool _imageTooSmall = false;

  _OcrState _ocrState = _OcrState.idle;
  OcrSuggestion? _ocr;
  String? _ocrMessage;
  int _ocrRun = 0;

  /// Ô "Chỉ số mới" đang giữ đúng số OCR gợi ý và người dùng chưa xác nhận.
  bool _valueFromOcr = false;
  bool _ocrConfirmed = false;
  bool _settingText = false;

  bool _submitting = false;
  bool _touched = false;

  String get _billingMonth => '${widget.monthKey}-01';

  @override
  void initState() {
    super.initState();
    _oldReading = widget.knownOldReading ?? widget.existing?.oldReading;
    if (widget.existing?.newReading != null && !widget.existing!.isRejected) {
      _newCtrl.text = _plain(widget.existing!.newReading!);
    }
    _newCtrl.addListener(_onNewChanged);
    _loadOldReading();
  }

  @override
  void dispose() {
    _newCtrl.removeListener(_onNewChanged);
    _newCtrl.dispose();
    _newFocus.dispose();
    super.dispose();
  }

  String _plain(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  void _onNewChanged() {
    if (_settingText) return;
    setState(() {
      _touched = true;
      // Người dùng tự sửa số → coi như đã tự chịu trách nhiệm (BR71.6).
      if (_valueFromOcr) _valueFromOcr = false;
    });
  }

  Future<void> _loadOldReading() async {
    try {
      final v = await MeterReadingApi.oldReading(roomId: widget.roomId, serviceId: widget.serviceId);
      if (mounted && v != null) setState(() => _oldReading = v);
    } catch (_) {
      // Giữ số đã biết; backend vẫn tự xác định chỉ số cũ khi lưu.
    } finally {
      if (mounted) setState(() => _loadingOld = false);
    }
  }

  // ── Ảnh & OCR ─────────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final picked = await MediaHelper.pickImage(context);
    if (picked == null || !mounted) return;
    var tooSmall = false;
    try {
      final img = await decodeImageFromList(Uint8List.fromList(picked.bytes));
      tooSmall = !MeterRules.isImageResolutionOk(img.width, img.height);
      img.dispose();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _image = picked;
      _imageTooSmall = tooSmall;
    });
    _runOcr();
  }

  Future<void> _runOcr() async {
    final image = _image;
    if (image == null) return;
    final run = ++_ocrRun;
    setState(() {
      _ocrState = _OcrState.running;
      _ocr = null;
      _ocrMessage = null;
    });
    try {
      final s = await MeterReadingApi.recognize(
        roomId: widget.roomId,
        serviceId: widget.serviceId,
        billingMonth: _billingMonth,
        base64Image: image.base64,
        mimeType: MeterRules.mimeTypeFor(image.name),
      );
      if (!mounted || run != _ocrRun) return;
      _settingText = true;
      _newCtrl.text = _plain(s.value);
      _settingText = false;
      setState(() {
        _ocr = s;
        _ocrState = _OcrState.done;
        _valueFromOcr = true;
        _ocrConfirmed = false;
        _touched = true;
        if (s.oldReading != null) _oldReading = s.oldReading;
      });
    } on OcrTimeoutException catch (e) {
      if (!mounted || run != _ocrRun) return;
      setState(() {
        _ocrState = _OcrState.timeout;
        _ocrMessage = e.toString();
      });
      _newFocus.requestFocus();
    } catch (_) {
      if (!mounted || run != _ocrRun) return;
      setState(() {
        _ocrState = _OcrState.failed;
        _ocrMessage = 'Không thể đọc số từ ảnh, vui lòng chụp lại hoặc nhập thủ công.';
      });
    }
  }

  /// Người dùng hủy chờ OCR để nhập tay ngay.
  void _cancelOcr() {
    _ocrRun++;
    setState(() {
      _ocrState = _OcrState.idle;
      _ocrMessage = null;
    });
    _newFocus.requestFocus();
  }

  void _confirmOcr() => setState(() => _ocrConfirmed = true);

  void _editOcr() {
    setState(() => _valueFromOcr = false);
    _newFocus.requestFocus();
    _newCtrl.selection = TextSelection(baseOffset: 0, extentOffset: _newCtrl.text.length);
  }

  // ── Gửi ───────────────────────────────────────────────────────────────────

  bool get _hasEvidence => _image != null || widget.existing?.imageUrl != null;

  String? get _validation => MeterRules.validateNewReading(_oldReading, _newCtrl.text);

  bool get _awaitingOcrConfirm => _valueFromOcr && !_ocrConfirmed;

  bool get _canSubmit =>
      !_submitting &&
      _ocrState != _OcrState.running &&
      _hasEvidence &&
      _validation == null &&
      !_awaitingOcrConfirm;

  Future<void> _submit() async {
    setState(() => _touched = true);
    if (!_canSubmit) return;
    final value = MeterRules.parseInput(_newCtrl.text)!;

    if (widget.isManager) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Chốt chỉ số?'),
          content: Text(
            '${widget.serviceName} phòng ${widget.roomLabel}: ${MeterRules.formatReading(value)}.\n'
            'Chỉ số do Quản lý tự chốt được duyệt ngay và dùng để tính hóa đơn.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Xem lại')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: MeterTone.confirm),
              child: const Text('Chốt số'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }

    setState(() => _submitting = true);
    try {
      final saved = await MeterReadingApi.submit(
        roomId: widget.roomId,
        serviceId: widget.serviceId,
        billingMonth: _billingMonth,
        newReading: value,
        base64Image: _image?.base64,
        mimeType: _image == null ? null : MeterRules.mimeTypeFor(_image!.name),
      );
      if (!mounted) return;
      Navigator.pop(context, saved);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không gửi được: ${meterErrorText(e)}'), backgroundColor: MeterTone.dangerText),
      );
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.isManager ? 'Chốt số ${widget.serviceName}' : 'Khai báo ${widget.serviceName}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text('Phòng ${widget.roomLabel} · ${MeterRules.monthLabel(widget.monthKey)}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.borderLight),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (existing != null && existing.isRejected) ...[
            MeterNotice.danger(
              'Quản lý đã từ chối chỉ số trước'
              '${existing.rejectReason != null ? ': "${existing.rejectReason}"' : ''}. Vui lòng chụp lại và gửi lại.',
            ),
            const SizedBox(height: 12),
          ],
          if (existing != null && existing.isPending) ...[
            MeterNotice.info('Bạn đã gửi chỉ số kỳ này và đang chờ duyệt. Gửi lại sẽ thay thế bản đã gửi.'),
            const SizedBox(height: 12),
          ],
          _buildPhotoCard(),
          const SizedBox(height: 12),
          _buildOcrFeedback(),
          _buildReadingCard(),
          const SizedBox(height: 20),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MeterTone.mist),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: child,
      );

  Widget _buildPhotoCard() {
    final existingUrl = widget.existing?.imageUrl;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MeterServiceIcon(widget.serviceName),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ảnh mặt đồng hồ',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: MeterTone.heading)),
                    SizedBox(height: 2),
                    Text('Chụp rõ, thẳng, đủ sáng để hệ thống đọc số',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_image != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.memory(Uint8List.fromList(_image!.bytes), fit: BoxFit.cover),
                  ),
                ),
                if (_ocrState == _OcrState.running)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.45),
                        alignment: Alignment.center,
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)),
                            SizedBox(height: 10),
                            Text('Đang nhận diện chỉ số…',
                                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                            Text('Tối đa 5 giây', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            )
          else if (existingUrl != null)
            Row(
              children: [
                MeterImageThumb(url: existingUrl, size: 72),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Đang dùng ảnh đã gửi trước. Chụp ảnh mới nếu số đã thay đổi.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
                ),
              ],
            )
          else
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              alignment: Alignment.center,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_camera_outlined, size: 32, color: AppColors.textSecondaryLight),
                  SizedBox(height: 6),
                  Text('Chưa có ảnh đồng hồ', style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
                ],
              ),
            ),
          const SizedBox(height: 12),
          if (_ocrState == _OcrState.running)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _cancelOcr,
                icon: const Icon(Icons.keyboard_rounded, size: 18),
                label: const Text('Bỏ qua, nhập tay'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  foregroundColor: AppColors.textPrimaryLight,
                  side: const BorderSide(color: AppColors.borderLight),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _pickImage,
                icon: const Icon(Icons.document_scanner_outlined, size: 18),
                label: Text(_image == null ? 'Chụp/Tải ảnh & Nhận diện' : 'Chụp lại ảnh'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  backgroundColor: AppColors.primary,
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          if (_imageTooSmall) ...[
            const SizedBox(height: 12),
            MeterNotice.warning(
                'Ảnh có độ phân giải thấp (dưới 640×480), kết quả đọc số có thể sai. Nên chụp lại gần và rõ hơn.'),
          ],
          if (_touched && !_hasEvidence) ...[
            const SizedBox(height: 12),
            MeterNotice.danger('Cần ảnh đồng hồ làm minh chứng trước khi gửi.'),
          ],
        ],
      ),
    );
  }

  Widget _buildOcrFeedback() {
    Widget? child;
    switch (_ocrState) {
      case _OcrState.failed:
        child = MeterNotice.warning(
          _ocrMessage ?? '',
          trailing: TextButton(onPressed: _runOcr, child: const Text('Thử lại')),
        );
        break;
      case _OcrState.timeout:
        child = MeterNotice.warning(
          _ocrMessage ?? '',
          trailing: TextButton(onPressed: _runOcr, child: const Text('Thử lại')),
        );
        break;
      case _OcrState.done:
        final s = _ocr!;
        child = _buildOcrResult(s);
        break;
      default:
        child = null;
    }
    if (child == null) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: child);
  }

  Widget _buildOcrResult(OcrSuggestion s) {
    final low = s.isLowConfidence;
    final review = s.needsReview;
    final ink = low ? MeterTone.dangerText : (review ? MeterTone.warningText : MeterTone.successText);
    final fill = low ? AppColors.danger : (review ? AppColors.warning : AppColors.success);
    final confirmed = _ocrConfirmed || !_valueFromOcr;
    final message = low
        ? 'Kết quả có thể không chính xác, vui lòng kiểm tra kỹ.'
        : review
            ? 'Độ tin cậy dưới 90%. Hãy đối chiếu với ảnh trước khi xác nhận.'
            : 'Nhận diện AI thành công. Vui lòng xác nhận lại chỉ số.';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fill.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 18, color: ink),
              const SizedBox(width: 8),
              Expanded(
                child: Text('AI đọc được: ${MeterRules.formatReading(s.value)}',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ink)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: Text('Tin cậy ${s.confidence.toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ink)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(message, style: TextStyle(fontSize: 13, color: ink, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          if (confirmed)
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, size: 18, color: MeterTone.successText),
                const SizedBox(width: 6),
                Text(_valueFromOcr ? 'Bạn đã xác nhận số này' : 'Bạn đã sửa lại số',
                    style: const TextStyle(fontSize: 13, color: MeterTone.successText, fontWeight: FontWeight.w700)),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _editOcr,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      foregroundColor: AppColors.textPrimaryLight,
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.borderLight),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Sửa lại'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _confirmOcr,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Xác nhận', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildReadingCard() {
    final newVal = MeterRules.parseInput(_newCtrl.text);
    final consumption =
        (newVal != null && _oldReading != null) ? MeterRules.consumption(_oldReading!, newVal) : null;
    final error = _touched ? _validation : null;
    final ocrLow = _valueFromOcr && _ocr != null && _ocr!.needsReview;
    final highlight = ocrLow ? (_ocr!.isLowConfidence ? AppColors.danger : AppColors.warning) : null;
    final unit = (widget.unit == null || widget.unit!.isEmpty) ? '' : ' ${widget.unit}';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chỉ số', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: MeterTone.heading)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Chỉ số cũ',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      _loadingOld && _oldReading == null
                          ? const SizedBox(
                              height: 26, child: Align(alignment: Alignment.centerLeft, child: LinearProgressIndicator()))
                          : Text(
                              MeterRules.formatReading(_oldReading),
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: MeterTone.heading),
                            ),
                      const Text('Tự điền từ kỳ trước',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _newCtrl,
                  focusNode: _newFocus,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight),
                  decoration: InputDecoration(
                    labelText: 'Chỉ số mới',
                    labelStyle: const TextStyle(fontSize: 13),
                    filled: true,
                    fillColor: highlight != null ? highlight.withValues(alpha: 0.08) : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: highlight ?? AppColors.borderLight, width: highlight != null ? 1.5 : 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: highlight ?? AppColors.primary, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.danger),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            MeterNotice.danger(error),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Tiêu thụ kỳ này',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(
                consumption == null || consumption < 0 ? '—' : '${MeterRules.formatReading(consumption)}$unit',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    String? hint;
    if (_ocrState == _OcrState.running) {
      hint = 'Đang nhận diện, vui lòng chờ hoặc bấm "Bỏ qua, nhập tay".';
    } else if (_awaitingOcrConfirm) {
      hint = 'Bấm "Xác nhận" hoặc sửa lại số AI đọc được trước khi gửi.';
    } else if (!_hasEvidence) {
      hint = 'Cần chụp ảnh đồng hồ trước khi gửi.';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hint != null) ...[
          Text(hint,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
          const SizedBox(height: 8),
        ],
        FilledButton.icon(
          onPressed: _canSubmit ? _submit : null,
          icon: _submitting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Icon(widget.isManager ? Icons.task_alt_rounded : Icons.send_rounded, size: 18),
          label: Text(widget.isManager ? 'Chốt chỉ số' : 'Gửi chỉ số'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 52),
            backgroundColor: widget.isManager ? MeterTone.confirm : AppColors.primary,
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        if (!widget.isManager) ...[
          const SizedBox(height: 8),
          const Text('Sau khi gửi, chỉ số ở trạng thái "Chờ duyệt" cho đến khi Quản lý duyệt.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
        ],
      ],
    );
  }
}
