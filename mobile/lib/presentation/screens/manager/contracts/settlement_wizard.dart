import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/contract_service.dart';
import '../../../../core/services/invoice_service.dart';
import '../../../../core/services/settlement_service.dart';
import '../../../../core/utils/media_helper.dart';
import 'contract_ui.dart';

class _DamageDraft {
  final TextEditingController name = TextEditingController();
  final TextEditingController fee = TextEditingController();
  PickedImage? photo;

  DamageItem toItem() => DamageItem(
        itemName: name.text,
        penaltyFee: Fmt.parseMoney(fee.text) ?? 0,
        imageBase64: photo?.base64,
      );

  void dispose() {
    name.dispose();
    fee.dispose();
  }
}

/// UC80 – Tất toán hợp đồng theo từng bước:
/// 1. Chốt chỉ số cuối → 2. Kiểm kê hư hỏng (ảnh bằng chứng bắt buộc) →
/// 3. Bảng kê tất toán → 4. Xác nhận hoàn cọc / thu thêm và thanh lý hợp đồng.
class SettlementWizard extends StatefulWidget {
  final ContractDetailResult contract;
  const SettlementWizard({super.key, required this.contract});

  @override
  State<SettlementWizard> createState() => _SettlementWizardState();
}

class _SettlementWizardState extends State<SettlementWizard> {
  static const _titles = ['Chốt chỉ số cuối', 'Kiểm kê hư hỏng', 'Bảng kê tất toán', 'Xác nhận'];

  int _step = 0;
  late DateTime _moveOut;
  final _electric = TextEditingController();
  final _water = TextEditingController();
  double? _prevElectric;
  double? _prevWater;
  final List<_DamageDraft> _damages = [];
  SettlementCalculation? _calc;
  SettlementConfirmation? _result;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _moveOut = DateTime.tryParse(widget.contract.intendedMoveOutDate ?? '') ?? DateTime.now();
    _loadPreviousReadings();
  }

  @override
  void dispose() {
    _electric.dispose();
    _water.dispose();
    for (final d in _damages) {
      d.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPreviousReadings() async {
    try {
      final res = await MeterReadingService.list(roomId: widget.contract.roomId, status: 'APPROVED', size: 100);
      final list = res.content.toList()..sort((a, b) => b.billingMonth.compareTo(a.billingMonth));
      double? e;
      double? w;
      for (final r in list) {
        final name = r.serviceName.toLowerCase();
        if (e == null && name.contains('điện')) e = r.newReading;
        if (w == null && name.contains('nước')) w = r.newReading;
      }
      if (mounted) {
        setState(() {
          _prevElectric = e;
          _prevWater = w;
        });
      }
    } catch (_) {}
  }

  List<DamageItem> get _items => _damages.map((d) => d.toItem()).toList();

  String? _validateStep() {
    switch (_step) {
      case 0:
        return SettlementMath.validateReading('điện', Fmt.parseMoney(_electric.text), previous: _prevElectric) ??
            SettlementMath.validateReading('nước', Fmt.parseMoney(_water.text), previous: _prevWater);
      case 1:
        return SettlementMath.validateDamages(_items);
    }
    return null;
  }

  Future<void> _next() async {
    final err = _validateStep();
    setState(() => _error = err);
    if (err != null) return;
    if (_step == 1) {
      await _calculate();
      return;
    }
    if (_step == 3) {
      await _confirm();
      return;
    }
    setState(() => _step++);
  }

  Future<void> _calculate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final calc = await SettlementService.calculate(
        widget.contract.id,
        moveOutDate: _moveOut,
        finalElectricReading: Fmt.parseMoney(_electric.text) ?? 0,
        finalWaterReading: Fmt.parseMoney(_water.text) ?? 0,
        damages: _items,
      );
      if (mounted) {
        setState(() {
          _calc = calc;
          _step = 2;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = Fmt.errorText(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirm() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await SettlementService.confirm(
        widget.contract.id,
        moveOutDate: _moveOut,
        finalElectricReading: Fmt.parseMoney(_electric.text) ?? 0,
        finalWaterReading: Fmt.parseMoney(_water.text) ?? 0,
        damages: _items,
      );
      if (mounted) setState(() => _result = res);
    } catch (e) {
      if (mounted) setState(() => _error = Fmt.errorText(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) return _buildDone(_result!);
    final c = widget.contract;
    return PopScope(
      canPop: _step == 0 && !_loading,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_loading && _step > 0) setState(() => _step--);
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(title: Text('Tất toán ${c.displayCode}')),
        body: Column(
          children: [
            StepProgress(current: _step, titles: _titles),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_step == 0) _stepReadings(),
                  if (_step == 1) _stepDamages(),
                  if (_step == 2 && _calc != null) _stepStatement(_calc!),
                  if (_step == 3 && _calc != null) _stepConfirm(_calc!),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    NoticeBox(text: _error!, tone: Tone.red, icon: Icons.error_outline_rounded),
                  ],
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: WizardBottomBar(
          onBack: _step == 0 ? null : () => setState(() => _step--),
          onNext: _next,
          loading: _loading,
          confirm: _step == 3,
          nextLabel: switch (_step) {
            1 => 'Tính bảng kê',
            3 => (_calc?.outcome == SettlementOutcome.collectMore)
                ? 'Tạo hóa đơn thu thêm & Tất toán'
                : 'Xác nhận đã hoàn tiền & Tất toán',
            _ => 'Tiếp tục',
          },
        ),
      ),
    );
  }

  Widget _stepReadings() {
    return SectionCard(
      title: 'Ngày trả phòng & chỉ số cuối',
      icon: Icons.speed_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DateField(
            label: 'Ngày trả phòng',
            value: _moveOut,
            onTap: () async {
              final d = await pickDate(context, initial: _moveOut, first: DateTime.tryParse(widget.contract.startDate));
              if (d != null) setState(() => _moveOut = d);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _electric,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Chỉ số điện cuối (kWh) *',
              helperText: _prevElectric != null ? 'Kỳ trước: ${_prevElectric!.toStringAsFixed(0)}' : null,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _water,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Chỉ số nước cuối (m³) *',
              helperText: _prevWater != null ? 'Kỳ trước: ${_prevWater!.toStringAsFixed(0)}' : null,
            ),
          ),
          const SizedBox(height: 12),
          const NoticeBox(text: 'Quản lý cần trực tiếp xem đồng hồ tại phòng. Hệ thống tự tính tiền điện nước và tiền phòng lẻ ngày.'),
        ],
      ),
    );
  }

  Widget _stepDamages() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NoticeBox(
          text: 'Nếu phòng không có hư hỏng, bấm "Tính bảng kê". Mỗi khoản khấu trừ phải kèm ít nhất 1 ảnh hiện trạng.',
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < _damages.length; i++) _damageCard(i, _damages[i]),
        OutlinedButton.icon(
          onPressed: () => setState(() => _damages.add(_DamageDraft())),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Thêm hạng mục hư hỏng'),
        ),
        if (_damages.isNotEmpty) ...[
          const SizedBox(height: 12),
          InfoRow(label: 'Tổng phí hư hỏng', value: Fmt.vnd(SettlementMath.repairTotal(_items)), emphasize: true),
        ],
      ],
    );
  }

  Widget _damageCard(int index, _DamageDraft d) {
    return SectionCard(
      title: 'Hạng mục ${index + 1}',
      icon: Icons.build_circle_outlined,
      trailing: IconButton(
        tooltip: 'Xóa hạng mục',
        icon: const Icon(Icons.delete_outline_rounded, color: ContractTokens.redText),
        onPressed: () => setState(() {
          _damages.removeAt(index).dispose();
        }),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(controller: d.name, decoration: const InputDecoration(labelText: 'Tên hư hỏng / mất mát')),
          const SizedBox(height: 10),
          TextField(
            controller: d.fee,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Số tiền khấu trừ (đ)'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (d.photo != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(Uint8List.fromList(d.photo!.bytes), width: 64, height: 64, fit: BoxFit.cover),
                ),
              if (d.photo != null) const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final p = await MediaHelper.pickImage(context, maxWidth: 1280, imageQuality: 75);
                    if (p != null) setState(() => d.photo = p);
                  },
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(d.photo == null ? 'Chụp ảnh bằng chứng *' : 'Chụp lại ảnh'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepStatement(SettlementCalculation calc) {
    return SectionCard(
      title: 'Bảng kê tất toán',
      icon: Icons.receipt_long_outlined,
      child: Column(
        children: [
          InfoRow(label: 'Tổng thu (tiền cọc)', value: Fmt.vnd(calc.deposit), valueColor: ContractTokens.greenText),
          const Divider(height: 20),
          InfoRow(label: 'Nợ cũ chưa thanh toán', value: Fmt.vnd(calc.currentDebt)),
          InfoRow(label: 'Tiền phòng lẻ ngày', value: Fmt.vnd(calc.proRatedRent)),
          InfoRow(label: 'Điện nước & dịch vụ cuối', value: Fmt.vnd(calc.finalUtilities)),
          InfoRow(label: 'Phí hư hỏng', value: Fmt.vnd(calc.repairFees)),
          InfoRow(label: 'Tổng chi', value: Fmt.vnd(calc.totalCharges), valueColor: ContractTokens.redText),
          const Divider(height: 20),
          _balanceRow(calc),
        ],
      ),
    );
  }

  Widget _balanceRow(SettlementCalculation calc) {
    switch (calc.outcome) {
      case SettlementOutcome.refund:
        return InfoRow(label: 'Hoàn lại cho khách', value: Fmt.vnd(calc.netAmount), emphasize: true, valueColor: ContractTokens.greenText);
      case SettlementOutcome.collectMore:
        return InfoRow(label: 'Khách cần trả thêm', value: Fmt.vnd(-calc.netAmount), emphasize: true, valueColor: ContractTokens.redText);
      case SettlementOutcome.even:
        return const InfoRow(label: 'Cân bằng', value: '0đ', emphasize: true);
    }
  }

  Widget _stepConfirm(SettlementCalculation calc) {
    final refund = calc.outcome != SettlementOutcome.collectMore;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: refund ? 'Hoàn cọc cho khách' : 'Thu thêm từ khách',
          icon: refund ? Icons.savings_outlined : Icons.request_quote_outlined,
          child: Column(
            children: [
              _balanceRow(calc),
              InfoRow(label: 'Ngày trả phòng', value: Fmt.dateOf(_moveOut)),
              InfoRow(label: 'Số hạng mục hư hỏng', value: '${_items.where((i) => i.penaltyFee > 0).length}'),
            ],
          ),
        ),
        NoticeBox(
          tone: refund ? Tone.green : Tone.amber,
          icon: refund ? Icons.verified_outlined : Icons.info_outline_rounded,
          text: refund
              ? 'Hãy trả tiền mặt/chuyển khoản cho khách trước, sau đó xác nhận. Hợp đồng sẽ chuyển sang Đã thanh lý'
                  '${calc.repairFees > 0 ? ' và phòng chuyển sang Đang sửa chữa.' : ' và phòng trở về Trống.'}'
              : 'Hệ thống tạo Hóa đơn tất toán để khách thanh toán. Hợp đồng ở trạng thái Chờ tất toán đến khi khách trả đủ.',
        ),
      ],
    );
  }

  Widget _buildDone(SettlementConfirmation r) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Tất toán hoàn tất'), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          NoticeBox(
            tone: r.liquidated ? Tone.green : Tone.amber,
            icon: r.liquidated ? Icons.check_circle_outline_rounded : Icons.hourglass_bottom_rounded,
            text: r.liquidated
                ? 'Hợp đồng đã được thanh lý. Trạng thái phòng: ${r.roomStatus == 'REPAIRING' ? 'Đang sửa chữa' : 'Trống'}.'
                : 'Đã tạo hóa đơn tất toán #${r.settlementInvoiceId ?? '—'}. Khách cần trả thêm ${Fmt.vnd(r.settlementRemaining ?? -r.netAmount)}.',
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Biên bản tất toán',
            icon: Icons.receipt_long_outlined,
            child: Column(
              children: [
                InfoRow(label: 'Tiền cọc', value: Fmt.vnd(r.depositSnapshot)),
                InfoRow(label: 'Trừ nợ cũ', value: Fmt.vnd(r.oldDebtDeducted)),
                InfoRow(label: 'Trừ phí tất toán', value: Fmt.vnd(r.settlementDeducted)),
                if (r.refundAmount != null)
                  InfoRow(label: 'Đã hoàn cho khách', value: Fmt.vnd(r.refundAmount), emphasize: true, valueColor: ContractTokens.greenText),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: WizardBottomBar(onNext: () => Navigator.pop(context, true), nextLabel: 'Về chi tiết hợp đồng'),
    );
  }
}
