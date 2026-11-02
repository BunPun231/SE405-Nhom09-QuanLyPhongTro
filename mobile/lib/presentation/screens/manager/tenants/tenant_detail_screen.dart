import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/resident_service.dart';
import '../../tenant/face_register_screen.dart';
import 'tenant_form_screen.dart';
import 'tenant_ui.dart';

/// UC51: chi tiết hồ sơ khách thuê dạng tab (Hồ sơ, Hợp đồng, Thanh toán, Lịch sử).
/// [readOnly] = true khi mở từ lịch sử khách đã trả phòng (UC52, chỉ xem).
/// Trả về `true` qua Navigator.pop nếu hồ sơ đã thay đổi.
class TenantDetailScreen extends StatefulWidget {
  final String residentId;
  final String initialName;
  final bool readOnly;

  const TenantDetailScreen({
    super.key,
    required this.residentId,
    required this.initialName,
    this.readOnly = false,
  });

  @override
  State<TenantDetailScreen> createState() => _TenantDetailScreenState();
}

class _TenantDetailScreenState extends State<TenantDetailScreen> {
  ResidentOverview? _data;
  String? _error;
  bool _loading = true;
  bool _changed = false;
  bool _showIdCard = false;
  bool _deactivating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await ResidentService.overview(widget.residentId);
      if (!mounted) return;
      setState(() => _data = d);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = tenantErrorText(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit() async {
    final d = _data;
    if (d == null) return;
    final saved = await Navigator.of(context).push<ResidentResult>(
      MaterialPageRoute(builder: (_) => TenantFormScreen(editing: d.profile)),
    );
    if (saved == null || !mounted) return;
    _changed = true;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Cập nhật thông tin thành công'),
      backgroundColor: Color(0xFF047857),
      behavior: SnackBarBehavior.floating,
    ));
    _load();
  }

  Future<void> _deactivate() async {
    final d = _data;
    if (d == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.person_off_outlined, color: Color(0xFFB91C1C), size: 32),
        title: const Text('Vô hiệu hóa hồ sơ?'),
        content: Text(
          'Khách "${d.profile.fullName}" sẽ không đăng nhập được nữa và bị đăng xuất ngay.\n\n'
          'Lịch sử hợp đồng và hóa đơn vẫn được giữ lại. Nếu khách quay lại thuê, '
          'chỉ cần thêm lại bằng cùng số điện thoại.',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB91C1C),
              foregroundColor: Colors.white,
              minimumSize: const Size(64, 48),
            ),
            child: const Text('Vô hiệu hóa'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _deactivating = true);
    try {
      await ResidentService.deactivate(widget.residentId);
      if (!mounted) return;
      _changed = true;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Đã vô hiệu hóa hồ sơ "${d.profile.fullName}"'),
        backgroundColor: const Color(0xFF047857),
        behavior: SnackBarBehavior.floating,
      ));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tenantErrorText(e)),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _deactivating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    final canEdit = !widget.readOnly && d != null && d.profile.active;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          backgroundColor: AppColors.backgroundLight,
          appBar: AppBar(
            title: Text(d?.profile.fullName ?? widget.initialName,
                overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimaryLight,
            surfaceTintColor: Colors.white,
            elevation: 0,
            actions: [
              if (canEdit)
                IconButton(
                  tooltip: 'Sửa hồ sơ',
                  onPressed: _edit,
                  icon: const Icon(Icons.edit_outlined),
                ),
              IconButton(
                tooltip: 'Tải lại',
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
            bottom: const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondaryLight,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: 'Hồ sơ'),
                Tab(text: 'Hợp đồng'),
                Tab(text: 'Thanh toán'),
                Tab(text: 'Lịch sử'),
              ],
            ),
          ),
          body: _loading && d == null
              ? const Center(child: CircularProgressIndicator())
              : _error != null && d == null
                  ? Center(
                      child: TenantEmptyState(
                        icon: Icons.cloud_off_rounded,
                        title: 'Không tải được hồ sơ',
                        message: _error,
                        actionLabel: 'Thử lại',
                        onAction: _load,
                      ),
                    )
                  : TabBarView(
                      children: [
                        _profileTab(d!),
                        _contractsTab(d),
                        _paymentsTab(d),
                        _historyTab(d),
                      ],
                    ),
        ),
      ),
    );
  }

  // ── Tab Hồ sơ ───────────────────────────────────────────────────────────────

  Widget _profileTab(ResidentOverview d) {
    final p = d.profile;
    final current = d.currentContract;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (widget.readOnly)
            _banner(Icons.visibility_outlined,
                'Chế độ chỉ xem: dữ liệu khách đã trả phòng không được chỉnh sửa.', TenantTone.slate),
          if (!p.active)
            _banner(Icons.lock_person_outlined,
                'Quyền truy cập đã bị thu hồi: khách không đăng nhập được và không còn dùng các chức năng của phòng.',
                TenantTone.red)
          else if (d.residencyStatus == 'FORMER')
            _banner(Icons.schedule_rounded,
                'Hợp đồng đã kết thúc. Hệ thống sẽ tự động thu hồi quyền truy cập của khách.',
                TenantTone.amber),
          TenantCard(
            child: Row(
              children: [
                TenantAvatar(name: p.fullName, imageUrl: p.avatarUrl, radius: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.fullName,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      const SizedBox(height: 4),
                      Text(
                        current != null
                            ? 'Phòng ${current.roomNumber ?? '—'}${current.motelName != null ? ' · ${current.motelName}' : ''}'
                            : 'Chưa ở phòng nào',
                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondaryLight),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          TenantBadge(
                              label: TenantLabels.residency(d.residencyStatus),
                              tone: TenantLabels.residencyTone(d.residencyStatus)),
                          TenantBadge(
                              label: TenantLabels.account(p.status),
                              tone: p.active ? TenantTone.green : TenantTone.red),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _debtCard(d),
          const SizedBox(height: 12),
          TenantCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                TenantInfoRow(icon: Icons.phone_outlined, label: 'Số điện thoại', value: p.phone),
                const Divider(height: 1),
                TenantInfoRow(icon: Icons.email_outlined, label: 'Email', value: p.email ?? '—'),
                const Divider(height: 1),
                TenantInfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Số CCCD',
                  value: _showIdCard ? (p.idCardNumber ?? '—') : _maskId(p.idCardNumber),
                  trailing: p.idCardNumber == null
                      ? null
                      : IconButton(
                          tooltip: _showIdCard ? 'Ẩn số CCCD' : 'Hiện số CCCD',
                          onPressed: () => setState(() => _showIdCard = !_showIdCard),
                          icon: Icon(_showIdCard ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 20),
                        ),
                ),
                const Divider(height: 1),
                TenantInfoRow(
                    icon: Icons.cake_outlined, label: 'Ngày sinh', value: TenantFormat.date(p.dateOfBirth)),
                const Divider(height: 1),
                TenantInfoRow(icon: Icons.wc_rounded, label: 'Giới tính', value: TenantLabels.gender(p.gender)),
                const Divider(height: 1),
                TenantInfoRow(
                    icon: Icons.sticky_note_2_outlined, label: 'Ghi chú', value: p.notes ?? '—'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TenantCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: TenantImageBox(label: 'CCCD mặt trước', url: p.idCardFrontUrl)),
                const SizedBox(width: 12),
                Expanded(child: TenantImageBox(label: 'CCCD mặt sau', url: p.idCardBackUrl)),
              ],
            ),
          ),
          if (!widget.readOnly && p.active) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _edit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Sửa thông tin liên hệ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => FaceRegisterScreen(userId: p.userId, userName: p.fullName),
              )),
              icon: const Icon(Icons.face_retouching_natural_rounded),
              label: const Text('Đăng ký khuôn mặt mở cổng'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 20),
            _deactivateSection(d),
          ],
        ],
      ),
    );
  }

  Widget _debtCard(ResidentOverview d) {
    final hasDebt = d.totalDebt > 0;
    final tone = hasDebt ? TenantTone.red : TenantTone.green;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(hasDebt ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
              color: tone.fg, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hasDebt ? 'Còn nợ ${d.unpaidInvoiceCount} hóa đơn' : 'Không còn nợ',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: tone.fg)),
                if (hasDebt)
                  Text('Xem chi tiết ở tab Thanh toán',
                      style: TextStyle(fontSize: 13, color: tone.fg)),
              ],
            ),
          ),
          if (hasDebt)
            Text(TenantFormat.money(d.totalDebt),
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: tone.fg)),
        ],
      ),
    );
  }

  Widget _deactivateSection(ResidentOverview d) {
    return TenantCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Vô hiệu hóa hồ sơ',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 6),
          Text(
            d.canDeactivate
                ? 'Khách đã thanh lý hợp đồng và không còn nợ. Có thể vô hiệu hóa để thu hồi quyền đăng nhập.'
                : (d.deactivateBlockReason ??
                    'Chỉ vô hiệu hóa được khi hợp đồng đã thanh lý và không còn nợ.'),
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: d.canDeactivate ? AppColors.textSecondaryLight : const Color(0xFFB45309),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: d.canDeactivate && !_deactivating ? _deactivate : null,
            icon: _deactivating
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.person_off_outlined),
            label: const Text('Vô hiệu hóa hồ sơ'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB91C1C),
              side: BorderSide(color: d.canDeactivate ? const Color(0xFFFCA5A5) : AppColors.borderLight),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab Hợp đồng ────────────────────────────────────────────────────────────

  Widget _contractsTab(ResidentOverview d) {
    if (d.contracts.isEmpty) {
      return const Center(
        child: TenantEmptyState(
          icon: Icons.description_outlined,
          title: 'Chưa có hợp đồng',
          message: 'Khách chưa đứng tên hoặc ở chung trong hợp đồng nào. Lập hợp đồng ở mục Hợp đồng.',
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: d.contracts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final c = d.contracts[i];
        return TenantCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Phòng ${c.roomNumber ?? '—'}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  ),
                  TenantBadge(label: TenantLabels.contract(c.status), tone: TenantLabels.contractTone(c.status)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'HĐ #${c.id}${c.motelName != null ? ' · ${c.motelName}' : ''} · ${c.primary ? 'Người đứng tên' : 'Ở cùng'}',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
              ),
              const Divider(height: 20),
              TenantInfoRow(
                  icon: Icons.login_rounded, label: 'Ngày vào ở', value: TenantFormat.date(c.startDate)),
              TenantInfoRow(
                  icon: Icons.event_outlined, label: 'Hết hạn HĐ', value: TenantFormat.date(c.endDate)),
              if (c.moveOutDate != null)
                TenantInfoRow(
                    icon: Icons.logout_rounded, label: 'Ngày trả phòng', value: TenantFormat.date(c.moveOutDate)),
              TenantInfoRow(
                  icon: Icons.payments_outlined, label: 'Giá thuê', value: '${TenantFormat.money(c.rentPrice)}/tháng'),
              TenantInfoRow(
                icon: Icons.savings_outlined,
                label: 'Tiền cọc',
                value: '${TenantFormat.money(c.depositAmount)} · ${TenantLabels.deposit(c.depositStatus)}',
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Tab Thanh toán ──────────────────────────────────────────────────────────

  Widget _paymentsTab(ResidentOverview d) {
    final paidTotal = d.invoices
        .where((i) => i.status != 'VOID')
        .fold<double>(0, (s, i) => s + i.paidAmount);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(
          children: [
            Expanded(child: _kpi('Còn nợ', TenantFormat.money(d.totalDebt), d.totalDebt > 0 ? TenantTone.red : TenantTone.green)),
            const SizedBox(width: 12),
            Expanded(child: _kpi('Đã thanh toán', TenantFormat.money(paidTotal), TenantTone.green)),
          ],
        ),
        const SizedBox(height: 16),
        if (d.invoices.isEmpty)
          const TenantEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Chưa có hóa đơn',
            message: 'Hóa đơn của các hợp đồng khách tham gia sẽ hiện ở đây.',
          )
        else
          ...d.invoices.map((inv) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TenantCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              inv.invoiceType == 'SETTLEMENT'
                                  ? 'Hóa đơn tất toán'
                                  : TenantFormat.month(inv.billingMonth),
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                          ),
                          TenantBadge(label: TenantLabels.invoice(inv.status), tone: TenantLabels.invoiceTone(inv.status)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '#${inv.id} · Phòng ${inv.roomNumber ?? '—'} · Hạn ${TenantFormat.date(inv.dueDate)}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text('Tổng: ${TenantFormat.money(inv.totalAmount)}',
                                style: const TextStyle(fontSize: 14, color: Color(0xFF334155))),
                          ),
                          if (inv.unpaid)
                            Text('Còn ${TenantFormat.money(inv.remainingAmount)}',
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C)))
                          else
                            Text('Đã trả ${TenantFormat.money(inv.paidAmount)}',
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF047857))),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
      ],
    );
  }

  Widget _kpi(String label, String value, TenantTone tone) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: tone.fg, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: tone.fg)),
        ],
      ),
    );
  }

  // ── Tab Lịch sử ─────────────────────────────────────────────────────────────

  Widget _historyTab(ResidentOverview d) {
    final stays = d.contracts.where((c) => c.startDate != null).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _sectionTitle('Quá trình lưu trú'),
        if (stays.isEmpty)
          _muted('Chưa có lần ở trọ nào.')
        else
          ...stays.map((c) => _timelineTile(
                icon: Icons.home_outlined,
                title: 'Phòng ${c.roomNumber ?? '—'}${c.motelName != null ? ' · ${c.motelName}' : ''}',
                subtitle:
                    '${TenantFormat.date(c.startDate)} → ${c.moveOutDate != null ? TenantFormat.date(c.moveOutDate) : 'nay'}',
                badge: TenantBadge(label: TenantLabels.contract(c.status), tone: TenantLabels.contractTone(c.status)),
              )),
        const SizedBox(height: 16),
        _sectionTitle('Yêu cầu sửa chữa (${d.maintenanceRequests.length})'),
        if (d.maintenanceRequests.isEmpty)
          _muted('Khách chưa gửi yêu cầu sửa chữa nào.')
        else
          ...d.maintenanceRequests.map((m) => _timelineTile(
                icon: Icons.build_outlined,
                title: m.description.isEmpty ? m.category : m.description,
                subtitle: '${TenantFormat.date(m.createdAt)} · Phòng ${m.roomNumber ?? '—'} · ${m.category}',
                badge: TenantBadge(label: TenantLabels.maintenance(m.status), tone: TenantLabels.maintenanceTone(m.status)),
              )),
        const SizedBox(height: 16),
        _sectionTitle('Nhật ký thay đổi hồ sơ'),
        if (d.activities.isEmpty)
          _muted('Chưa có thay đổi nào được ghi lại.')
        else
          ...d.activities.map((a) => _timelineTile(
                icon: Icons.history_rounded,
                title: a.action == 'UPDATE_RESIDENT'
                    ? 'Sửa ${TenantLabels.field(a.field).toLowerCase()}'
                    : TenantLabels.activity(a.action),
                subtitle: [
                  TenantFormat.date(a.timestamp),
                  if (a.action == 'UPDATE_RESIDENT') '${a.oldValue ?? '(trống)'} → ${a.newValue ?? '(trống)'}',
                ].join(' · '),
              )),
      ],
    );
  }

  Widget _timelineTile({required IconData icon, required String title, required String subtitle, Widget? badge}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TenantCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
                  if (badge != null) ...[const SizedBox(height: 6), badge],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(t,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
      );

  Widget _muted(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
      );

  Widget _banner(IconData icon, String text, TenantTone tone) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(12)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: tone.fg, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: tone.fg, height: 1.4))),
          ],
        ),
      );

  static String _maskId(String? id) {
    if (id == null || id.isEmpty) return '—';
    if (id.length <= 4) return id;
    return '${'•' * (id.length - 4)}${id.substring(id.length - 4)}';
  }
}
