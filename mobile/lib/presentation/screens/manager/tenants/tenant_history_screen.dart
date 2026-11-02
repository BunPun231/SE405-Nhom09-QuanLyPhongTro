import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/resident_service.dart';
import 'tenant_detail_screen.dart';
import 'tenant_ui.dart';

/// UC52: khách đã trả phòng — chỉ xem, lọc theo ngày trả phòng, tải thêm từng trang.
class TenantHistoryScreen extends StatefulWidget {
  const TenantHistoryScreen({super.key});

  @override
  State<TenantHistoryScreen> createState() => _TenantHistoryScreenState();
}

class _TenantHistoryScreenState extends State<TenantHistoryScreen> {
  static const _pageSize = 20;

  final _search = TextEditingController();
  Timer? _debounce;

  DateTimeRange? _range;
  final List<ResidentHistoryItem> _items = [];
  int _page = 0;
  int _total = 0;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ResidentService.history(
        query: _search.text,
        from: _range?.start,
        to: _range?.end,
        page: 0,
        size: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(res.content);
        _page = 0;
        _total = res.totalElements;
        _hasMore = res.hasMore;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = tenantErrorText(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final res = await ResidentService.history(
        query: _search.text,
        from: _range?.start,
        to: _range?.end,
        page: _page + 1,
        size: _pageSize,
      );
      if (!mounted) return;
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

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _range,
      helpText: 'Chọn khoảng ngày trả phòng',
      saveText: 'Áp dụng',
      cancelText: 'Hủy',
    );
    if (picked == null) return;
    setState(() => _range = picked);
    _reload();
  }

  void _setQuickRange(int months) {
    final now = DateTime.now();
    setState(() => _range = DateTimeRange(
        start: DateTime(now.year, now.month - months + 1, 1), end: DateTime(now.year, now.month, now.day)));
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Khách đã trả phòng'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimaryLight,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _search,
                  onChanged: (_) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 400), _reload);
                  },
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên hoặc số điện thoại',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: AppColors.backgroundLight,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.borderLight)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.borderLight)),
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Lọc theo ngày trả phòng',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight)),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Tất cả'),
                        selected: _range == null,
                        onSelected: (_) {
                          setState(() => _range = null);
                          _reload();
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('3 tháng gần đây'),
                        selected: false,
                        onSelected: (_) => _setQuickRange(3),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('12 tháng gần đây'),
                        selected: false,
                        onSelected: (_) => _setQuickRange(12),
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Icon(Icons.date_range_rounded, size: 18),
                        label: Text(_range == null
                            ? 'Chọn ngày...'
                            : '${TenantFormat.date(_range!.start)} – ${TenantFormat.date(_range!.end)}'),
                        onPressed: _pickRange,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                Icon(Icons.visibility_outlined, size: 16, color: AppColors.textSecondaryLight),
                SizedBox(width: 6),
                Expanded(
                  child: Text('Dữ liệu lịch sử chỉ để xem, không chỉnh sửa được.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
                ),
              ],
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: TenantEmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Không tải được dữ liệu',
          message: _error,
          actionLabel: 'Thử lại',
          onAction: _reload,
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: TenantEmptyState(
          icon: Icons.history_rounded,
          title: 'Không có khách đã trả phòng',
          message: 'Thử đổi khoảng ngày hoặc từ khóa tìm kiếm.',
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
        itemCount: _items.length + 1,
        itemBuilder: (_, i) {
          if (i == _items.length) return _footer();
          return Padding(padding: const EdgeInsets.only(bottom: 12), child: _card(_items[i]));
        },
      ),
    );
  }

  Widget _footer() {
    return Column(
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
            label: const Text('Tải thêm'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(200, 48)),
          ),
        ],
      ],
    );
  }

  Widget _card(ResidentHistoryItem h) {
    final settled = h.settlementTotal != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => TenantDetailScreen(residentId: h.userId, initialName: h.fullName, readOnly: true),
        )),
        child: TenantCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TenantAvatar(name: h.fullName, radius: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(h.fullName,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        const SizedBox(height: 2),
                        Text('${h.phone} · Phòng ${h.roomNumber ?? '—'}',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
                      ],
                    ),
                  ),
                  TenantBadge(
                      label: TenantLabels.contract(h.contractStatus),
                      tone: TenantLabels.contractTone(h.contractStatus)),
                ],
              ),
              const Divider(height: 22),
              TenantInfoRow(
                icon: Icons.date_range_outlined,
                label: 'Thời gian ở',
                value: '${TenantFormat.date(h.checkInDate)} → ${TenantFormat.date(h.checkOutDate)}',
              ),
              TenantInfoRow(
                  icon: Icons.timelapse_rounded, label: 'Đã ở', value: TenantFormat.duration(h.stayDays)),
              TenantInfoRow(
                icon: Icons.savings_outlined,
                label: 'Tiền cọc',
                value: '${TenantFormat.money(h.depositAmount)} · ${TenantLabels.deposit(h.depositStatus)}',
              ),
              TenantInfoRow(
                icon: Icons.receipt_long_outlined,
                label: 'Tất toán',
                value: settled
                    ? '${TenantFormat.money(h.settlementTotal!)} · ${TenantLabels.invoice(h.settlementStatus ?? '')}'
                    : 'Không có hóa đơn tất toán',
              ),
              const SizedBox(height: 6),
              TenantBadge(
                label: h.remainingDebt > 0
                    ? 'Còn nợ ${TenantFormat.money(h.remainingDebt)}'
                    : 'Đã tất toán xong, không còn nợ',
                tone: h.remainingDebt > 0 ? TenantTone.red : TenantTone.green,
                icon: h.remainingDebt > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
              ),
              if (h.endReason != null) ...[
                const SizedBox(height: 8),
                Text('Lý do: ${h.endReason}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
