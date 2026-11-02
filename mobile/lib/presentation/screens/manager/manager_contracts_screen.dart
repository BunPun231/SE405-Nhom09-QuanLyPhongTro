import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/contract_service.dart';
import '../../../core/services/motel_service.dart';
import '../../../core/services/resident_service.dart';
import 'contracts/contract_create_wizard.dart';
import 'contracts/contract_detail_screen.dart';
import 'contracts/contract_ui.dart';

/// UC64 – Danh sách hợp đồng (phía Quản lý): lọc theo khu trọ, trạng thái, phòng;
/// tìm theo tên khách / số phòng; phân trang 20 bản ghi (BR64.8).
class ManagerContractsScreen extends StatefulWidget {
  const ManagerContractsScreen({super.key});

  @override
  State<ManagerContractsScreen> createState() => _ManagerContractsScreenState();
}

class _StatusFilter {
  final String key;
  final String label;
  final String? status;
  final bool expiring;
  const _StatusFilter(this.key, this.label, {this.status, this.expiring = false});
}

const _filters = <_StatusFilter>[
  _StatusFilter('ALL', 'Tất cả'),
  _StatusFilter('ACTIVE', 'Đang hiệu lực', status: 'ACTIVE'),
  _StatusFilter('EXPIRING', 'Sắp hết hạn', expiring: true),
  _StatusFilter('DRAFT', 'Chờ thu cọc', status: 'DRAFT'),
  _StatusFilter('PENDING_LIQUIDATION', 'Chờ tất toán', status: 'PENDING_LIQUIDATION'),
  _StatusFilter('LIQUIDATED', 'Đã thanh lý', status: 'LIQUIDATED'),
  _StatusFilter('CANCELED', 'Đã hủy', status: 'CANCELED'),
];

class _ManagerContractsScreenState extends State<ManagerContractsScreen> {
  static const int _pageSize = 20;

  List<MotelResult> _motels = [];
  MotelResult? _motel;
  List<RoomResult> _rooms = [];
  final Map<String, String> _residentNames = {};

  final List<ContractResult> _contracts = [];
  int _page = 0;
  int _totalPages = 0;
  int _totalElements = 0;

  bool _loadingInit = true;
  bool _loadingList = false;
  bool _loadingMore = false;
  String? _error;

  String _filterKey = 'ALL';
  int? _roomId;
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() {
      _loadingInit = true;
      _error = null;
    });
    try {
      final motels = await MotelService.list(size: 100);
      _motels = motels.content;
      _motel = _motels.isNotEmpty ? _motels.first : null;
      await Future.wait([_loadRooms(), _loadResidents()]);
      await _reload();
    } catch (e) {
      _error = Fmt.errorText(e);
    } finally {
      if (mounted) setState(() => _loadingInit = false);
    }
  }

  Future<void> _loadRooms() async {
    final motel = _motel;
    if (motel == null) {
      _rooms = [];
      return;
    }
    try {
      final res = await RoomService.list(motel.id, size: 500);
      _rooms = res.content..sort((a, b) => a.roomNumber.compareTo(b.roomNumber));
    } catch (_) {
      _rooms = [];
    }
  }

  Future<void> _loadResidents() async {
    try {
      var page = 0;
      while (page < 10) {
        final res = await ResidentService.list(page: page, size: 100);
        for (final r in res.content) {
          _residentNames[r.userId] = r.fullName;
        }
        page++;
        if (page >= res.totalPages) break;
      }
    } catch (_) {}
  }

  _StatusFilter get _filter => _filters.firstWhere((f) => f.key == _filterKey);

  Future<void> _reload() async {
    final motel = _motel;
    if (motel == null) return;
    setState(() {
      _loadingList = true;
      _error = null;
    });
    try {
      final res = await ContractService.listByMotel(
        motel.id,
        status: _filter.status,
        expiring: _roomId == null && _filter.expiring,
        roomId: _roomId,
        page: 0,
        size: _pageSize,
      );
      _contracts
        ..clear()
        ..addAll(_applyExpiringIfRoom(res.content));
      _page = 0;
      _totalPages = res.totalPages;
      _totalElements = res.totalElements;
    } catch (e) {
      _error = Fmt.errorText(e);
    } finally {
      if (mounted) setState(() => _loadingList = false);
    }
  }

  /// Khi lọc theo phòng, backend không kết hợp được với "sắp hết hạn" nên lọc thêm ở app.
  List<ContractResult> _applyExpiringIfRoom(List<ContractResult> list) {
    if (_roomId != null && _filter.expiring) {
      return list.where((c) => ContractRules.isExpiringSoon(c.status, c.endDate)).toList();
    }
    return list;
  }

  bool get _hasMore => _page + 1 < _totalPages;

  Future<void> _loadMore() async {
    final motel = _motel;
    if (motel == null || _loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final res = await ContractService.listByMotel(
        motel.id,
        status: _filter.status,
        expiring: _roomId == null && _filter.expiring,
        roomId: _roomId,
        page: _page + 1,
        size: _pageSize,
      );
      _contracts.addAll(_applyExpiringIfRoom(res.content));
      _page = res.number;
      _totalPages = res.totalPages;
      _totalElements = res.totalElements;
    } catch (e) {
      if (mounted) showSnack(context, Fmt.errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _changeMotel(MotelResult? motel) async {
    if (motel == null || motel.id == _motel?.id) return;
    setState(() {
      _motel = motel;
      _roomId = null;
    });
    await _loadRooms();
    await _reload();
  }

  String _roomLabel(int roomId) {
    for (final r in _rooms) {
      if (r.id == roomId) return 'Phòng ${r.roomNumber}';
    }
    return 'Phòng #$roomId';
  }

  String _tenantName(String userId) => _residentNames[userId] ?? 'Khách thuê';

  List<ContractResult> get _visible {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _contracts;
    return _contracts.where((c) {
      return _tenantName(c.primaryResidentUserId).toLowerCase().contains(q) ||
          _roomLabel(c.roomId).toLowerCase().contains(q) ||
          c.displayCode.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _openCreate() async {
    await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => ContractCreateWizard(initialMotelId: _motel?.id)),
    );
    if (!mounted) return;
    await _loadResidents();
    await _reload();
  }

  Future<void> _openDetail(ContractResult c) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ContractDetailScreen(contractId: c.id, isManager: true)),
    );
    if (mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _motels.isEmpty ? null : _openCreate,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Lập hợp đồng', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _loadingInit
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
          : _motels.isEmpty
              ? _buildNoMotel()
              : RefreshIndicator(
                  onRefresh: _reload,
                  color: AppColors.primary,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _buildFilters()),
                      ..._buildListSlivers(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildNoMotel() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.home_work_outlined, size: 48, color: AppColors.textSecondaryLight),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Chưa có khu trọ nào. Hãy tạo khu trọ trước khi lập hợp đồng.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _init, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _motel?.id,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Khu trọ',
                    prefixIcon: Icon(Icons.home_work_outlined, size: 18),
                  ),
                  items: _motels
                      .map((m) => DropdownMenuItem(value: m.id, child: Text(m.name, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (id) => _changeMotel(_motels.firstWhere((m) => m.id == id)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  key: ValueKey('room-filter-${_motel?.id}'),
                  initialValue: _roomId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Phòng'),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Tất cả phòng')),
                    ..._rooms.map((r) => DropdownMenuItem<int?>(value: r.id, child: Text('Phòng ${r.roomNumber}'))),
                  ],
                  onChanged: (id) {
                    setState(() => _roomId = id);
                    _reload();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Tìm theo tên khách, số phòng, mã HĐ',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Xóa tìm kiếm',
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _filters[i];
                final selected = f.key == _filterKey;
                return Center(
                  child: ChoiceChip(
                    label: Text(f.label),
                    selected: selected,
                    showCheckmark: true,
                    checkmarkColor: Colors.white,
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.textSecondaryLight,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: selected ? AppColors.primary : AppColors.borderLight),
                    ),
                    onSelected: (_) {
                      setState(() => _filterKey = f.key);
                      _reload();
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildListSlivers() {
    if (_loadingList && _contracts.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
        ),
      ];
    }
    if (_error != null && _contracts.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NoticeBox(text: 'Không thể tải danh sách hợp đồng: $_error', tone: Tone.red, icon: Icons.error_outline_rounded),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: _reload, child: const Text('Thử lại')),
                ],
              ),
            ),
          ),
        ),
      ];
    }
    final items = _visible;
    if (items.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.description_outlined, size: 32, color: AppColors.primary),
                  ),
                  const SizedBox(height: 12),
                  const Text('Không có dữ liệu hiển thị',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ContractTokens.heading)),
                  const SizedBox(height: 6),
                  Text(
                    _query.isNotEmpty && _hasMore
                        ? 'Chưa tìm thấy trong ${_contracts.length}/$_totalElements hợp đồng đã tải.'
                        : 'Không có hợp đồng phù hợp bộ lọc hiện tại.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 12),
                  if (_query.isNotEmpty && _hasMore)
                    OutlinedButton(onPressed: _loadMore, child: const Text('Tải thêm để tìm tiếp'))
                  else
                    ElevatedButton.icon(
                      onPressed: _openCreate,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Tạo hợp đồng mới'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        sliver: SliverToBoxAdapter(
          child: Text(
            _query.isEmpty
                ? 'Đang hiển thị ${_contracts.length}/$_totalElements hợp đồng'
                : 'Tìm thấy ${items.length} trong ${_contracts.length}/$_totalElements hợp đồng đã tải',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => _buildCard(items[i]),
            childCount: items.length,
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          child: _hasMore
              ? OutlinedButton(
                  onPressed: _loadingMore ? null : _loadMore,
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: _loadingMore
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text('Tải thêm (còn ${_totalElements - _contracts.length} hợp đồng)'),
                )
              : Center(
                  child: Text(
                    _totalElements > 0 ? 'Đã hiển thị toàn bộ $_totalElements hợp đồng' : '',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                ),
        ),
      ),
    ];
  }

  Widget _buildCard(ContractResult c) {
    final tone = contractTone(c.status, c.endDate);
    final expiring = ContractRules.isExpiringSoon(c.status, c.endDate);
    final months = DateTime.tryParse(c.startDate) != null && DateTime.tryParse(c.endDate) != null
        ? ContractRules.durationMonths(DateTime.parse(c.startDate), DateTime.parse(c.endDate))
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openDetail(c),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: expiring ? AppColors.warning : AppColors.borderLight, width: expiring ? 1.5 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.description_rounded, color: tone.fg, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _tenantName(c.primaryResidentUserId),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ContractTokens.heading),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_roomLabel(c.roomId)} · ${c.displayCode}',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(label: contractStatusText(c.status, c.endDate), tone: tone),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _metric(
                        'Thời hạn',
                        '${Fmt.date(c.startDate)} → ${Fmt.date(c.endDate)}${months != null ? ' ($months th)' : ''}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _metric('Giá thuê', Fmt.vnd(c.rentPrice))),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tiền cọc', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  Fmt.vnd(c.depositAmount),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ContractTokens.heading),
                                ),
                              ),
                              const SizedBox(width: 6),
                              StatusBadge(label: ContractRules.depositLabel(c.depositStatus), tone: depositTone(c.depositStatus)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ContractTokens.heading)),
      ],
    );
  }
}
