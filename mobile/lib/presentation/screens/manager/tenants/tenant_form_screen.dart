import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/resident_service.dart';
import '../../../../core/utils/media_helper.dart';
import 'tenant_ui.dart';

/// UC49 (thêm khách mới) và UC53 (cập nhật hồ sơ) — màn hình toàn trang,
/// chia thành các bước đánh số để người dùng trung niên làm lần lượt.
class TenantFormScreen extends StatefulWidget {
  /// null = thêm mới; khác null = chỉnh sửa hồ sơ.
  final ResidentResult? editing;
  const TenantFormScreen({super.key, this.editing});

  bool get isEditing => editing != null;

  @override
  State<TenantFormScreen> createState() => _TenantFormScreenState();
}

class _TenantFormScreenState extends State<TenantFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _idCard;
  late final TextEditingController _email;
  late final TextEditingController _notes;

  DateTime? _dob;
  String? _gender;

  PickedImage? _front;
  PickedImage? _back;
  PickedImage? _avatar;

  bool _ocrRunning = false;
  String? _ocrMessage;
  bool _saving = false;

  List<LinkableContract> _contracts = const [];
  bool _contractsLoading = false;
  String? _contractsError;
  int? _contractId;

  @override
  void initState() {
    super.initState();
    final r = widget.editing;
    _name = TextEditingController(text: r?.fullName ?? '');
    _phone = TextEditingController(text: r?.phone ?? '');
    _idCard = TextEditingController(text: r?.idCardNumber ?? '');
    _email = TextEditingController(text: r?.email ?? '');
    _notes = TextEditingController(text: r?.notes ?? '');
    _dob = r?.dateOfBirth;
    _gender = r?.gender;
    if (!widget.isEditing) _loadContracts();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _idCard.dispose();
    _email.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _loadContracts() async {
    setState(() {
      _contractsLoading = true;
      _contractsError = null;
    });
    try {
      final list = await ResidentService.linkableContracts();
      if (!mounted) return;
      setState(() => _contracts = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _contractsError = tenantErrorText(e));
    } finally {
      if (mounted) setState(() => _contractsLoading = false);
    }
  }

  // ── Ảnh ─────────────────────────────────────────────────────────────────────

  Future<void> _pickFront() async {
    final img = await MediaHelper.pickImage(context, maxWidth: 1280, imageQuality: 75);
    if (img == null || !mounted) return;
    setState(() => _front = img);
    if (!widget.isEditing) await _runOcr(img);
  }

  Future<void> _pickBack() async {
    final img = await MediaHelper.pickImage(context, maxWidth: 1280, imageQuality: 75);
    if (img == null || !mounted) return;
    setState(() => _back = img);
  }

  Future<void> _pickAvatar() async {
    final img = await MediaHelper.pickImage(context, maxWidth: 480, imageQuality: 75);
    if (img == null || !mounted) return;
    setState(() => _avatar = img);
  }

  /// Đọc CCCD mặt trước để điền sẵn họ tên, số CCCD, ngày sinh.
  Future<void> _runOcr(PickedImage img) async {
    setState(() {
      _ocrRunning = true;
      _ocrMessage = null;
    });
    try {
      final r = await ResidentService.ocrIdCard(base64Image: img.base64);
      if (!mounted) return;
      final filled = <String>[];
      if (r.fullName.isNotEmpty) {
        _name.text = r.fullName;
        filled.add('họ tên');
      }
      if (r.idCardNumber.isNotEmpty) {
        _idCard.text = r.idCardNumber;
        filled.add('số CCCD');
      }
      if (r.dateOfBirth != null) {
        _dob = r.dateOfBirth;
        filled.add('ngày sinh');
      }
      setState(() {
        _ocrMessage = filled.isEmpty
            ? 'Không đọc được chữ trên ảnh. Vui lòng nhập tay ở bước 2.'
            : 'Đã tự điền ${filled.join(', ')}. Vui lòng kiểm tra lại.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _ocrMessage = 'Chưa đọc được CCCD (${tenantErrorText(e)}). Vui lòng nhập tay.');
    } finally {
      if (mounted) setState(() => _ocrRunning = false);
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      helpText: 'Chọn ngày sinh',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
      initialEntryMode: DatePickerEntryMode.input,
      fieldHintText: 'ngày/tháng/năm',
    );
    if (picked != null) setState(() => _dob = picked);
  }

  // ── Lưu ─────────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      _snack('Vui lòng sửa các ô được tô đỏ.', TenantTone.amber.fg);
      return;
    }
    final dobError = ResidentValidators.dateOfBirth(_dob);
    if (dobError != null) {
      _snack(dobError, TenantTone.amber.fg);
      return;
    }
    setState(() => _saving = true);
    try {
      ResidentResult saved;
      if (widget.isEditing) {
        final body = ResidentService.buildUpdateBody(
          original: widget.editing!,
          phone: _phone.text,
          email: _email.text,
          notes: _notes.text,
          dateOfBirth: _dob,
          gender: _gender,
          avatarUrl: _avatar != null ? toDataImageUri(_avatar!.base64) : null,
        );
        if (_front != null) body['idCardFrontUrl'] = toDataImageUri(_front!.base64);
        if (_back != null) body['idCardBackUrl'] = toDataImageUri(_back!.base64);
        if (body.isEmpty) {
          if (mounted) Navigator.pop(context, widget.editing);
          return;
        }
        saved = await ResidentService.update(widget.editing!.userId, body);
      } else {
        saved = await ResidentService.create(
          fullName: _name.text,
          phone: _phone.text,
          idCardNumber: _idCard.text,
          email: _email.text,
          idCardFrontUrl: _front != null ? toDataImageUri(_front!.base64) : null,
          idCardBackUrl: _back != null ? toDataImageUri(_back!.base64) : null,
          dateOfBirth: _dob,
          gender: _gender,
          notes: _notes.text,
          avatarUrl: _avatar != null ? toDataImageUri(_avatar!.base64) : null,
          contractId: _contractId,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, saved);
    } catch (e) {
      if (!mounted) return;
      _snack(_friendlyError(e), AppColors.danger);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _friendlyError(Object e) {
    final t = tenantErrorText(e);
    if (t.contains('Phone already registered') || t.contains('PHONE_EXISTS')) {
      return 'Số điện thoại này đã có tài khoản khác dùng.';
    }
    if (t.contains('ID card number already exists')) {
      return 'Số CCCD này đã có trong hồ sơ khác.';
    }
    return 'Không lưu được: $t';
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final editing = widget.isEditing;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(editing ? 'Sửa hồ sơ khách' : 'Thêm khách thuê mới'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: editing ? _editSections() : _createSections(),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.borderLight)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Hủy', style: TextStyle(fontSize: 15)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_rounded),
                  label: Text(editing ? 'Lưu thay đổi' : 'Lưu hồ sơ',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _createSections() => [
        _step(1, 'Chụp ảnh CCCD',
            'Chụp mặt trước để app tự điền họ tên, số CCCD và ngày sinh.', _idCardPhotos()),
        _step(2, 'Thông tin cá nhân', 'Các ô có dấu * là bắt buộc.', _personalFields(editing: false)),
        _step(3, 'Ảnh đại diện', 'Không bắt buộc. Giúp nhận ra khách nhanh hơn.', _avatarPicker()),
        _step(4, 'Gắn vào phòng / hợp đồng',
            'Không bắt buộc. Chọn nếu khách vào ở chung phòng đã có hợp đồng.', _contractPicker()),
        _infoNote(Icons.lock_outline_rounded,
            'Khách đăng nhập bằng số điện thoại, mật khẩu ban đầu là số điện thoại. '
            'Khách sẽ được yêu cầu đổi mật khẩu ở lần đăng nhập đầu tiên.'),
      ];

  List<Widget> _editSections() => [
        _step(1, 'Thông tin liên hệ', 'Có thể sửa số điện thoại, email và ghi chú.',
            _personalFields(editing: true)),
        _step(2, 'Ảnh đại diện và ảnh CCCD', 'Chỉ chọn ảnh nếu muốn thay ảnh cũ.',
            Column(children: [
              _avatarPicker(),
              const SizedBox(height: 16),
              _idCardPhotos(),
            ])),
      ];

  Widget _step(int n, String title, String subtitle, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TenantCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$n',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 15)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(subtitle,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight, height: 1.4)),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _idCardPhotos() {
    final r = widget.editing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _photoSlot(
                label: 'Mặt trước',
                picked: _front,
                existingUrl: r?.idCardFrontUrl,
                onPick: _pickFront,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _photoSlot(
                label: 'Mặt sau',
                picked: _back,
                existingUrl: r?.idCardBackUrl,
                onPick: _pickBack,
              ),
            ),
          ],
        ),
        if (_ocrRunning) ...[
          const SizedBox(height: 12),
          const Row(children: [
            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 10),
            Expanded(
                child: Text('Đang đọc thông tin trên CCCD...',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight))),
          ]),
        ],
        if (_ocrMessage != null && !_ocrRunning) ...[
          const SizedBox(height: 12),
          _infoNote(Icons.auto_fix_high_rounded, _ocrMessage!, tone: TenantTone.blue),
        ],
        if (!widget.isEditing && _front != null && !_ocrRunning) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _runOcr(_front!),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Đọc lại thông tin từ ảnh mặt trước'),
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          ),
        ],
      ],
    );
  }

  Widget _photoSlot({
    required String label,
    required PickedImage? picked,
    required String? existingUrl,
    required VoidCallback onPick,
  }) {
    final hasImage = picked != null || (existingUrl != null && existingUrl.isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TenantImageBox(label: label, bytes: picked?.bytes, url: picked == null ? existingUrl : null),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onPick,
          icon: Icon(hasImage ? Icons.cameraswitch_outlined : Icons.photo_camera_outlined, size: 20),
          label: Text(hasImage ? 'Chụp lại' : 'Chụp ảnh'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  Widget _avatarPicker() {
    final r = widget.editing;
    final name = _name.text.isEmpty ? (r?.fullName ?? 'K') : _name.text;
    final avatar = _avatar != null
        ? CircleAvatar(radius: 34, backgroundImage: MemoryImage(Uint8List.fromList(_avatar!.bytes)))
        : TenantAvatar(name: name, imageUrl: r?.avatarUrl, radius: 34);
    return Row(
      children: [
        avatar,
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _pickAvatar,
            icon: const Icon(Icons.add_a_photo_outlined, size: 20),
            label: Text(_avatar != null || (r?.avatarUrl != null) ? 'Đổi ảnh đại diện' : 'Chọn ảnh đại diện'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _personalFields({required bool editing}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (editing) ...[
          _lockedField('Họ và tên', _name.text),
          const SizedBox(height: 12),
          _lockedField('Số CCCD', _idCard.text.isEmpty ? '—' : _idCard.text),
          const SizedBox(height: 8),
          _infoNote(Icons.info_outline_rounded,
              'Họ tên và số CCCD là thông tin pháp lý, không sửa trực tiếp được. '
              'Cần yêu cầu chỉnh sửa (kèm giấy tờ) để được duyệt.',
              tone: TenantTone.amber),
          const SizedBox(height: 16),
        ] else ...[
          _input(_name, 'Họ và tên *', Icons.person_outline,
              hint: 'Nguyễn Văn A',
              validator: ResidentValidators.fullName,
              capitalization: TextCapitalization.words),
          const SizedBox(height: 14),
          _input(_idCard, 'Số CCCD *', Icons.badge_outlined,
              hint: '12 chữ số',
              validator: ResidentValidators.idCard,
              keyboard: TextInputType.number,
              formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(12)]),
          const SizedBox(height: 14),
        ],
        _input(_phone, 'Số điện thoại *', Icons.phone_outlined,
            hint: '0901234567',
            validator: ResidentValidators.phone,
            keyboard: TextInputType.phone,
            formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)]),
        if (editing && _phone.text != widget.editing!.phone)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('Lưu ý: khách sẽ đăng nhập bằng số điện thoại mới.',
                style: TextStyle(fontSize: 13, color: Color(0xFFB45309))),
          ),
        const SizedBox(height: 14),
        _input(_email, 'Email (không bắt buộc)', Icons.email_outlined,
            hint: 'email@example.com',
            validator: ResidentValidators.email,
            keyboard: TextInputType.emailAddress),
        const SizedBox(height: 14),
        _label('Ngày sinh'),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: _pickDob,
          icon: const Icon(Icons.cake_outlined, size: 20),
          label: Align(
            alignment: Alignment.centerLeft,
            child: Text(_dob == null ? 'Chọn ngày sinh' : TenantFormat.date(_dob),
                style: TextStyle(
                    fontSize: 15,
                    color: _dob == null ? AppColors.textSecondaryLight : const Color(0xFF1E293B))),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            alignment: Alignment.centerLeft,
            foregroundColor: AppColors.textSecondaryLight,
            side: const BorderSide(color: AppColors.borderLight),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 14),
        _label('Giới tính'),
        const SizedBox(height: 6),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'MALE', label: Text('Nam')),
            ButtonSegment(value: 'FEMALE', label: Text('Nữ')),
            ButtonSegment(value: 'OTHER', label: Text('Khác')),
          ],
          emptySelectionAllowed: true,
          selected: _gender == null ? <String>{} : {_gender!},
          onSelectionChanged: (s) => setState(() => _gender = s.isEmpty ? null : s.first),
          style: SegmentedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            selectedBackgroundColor: AppColors.primary.withValues(alpha: 0.12),
            selectedForegroundColor: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 14),
        _input(_notes, 'Ghi chú', Icons.sticky_note_2_outlined,
            hint: 'Ví dụ: đi làm ca đêm, có xe máy biển số...', maxLines: 3),
      ],
    );
  }

  Widget _contractPicker() {
    if (_contractsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 10),
          Text('Đang tải danh sách hợp đồng...', style: TextStyle(fontSize: 13)),
        ]),
      );
    }
    if (_contractsError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Không tải được hợp đồng: $_contractsError',
              style: const TextStyle(fontSize: 13, color: Color(0xFFB91C1C))),
          TextButton(onPressed: _loadContracts, child: const Text('Thử lại')),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<int?>(
          initialValue: _contractId,
          isExpanded: true,
          decoration: _decoration('Phòng / hợp đồng', Icons.meeting_room_outlined),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('Chưa gắn phòng')),
            ..._contracts.map((c) => DropdownMenuItem<int?>(
                  value: c.id,
                  child: Text(
                    '${c.label}${c.primaryResidentName != null ? ' (${c.primaryResidentName})' : ''}'
                    '${c.status == 'DRAFT' ? ' · chờ cọc' : ''}',
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
          ],
          onChanged: (v) => setState(() => _contractId = v),
        ),
        const SizedBox(height: 8),
        Text(
          _contracts.isEmpty
              ? 'Chưa có hợp đồng nào đang mở. Nếu khách thuê phòng mới, hãy lưu hồ sơ rồi lập hợp đồng ở mục Hợp đồng.'
              : 'Nếu khách thuê phòng mới (chưa có hợp đồng), hãy để "Chưa gắn phòng" rồi lập hợp đồng ở mục Hợp đồng.',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight, height: 1.4),
        ),
      ],
    );
  }

  Widget _lockedField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(value,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
              ),
              const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textSecondaryLight),
            ],
          ),
        ),
      ],
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151)));

  InputDecoration _decoration(String label, IconData icon, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(fontSize: 14),
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.borderLight)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.borderLight)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorStyle: const TextStyle(fontSize: 13, color: Color(0xFFB91C1C)),
      );

  Widget _input(
    TextEditingController c,
    String label,
    IconData icon, {
    String? hint,
    String? Function(String?)? validator,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
    int maxLines = 1,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: c,
      validator: validator,
      keyboardType: maxLines > 1 ? TextInputType.multiline : keyboard,
      inputFormatters: formatters,
      maxLines: maxLines,
      textCapitalization: capitalization,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
      decoration: _decoration(label, icon, hint: hint),
    );
  }

  Widget _infoNote(IconData icon, String text, {TenantTone tone = TenantTone.slate}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: tone.fg),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: tone.fg, height: 1.4))),
        ],
      ),
    );
  }
}
