import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/resident_service.dart';
import 'tenants/tenant_detail_screen.dart';
import 'tenants/tenant_form_screen.dart';
import 'tenants/tenant_history_screen.dart';
import 'tenants/tenant_ui.dart';

/// Module VI – Quản lý Khách thuê (UC49–UC55), phía Quản lý.
/// UC50: danh sách khách có tìm theo tên/SĐT, lọc trạng thái và tải thêm theo trang.
class ManagerTenantsScreen extends StatefulWidget {
  const ManagerTenantsScreen({super.key});

  @override
  State<ManagerTenantsScreen> createState() => _ManagerTenantsScreenState();
}

class _TenantFilter {
  final String value;
  final String label;
  final IconData icon;
  const _TenantFilter(this.value, this.label, this.icon);
}

class _ManagerTenantsScreenState extends State<ManagerTenantsScreen> {
  static const _pageSize = 20;
  static const _filters = [
    _TenantFilter(ResidentService.filterAll, 'Tất cả', Icons.people_outline_rounded),
    _TenantFilter(ResidentService.filterLiving, 'Đang ở', Icons.home_outlined),
    _TenantFilter(ResidentService.filterPending, 'Chờ vào ở', Icons.hourglass_empty_rounded),
    _TenantFilter(ResidentService.filterDebt, 'Còn nợ', Icons.warning_amber_rounded),
    _TenantFilter(ResidentService.filterFormer, 'Đã trả phòng', Icons.logout_rounded),
    _TenantFilter(ResidentService.filterInactive, 'Đã vô hiệu hóa', Icons.person_off_outlined),
  ];

  final _search = TextEditingController();
  Timer? _debounce;
  String _status = ResidentService.filterAll;

  final List<ResidentSummary> _items = [];
  int _page = 0;
  int _total = 0;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final req = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ResidentService.search(
          query: _search.text, status: _status, page: 0, size: _pageSize);
      if (!mounted || req != _requestId) return;
      setState(() {
        _items
          ..clear()
          ..addAll(res.content);
        _page = 0;
        _total = res.totalElements;
        _hasMore = res.hasMore;
      });
    } catch (e) {
      if (!mounted || req != _requestId) return;
      setState(() => _error = tenantErrorText(e));
    } finally {
      if (mounted && req == _requestId) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    final req = _requestId;
    setState(() => _loadingMore = true);
    try {
      final res = await ResidentService.search(
          query: _search.text, status: _status, page: _page + 1, size: _pageSize);
      if (!mounted || req != _requestId) return;
      setState(() {
        _items.addAll(res.content);
        _page = res.page;
        _total = res.totalElements;
        _hasMore = res.hasMore;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Không tải thêm được: ${tenantErrorText(e)}'),
        backgroundColor: AppColors.danger,
      ));
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _reload);
    setState(() {});
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<ResidentResult>(
      MaterialPageRoute(builder: (_) => const TenantFormScreen()),
    );
    if (created == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Thêm mới khách thuê thành công'),
      backgroundColor: Color(0xFF047857),
      behavior: SnackBarBehavior.floating,
    ));
    _reload();
    // BR49.8: chuyển tới trang chi tiết khách vừa tạo.
    await _openDetail(created.userId, created.fullName);
  }

  Future<void> _openDetail(String id, String name) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TenantDetailScreen(residentId: id, initialName: name)),
    );
    if (changed == true && mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        tooltip: 'Thêm khách thuê mới',
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Thêm khách', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _search,
                        onChanged: _onSearchChanged,
                        textInputAction: TextInputAction.search,
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Tìm theo tên hoặc số điện thoại',
                          hintStyle: const TextStyle(fontSize: 14, color: AppColors.textSecondaryLight),
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _search.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Xóa tìm kiếm',
                                  onPressed: () {
                                    _search.clear();
                                    _reload();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                          filled: true,
                          fillColor: AppColors.backgroundLight,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.borderLight)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.borderLight)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      tooltip: 'Khách đã trả phòng (lịch sử)',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TenantHistoryScreen()),
                      ),
                      icon: const Icon(Icons.history_rounded),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(52, 52),
                        side: const BorderSide(color: AppColors.borderLight),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters
                        .map((f) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                avatar: Icon(f.icon,
                                    size: 18,
                                    color: _status == f.value ? Colors.white : AppColors.textSecondaryLight),
                                label: Text(f.label),
                                labelStyle: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _status == f.value ? Colors.white : const Color(0xFF334155),
                                ),
                                selected: _status == f.value,
                                showCheckmark: false,
                                selectedColor: AppColors.primary,
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                    color: _status == f.value ? AppColors.primary : AppColors.borderLight),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                onSelected: (_) {
                                  if (_status == f.value) return;
                                  setState(() => _status = f.value);
                                  _reload();
                                },
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.borderLight),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(
        child: TenantEmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Không tải được danh sách',
          message: _error,
          actionLabel: 'Thử lại',
          onAction: _reload,
        ),
      );
    }
    if (_items.isEmpty) {
      final searching = _search.text.trim().isNotEmpty || _status != ResidentService.filterAll;
      return RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          children: [
            TenantEmptyState(
              icon: Icons.people_outline_rounded,
              title: searching ? 'Không tìm thấy khách phù hợp' : 'Chưa có khách thuê nào',
              message: searching
                  ? 'Thử đổi từ khóa hoặc chọn bộ lọc "Tất cả".'
                  : 'Bấm "Thêm khách" để lưu hồ sơ khách thuê đầu tiên.',
              actionLabel: searching ? 'Xem tất cả' : 'Thêm khách',
              onAction: searching
                  ? () {
                      _search.clear();
                      setState(() => _status = ResidentService.filterAll);
                      _reload();
                    }
                  : _openCreate,
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _reload,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _items.length + 1,
        itemBuilder: (_, i) {
          if (i == _items.length) return _footer();
          return Padding(padding: const EdgeInsets.only(bottom: 12), child: _tenantCard(_items[i]));
        },
      ),
    );
  }

  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Column(
        children: [
          Text('Đang hiện ${_items.length}/$_total khách',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
          if (_hasMore) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _loadingMore ? null : _loadMore,
              icon: _loadingMore
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.expand_more_rounded),
              label: Text('Tải thêm ${(_total - _items.length).clamp(0, _pageSize)} khách'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(220, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tenantCard(ResidentSummary t) {
    final room = t.roomNumber != null
        ? 'Phòng ${t.roomNumber}${t.motelName != null ? ' · ${t.motelName}' : ''}'
        : 'Chưa ở phòng nào';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDetail(t.userId, t.fullName),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TenantAvatar(name: t.fullName, imageUrl: t.avatarUrl, radius: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                        const SizedBox(height: 2),
                        Text(room,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, color: Color(0xFF334155))),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined, size: 15, color: AppColors.textSecondaryLight),
                            const SizedBox(width: 4),
                            Text(t.phone, style: const TextStyle(fontSize: 14, color: AppColors.textSecondaryLight)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  TenantBadge(
                    label: TenantLabels.contract(t.contractStatus),
                    tone: TenantLabels.contractTone(t.contractStatus),
                    icon: Icons.description_outlined,
                  ),
                  TenantBadge(
                    label: t.hasDebt
                        ? 'Nợ ${TenantFormat.money(t.debtAmount)} (${t.unpaidInvoiceCount} HĐ)'
                        : 'Không nợ',
                    tone: t.hasDebt ? TenantTone.red : TenantTone.green,
                    icon: t.hasDebt ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                  ),
                  if (!t.accountActive)
                    TenantBadge(
                      label: TenantLabels.account(t.accountStatus),
                      tone: TenantTone.slate,
                      icon: Icons.lock_outline_rounded,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
