import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/maintenance_service.dart';
import '../../../core/services/motel_service.dart';
import '../../../core/services/technician_service.dart';
import '../../widgets/maintenance_widgets.dart';

class ManagerMaintenanceScreen extends StatefulWidget {
  const ManagerMaintenanceScreen({Key? key}) : super(key: key);

  @override
  State<ManagerMaintenanceScreen> createState() => _ManagerMaintenanceScreenState();
}

class _ManagerMaintenanceScreenState extends State<ManagerMaintenanceScreen> {
  List<MotelResult> _motels = [];
  MotelResult? _selectedMotel;
  List<MaintenanceTicketResult> _tickets = [];
  String _statusFilter = ''; // '' = tất cả
  bool _isLoading = true;
  String? _error;

  static const _filters = <String, String>{
    '': 'Tất cả',
    'OPEN': 'Chờ xử lý',
    'PROCESSING': 'Đang xử lý',
    'COMPLETED': 'Hoàn thành',
    'CANCELLED': 'Đã hủy',
  };

  @override
  void initState() {
    super.initState();
    _loadMotels();
  }

  Future<void> _loadMotels() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await MotelService.list();
      _motels = res.content;
      if (_motels.isNotEmpty) {
        _selectedMotel = _motels.first;
        await _loadTickets(showLoading: false);
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTickets({bool showLoading = true}) async {
    if (_selectedMotel == null) return;
    if (showLoading) setState(() => _isLoading = true);
    try {
      final res = await MaintenanceService.listByMotel(_selectedMotel!.id, size: 100);
      if (!mounted) return;
      setState(() {
        _tickets = res.content;
        _error = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _toast(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  List<MaintenanceTicketResult> get _visible =>
      _statusFilter.isEmpty ? _tickets : _tickets.where((t) => t.status == _statusFilter).toList();

  int _count(String status) => status.isEmpty ? _tickets.length : _tickets.where((t) => t.status == status).length;

  Future<void> _cancelTicket(MaintenanceTicketResult t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy phiếu bảo trì?'),
        content: Text('Phiếu "${t.categoryLabel}" phòng ${t.roomNumber} sẽ bị hủy.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Giữ lại')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hủy phiếu', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await MaintenanceService.cancel(t.id);
      _toast('Đã hủy phiếu bảo trì');
      _loadTickets();
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _showAssignSheet(MaintenanceTicketResult t) async {
    List<TechnicianResult> techs;
    try {
      final res = await TechnicianService.list();
      techs = res.content.where((k) => !k.locked).toList();
    } catch (e) {
      _toast('Không tải được danh sách kỹ thuật viên');
      return;
    }
    if (!mounted) return;
    if (techs.isEmpty) {
      _toast('Chưa có kỹ thuật viên nào. Hãy thêm KTV trên web trước.');
      return;
    }
    String? selected = t.assignedTo != null && techs.any((k) => k.userId == t.assignedTo) ? t.assignedTo : techs.first.userId;
    var submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.isAssigned ? 'Đổi Kỹ Thuật Viên' : 'Giao Thợ Xử Lý',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Phòng ${t.roomNumber} - ${t.categoryLabel}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: techs
                        .map((k) => RadioListTile<String>(
                              value: k.userId,
                              groupValue: selected,
                              onChanged: (v) => setSheet(() => selected = v),
                              activeColor: AppColors.primary,
                              contentPadding: EdgeInsets.zero,
                              title: Text(k.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              subtitle: Text(
                                [
                                  k.phone,
                                  if (k.expertise.isNotEmpty) k.expertise.join(', '),
                                  if (!k.available) 'Đang bận',
                                ].join(' · '),
                                style: const TextStyle(fontSize: 11),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: submitting || selected == null
                      ? null
                      : () async {
                          setSheet(() => submitting = true);
                          try {
                            await MaintenanceService.assign(t.id, selected!);
                            if (sheetContext.mounted) Navigator.pop(sheetContext);
                            _toast('Đã giao việc cho kỹ thuật viên');
                            _loadTickets();
                          } catch (e) {
                            setSheet(() => submitting = false);
                            _toast(e.toString().replaceFirst('Exception: ', ''));
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Xác Nhận Giao Việc', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _selectedMotel == null ? _loadMotels() : _loadTickets(showLoading: false),
            child: _buildBody(),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_motels.length > 1)
            Container(
              height: 38,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<MotelResult>(
                  isExpanded: true,
                  value: _selectedMotel,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  borderRadius: BorderRadius.circular(10),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                  items: _motels.map((m) => DropdownMenuItem(value: m, child: Text(m.name))).toList(),
                  onChanged: (m) {
                    if (m == null) return;
                    setState(() => _selectedMotel = m);
                    _loadTickets();
                  },
                ),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.entries.map((e) {
                final active = _statusFilter == e.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${e.value} (${_count(e.key)})', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.textPrimaryLight)),
                    selected: active,
                    selectedColor: AppColors.primary,
                    backgroundColor: const Color(0xFFF8FAFC),
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _statusFilter = e.key),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return ListView(children: [
        const SizedBox(height: 120),
        Center(child: Text(_error!, style: const TextStyle(color: AppColors.danger))),
        const SizedBox(height: 12),
        Center(child: TextButton(onPressed: _loadMotels, child: const Text('Thử lại'))),
      ]);
    }
    if (_motels.isEmpty) {
      return ListView(children: [_emptyState(Icons.business_outlined, 'Chưa có khu trọ nào', 'Hãy tạo khu trọ trước khi nhận yêu cầu bảo trì')]);
    }
    final items = _visible;
    if (items.isEmpty) {
      return ListView(children: [
        _emptyState(
          Icons.handyman_outlined,
          _statusFilter.isEmpty ? 'Chưa có yêu cầu bảo trì' : 'Không có phiếu ở trạng thái này',
          'Các sự cố do khách thuê báo sẽ hiển thị tại đây',
        ),
      ]);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final t = items[i];
        final canAssign = t.isOpen || t.isProcessing || t.status == 'ESCALATED';
        return MaintenanceTicketCard(
          ticket: t,
          showReporter: true,
          onTap: () => showMaintenanceTicketDetail(context, t),
          actions: [
            if (t.isOpen || t.isProcessing)
              TextButton(
                onPressed: () => _cancelTicket(t),
                child: const Text('Hủy', style: TextStyle(color: AppColors.danger)),
              ),
            if (canAssign) ...[
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _showAssignSheet(t),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: Text(t.isAssigned ? 'Đổi Thợ' : 'Giao Thợ', style: const TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
          child: Icon(icon, size: 36, color: AppColors.primary),
        ),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
      ]),
    );
  }
}
