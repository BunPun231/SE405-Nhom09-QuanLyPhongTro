import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/contract_service.dart';
import '../../../../core/services/motel_service.dart';
import '../../../../core/services/resident_service.dart';
import '../../../../core/utils/media_helper.dart';
import 'contract_detail_screen.dart';
import 'contract_ui.dart';

/// UC63 – Lập hợp đồng mới theo từng bước:
/// 1. Khách thuê (tìm/chọn hoặc tạo nhanh) → 2. Phòng (Trống/Đã cọc) → 3. Điều khoản →
/// 4. Tài liệu & xem trước → 5. Kích hoạt (thu cọc ngay hoặc chờ thu cọc).
/// Trả về id hợp đồng khi tạo thành công.
class ContractCreateWizard extends StatefulWidget {
  final int? initialMotelId;
  const ContractCreateWizard({super.key, this.initialMotelId});

  @override
  State<ContractCreateWizard> createState() => _ContractCreateWizardState();
}

class _ContractCreateWizardState extends State<ContractCreateWizard> {
  static const _titles = ['Khách thuê', 'Chọn phòng', 'Điều khoản', 'Tài liệu & xem trước', 'Kích hoạt'];

  int _step = 0;
  bool _loading = false;
  String? _error;

  // Bước 1
  List<ResidentResult> _residents = [];
  ResidentResult? _resident;
  bool _newResident = false;
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _idCard = TextEditingController();
  final _email = TextEditingController();

  // Bước 2
  List<MotelResult> _motels = [];
  MotelResult? _motel;
  List<RoomResult> _rooms = [];
  RoomResult? _room;
  bool _loadingRooms = false;

  // Bước 3
  DateTime _start = DateTime.now();
  DateTime? _end;
  final _rent = TextEditingController();
  final _deposit = TextEditingController();
  int _billingDay = 31;
  int _paymentMonths = 1;

  // Bước 4
  final List<PickedImage> _docs = [];

  // Bước 5
  bool _collectNow = true;
  DateTime _collectDate = DateTime.now();
  String _method = 'CASH';

  // Kết quả
  ContractResult? _created;
  final List<String> _warnings = [];

  @override
  void initState() {
    super.initState();
    _end = ContractRules.addMonths(_start, 12);
    _bootstrap();
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _idCard, _email, _rent, _deposit]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() => _loading = true);
    try {
      final motels = await MotelService.list(size: 100);
      _motels = motels.content;
      if (_motels.isNotEmpty) {
        _motel = _motels.firstWhere((m) => m.id == widget.initialMotelId, orElse: () => _motels.first);
        _billingDay = _motel!.billingCycleDay ?? 31;
      }
      final all = <ResidentResult>[];
      var page = 0;
      while (page < 10) {
        final res = await ResidentService.list(page: page, size: 100);
        all.addAll(res.content);
        page++;
        if (page >= res.totalPages) break;
      }
      _residents = all.where((r) => r.active).toList();
      await _loadRooms();
    } catch (e) {
      _error = Fmt.errorText(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadRooms() async {
    final motel = _motel;
    if (motel == null) return;
    setState(() => _loadingRooms = true);
    try {
      final res = await RoomService.list(motel.id, size: 500);
      _rooms = res.content.where((r) => r.status == 'EMPTY' || r.status == 'DEPOSITED' || r.status == 'AVAILABLE').toList()
        ..sort((a, b) => a.roomNumber.compareTo(b.roomNumber));
    } catch (e) {
      _rooms = [];
      _error = Fmt.errorText(e);
    } finally {
      if (mounted) setState(() => _loadingRooms = false);
    }
  }

  void _selectRoom(RoomResult room) {
    setState(() {
      _room = room;
      _rent.text = room.basePrice.toStringAsFixed(0);
      final percent = _motel?.depositPercent;
      final deposit = percent != null && percent > 0 ? room.basePrice * percent / 100 : room.basePrice;
      _deposit.text = deposit.toStringAsFixed(0);
    });
  }

  // ─── Kiểm tra từng bước ───
  String? _validate() {
    switch (_step) {
      case 0:
        if (!_newResident) return _resident == null ? 'Vui lòng tìm và chọn khách thuê' : null;
        if (_name.text.trim().isEmpty) return 'Vui lòng nhập họ tên khách thuê';
        if (!RegExp(r'^0\d{9}$').hasMatch(_phone.text.trim())) return 'Số điện thoại phải gồm 10 chữ số, bắt đầu bằng 0';
        if (!RegExp(r'^(\d{9}|\d{12})$').hasMatch(_idCard.text.trim())) return 'Số CCCD/CMND phải gồm 9 hoặc 12 chữ số';
        final dup = _residents.where((r) => r.phone == _phone.text.trim());
        if (dup.isNotEmpty) return 'Số điện thoại đã thuộc khách "${dup.first.fullName}". Hãy chọn khách có sẵn.';
        return null;
      case 1:
        return _room == null ? 'Vui lòng chọn một phòng Trống hoặc Đã cọc' : null;
      case 2:
        return ContractRules.validateTerms(
          start: _start,
          end: _end,
          rent: Fmt.parseMoney(_rent.text),
          deposit: Fmt.parseMoney(_deposit.text),
        ).error;
    }
    return null;
  }

  Future<void> _next() async {
    final err = _validate();
    setState(() => _error = err);
    if (err != null) return;
    if (_step == _titles.length - 1) {
      await _submit();
    } else {
      setState(() => _step++);
    }
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
      _warnings.clear();
    });
    try {
      final body = ContractService.buildCreateBody(
        roomId: _room!.id,
        residentUserId: _newResident ? null : _resident!.userId,
        newResidentFullName: _name.text.trim(),
        newResidentPhone: _phone.text.trim(),
        newResidentIdCard: _idCard.text.trim(),
        newResidentEmail: _email.text.trim(),
        startDate: _start,
        endDate: _end!,
        rentPrice: Fmt.parseMoney(_rent.text)!,
        depositAmount: Fmt.parseMoney(_deposit.text)!,
        billingCycleDay: _billingDay,
        paymentCycleMonths: _paymentMonths,
      );
      var created = await ContractService.create(body);
      if (_collectNow) {
        try {
          created = await ContractService.collectDeposit(
            created.id,
            amount: created.depositAmount,
            collectedDate: _collectDate,
            paymentMethod: _method,
          );
        } catch (e) {
          _warnings.add('Chưa ghi nhận được tiền cọc (${Fmt.errorText(e)}). Hợp đồng đang ở trạng thái Chờ thu cọc.');
        }
      }
      for (final doc in _docs) {
        try {
          await ContractService.addAttachment(created.id, fileName: doc.name, base64Data: doc.base64);
        } catch (e) {
          _warnings.add('Không tải được tệp "${doc.name}": ${Fmt.errorText(e)}');
        }
      }
      if (mounted) setState(() => _created = created);
    } catch (e) {
      if (mounted) setState(() => _error = Fmt.errorText(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_created != null) return _buildSuccess(_created!);
    return PopScope(
      canPop: _step == 0 && !_loading,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_loading && _step > 0) setState(() => _step--);
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(title: const Text('Lập hợp đồng mới')),
        body: Column(
          children: [
            StepProgress(current: _step, titles: _titles),
            Expanded(
              child: _loading && _motels.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (_step == 0) _stepTenant(),
                        if (_step == 1) _stepRoom(),
                        if (_step == 2) _stepTerms(),
                        if (_step == 3) _stepDocs(),
                        if (_step == 4) _stepActivate(),
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
          confirm: _step == 4 && _collectNow,
          nextLabel: _step == 4 ? (_collectNow ? 'Thu cọc & kích hoạt' : 'Lưu hợp đồng') : 'Tiếp tục',
        ),
      ),
    );
  }

  // ─── Bước 1: Khách thuê ───
  Widget _stepTenant() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Khách có sẵn'), icon: Icon(Icons.person_search_outlined)),
            ButtonSegment(value: true, label: Text('Khách mới'), icon: Icon(Icons.person_add_alt_1_outlined)),
          ],
          selected: {_newResident},
          onSelectionChanged: (s) => setState(() {
            _newResident = s.first;
            _error = null;
          }),
        ),
        const SizedBox(height: 16),
        if (!_newResident) ...[
          Autocomplete<ResidentResult>(
            displayStringForOption: (r) => '${r.fullName} · ${r.phone}',
            optionsBuilder: (value) {
              final q = value.text.trim().toLowerCase();
              if (q.isEmpty) return _residents.take(20);
              return _residents
                  .where((r) =>
                      r.fullName.toLowerCase().contains(q) ||
                      r.phone.contains(q) ||
                      (r.idCardNumber ?? '').contains(q))
                  .take(20);
            },
            onSelected: (r) => setState(() {
              _resident = r;
              _error = null;
            }),
            fieldViewBuilder: (ctx, ctrl, focus, onSubmit) => TextField(
              controller: ctrl,
              focusNode: focus,
              decoration: const InputDecoration(
                labelText: 'Tìm khách theo tên, SĐT hoặc CCCD',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_resident != null)
            SectionCard(
              title: _resident!.fullName,
              icon: Icons.person_outline_rounded,
              trailing: const StatusBadge(label: 'Đã chọn', tone: Tone.green),
              child: Column(
                children: [
                  InfoRow(label: 'Số điện thoại', value: _resident!.phone),
                  InfoRow(label: 'CCCD', value: _resident!.idCardNumber ?? '—'),
                  if (_resident!.email != null) InfoRow(label: 'Email', value: _resident!.email!),
                ],
              ),
            )
          else if (_residents.isEmpty)
            const NoticeBox(text: 'Chưa có khách thuê nào. Chọn "Khách mới" để nhập thông tin.'),
        ] else ...[
          TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Họ và tên *')),
          const SizedBox(height: 12),
          TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Số điện thoại *')),
          const SizedBox(height: 12),
          TextField(controller: _idCard, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Số CCCD/CMND *')),
          const SizedBox(height: 12),
          TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email (tùy chọn)')),
          const SizedBox(height: 12),
          const NoticeBox(text: 'Hệ thống tự tạo tài khoản cho khách với tên đăng nhập là số điện thoại khi lưu hợp đồng.'),
        ],
      ],
    );
  }

  // ─── Bước 2: Phòng ───
  Widget _stepRoom() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<int>(
          initialValue: _motel?.id,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Khu trọ'),
          items: _motels.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))).toList(),
          onChanged: (id) async {
            final m = _motels.firstWhere((x) => x.id == id);
            setState(() {
              _motel = m;
              _room = null;
              _billingDay = m.billingCycleDay ?? 31;
            });
            await _loadRooms();
          },
        ),
        const SizedBox(height: 12),
        if (_loadingRooms)
          const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
        else if (_rooms.isEmpty)
          const NoticeBox(text: 'Khu trọ này không còn phòng Trống hoặc Đã cọc.', tone: Tone.amber)
        else
          for (final r in _rooms)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _selectRoom(r),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 64),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _room?.id == r.id ? AppColors.primary : AppColors.borderLight,
                        width: _room?.id == r.id ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _room?.id == r.id ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                          color: _room?.id == r.id ? AppColors.primary : AppColors.textSecondaryLight,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Phòng ${r.roomNumber}',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ContractTokens.heading)),
                              Text('Tầng ${r.floor}${r.area != null ? ' · ${r.area!.toStringAsFixed(0)} m²' : ''} · ${Fmt.vnd(r.basePrice)}/tháng',
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
                            ],
                          ),
                        ),
                        StatusBadge(
                          label: r.status == 'DEPOSITED' ? 'Đã cọc' : 'Trống',
                          tone: r.status == 'DEPOSITED' ? Tone.violet : Tone.green,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }

  // ─── Bước 3: Điều khoản ───
  Widget _stepTerms() {
    final rent = Fmt.parseMoney(_rent.text);
    final check = ContractRules.validateTerms(start: _start, end: _end, rent: rent, deposit: Fmt.parseMoney(_deposit.text));
    final months = _end != null ? ContractRules.durationMonths(_start, _end!) : 0;
    final pro = rent != null && rent > 0 ? ContractRules.proRatedFirstRent(start: _start, rent: rent, billingCycleDay: _billingDay) : null;
    final endBeforeStart = _end != null && !_end!.isAfter(_start);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: DateField(
                label: 'Ngày bắt đầu',
                value: _start,
                onTap: () async {
                  final d = await pickDate(context, initial: _start);
                  if (d != null) setState(() => _start = d);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DateField(
                label: 'Ngày kết thúc',
                value: _end,
                errorText: endBeforeStart ? 'Phải sau ngày bắt đầu' : null,
                onTap: () async {
                  final d = await pickDate(context, initial: _end ?? _start, first: _start);
                  if (d != null) setState(() => _end = d);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final m in const [6, 12, 24])
              ChoiceChip(
                label: Text('$m tháng'),
                selected: months == m && _end != null && ContractRules.addMonths(_start, m) == _end,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                onSelected: (_) => setState(() => _end = ContractRules.addMonths(_start, m)),
              ),
          ],
        ),
        Text('Thời hạn: $months tháng', style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
        const SizedBox(height: 12),
        TextField(
          controller: _rent,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(labelText: 'Giá thuê (đ/tháng) *'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _deposit,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(labelText: 'Tiền cọc (đ) *'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                key: ValueKey('billing-${_motel?.id}'),
                initialValue: _billingDay,
                decoration: const InputDecoration(labelText: 'Ngày chốt sổ'),
                items: [
                  for (final d in const [5, 10, 15, 20, 25, 31])
                    DropdownMenuItem(value: d, child: Text(d == 31 ? 'Cuối tháng' : 'Ngày $d')),
                  if (![5, 10, 15, 20, 25, 31].contains(_billingDay))
                    DropdownMenuItem(value: _billingDay, child: Text('Ngày $_billingDay')),
                ],
                onChanged: (v) => setState(() => _billingDay = v ?? 31),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: _paymentMonths,
                decoration: const InputDecoration(labelText: 'Kỳ đóng tiền'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1 tháng')),
                  DropdownMenuItem(value: 3, child: Text('3 tháng')),
                  DropdownMenuItem(value: 6, child: Text('6 tháng')),
                ],
                onChanged: (v) => setState(() => _paymentMonths = v ?? 1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (pro != null)
          NoticeBox(
            text: 'Ngày bắt đầu lệch ngày chốt sổ: tiền phòng kỳ đầu (lẻ ${pro.days} ngày, đến ${Fmt.dateOf(pro.until)}) '
                'gợi ý ${Fmt.vnd(pro.amount)} = giá thuê / 30 × ${pro.days}.',
            icon: Icons.calculate_outlined,
          ),
        if (!check.ok && _end != null) ...[
          const SizedBox(height: 8),
          NoticeBox(text: check.error!, tone: Tone.amber, icon: Icons.warning_amber_rounded),
        ],
      ],
    );
  }

  // ─── Bước 4: Tài liệu & xem trước ───
  Widget _stepDocs() {
    final tenantName = _newResident ? _name.text.trim() : _resident?.fullName ?? '';
    final tenantPhone = _newResident ? _phone.text.trim() : _resident?.phone ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: 'Bản scan / mẫu hợp đồng (${_docs.length})',
          icon: Icons.attach_file_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_docs.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < _docs.length; i++)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(Uint8List.fromList(_docs[i].bytes), width: 88, height: 88, fit: BoxFit.cover),
                          ),
                          Positioned(
                            right: -4,
                            top: -4,
                            child: IconButton(
                              tooltip: 'Bỏ tệp',
                              style: IconButton.styleFrom(backgroundColor: Colors.white),
                              icon: const Icon(Icons.close_rounded, size: 16, color: ContractTokens.redText),
                              onPressed: () => setState(() => _docs.removeAt(i)),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final p = await MediaHelper.pickImage(context);
                  if (p != null) setState(() => _docs.add(p));
                },
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Thêm ảnh tài liệu'),
              ),
              const SizedBox(height: 6),
              const Text('Tùy chọn. File PDF hợp đồng được hệ thống tự sinh sau khi lưu.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
            ],
          ),
        ),
        SectionCard(
          title: 'Xem trước hợp đồng',
          icon: Icons.preview_outlined,
          child: Column(
            children: [
              InfoRow(label: 'Bên thuê', value: tenantName),
              InfoRow(label: 'Số điện thoại', value: tenantPhone),
              InfoRow(label: 'Khu trọ', value: _motel?.name ?? '—'),
              InfoRow(label: 'Phòng', value: _room == null ? '—' : 'Phòng ${_room!.roomNumber}'),
              InfoRow(label: 'Thời hạn', value: '${Fmt.dateOf(_start)} → ${_end == null ? '—' : Fmt.dateOf(_end!)}'),
              InfoRow(label: 'Giá thuê', value: '${Fmt.vnd(Fmt.parseMoney(_rent.text))}/tháng', emphasize: true),
              InfoRow(label: 'Tiền cọc', value: Fmt.vnd(Fmt.parseMoney(_deposit.text))),
              InfoRow(label: 'Ngày chốt sổ', value: _billingDay >= 31 ? 'Cuối tháng' : 'Ngày $_billingDay'),
              InfoRow(label: 'Kỳ đóng tiền', value: '$_paymentMonths tháng/lần'),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Bước 5: Kích hoạt ───
  Widget _stepActivate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RadioGroup<bool>(
          groupValue: _collectNow,
          onChanged: (v) => setState(() => _collectNow = v ?? true),
          child: const Column(
            children: [
              RadioListTile<bool>(
                value: true,
                title: Text('Đã thu cọc – kích hoạt ngay', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('Hợp đồng Đang hiệu lực, phòng chuyển sang Đang thuê.'),
              ),
              RadioListTile<bool>(
                value: false,
                title: Text('Chờ thu cọc', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('Lưu hợp đồng ở trạng thái Chờ thu cọc, phòng giữ ở Đã cọc.'),
              ),
            ],
          ),
        ),
        if (_collectNow) ...[
          const SizedBox(height: 8),
          SectionCard(
            title: 'Thông tin thu cọc',
            icon: Icons.payments_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InfoRow(label: 'Số tiền', value: Fmt.vnd(Fmt.parseMoney(_deposit.text)), emphasize: true),
                const SizedBox(height: 8),
                DateField(
                  label: 'Ngày thu thực tế',
                  value: _collectDate,
                  onTap: () async {
                    final d = await pickDate(context, initial: _collectDate, last: DateTime.now());
                    if (d != null) setState(() => _collectDate = d);
                  },
                ),
                const SizedBox(height: 10),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'CASH', label: Text('Tiền mặt')),
                    ButtonSegment(value: 'BANK_TRANSFER', label: Text('Chuyển khoản')),
                  ],
                  selected: {_method},
                  onSelectionChanged: (s) => setState(() => _method = s.first),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSuccess(ContractResult c) {
    final active = c.status == 'ACTIVE';
    final phone = _newResident ? _phone.text.trim() : _resident?.phone ?? '';
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Đã lập hợp đồng'), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          NoticeBox(
            tone: active ? Tone.green : Tone.violet,
            icon: Icons.check_circle_outline_rounded,
            text: active
                ? 'Hợp đồng ${c.displayCode} đã có hiệu lực. Phòng chuyển sang Đang thuê.'
                : 'Hợp đồng ${c.displayCode} đã lưu ở trạng thái Chờ thu cọc.',
          ),
          for (final w in _warnings) ...[
            const SizedBox(height: 8),
            NoticeBox(text: w, tone: Tone.amber, icon: Icons.warning_amber_rounded),
          ],
          const SizedBox(height: 12),
          SectionCard(
            title: 'Bước tiếp theo',
            icon: Icons.checklist_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• Khách đăng nhập app bằng số điện thoại $phone và đổi mật khẩu ở lần đầu.',
                    style: const TextStyle(fontSize: 13, height: 1.4)),
                const Text('• Xuất PDF để in và ký hợp đồng với khách.', style: TextStyle(fontSize: 13, height: 1.4)),
                if (!active)
                  const Text('• Ghi nhận thu cọc tại màn hình chi tiết để kích hoạt hợp đồng.',
                      style: TextStyle(fontSize: 13, height: 1.4)),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              try {
                await MediaHelper.downloadAndOpen(ContractService.pdfEndpoint(c.id), fileName: 'hop-dong-${c.id}.pdf');
              } catch (e) {
                if (mounted) showSnack(context, Fmt.errorText(e), error: true);
              }
            },
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Xuất PDF hợp đồng'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => ContractDetailScreen(contractId: c.id, isManager: true)),
            ),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Xem chi tiết hợp đồng'),
          ),
        ],
      ),
      bottomNavigationBar: WizardBottomBar(onNext: () => Navigator.pop(context, c.id), nextLabel: 'Xong'),
    );
  }
}
