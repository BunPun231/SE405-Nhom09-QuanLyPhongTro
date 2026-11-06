import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/admin_service.dart';

/// Quản lý chủ trọ (UC09 xem danh sách, UC10 khóa/mở khóa tài khoản).
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({Key? key}) : super(key: key);

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  static const _pageSize = 20;
  static const _filters = <String, String>{'': 'Tất cả', 'ACTIVE': 'Hoạt động', 'LOCKED': 'Bị khóa'};

  final List<ManagerResult> _managers = [];
  String _status = '';
  String _query = '';
  int _page = 0;
  int _total = 0;
  bool _isLoading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool get _hasMore => _managers.length < _total;

  Future<void> _load({bool more = false}) async {
    if (more) {
      setState(() => _loadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _page = 0;
      });
    }
    try {
      final res = await AdminService.getManagers(
        search: _query.trim(),
        status: _status,
        page: more ? _page + 1 : 0,
        size: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        if (more) {
          _page++;
          _managers.addAll(res.content);
        } else {
          _managers
            ..clear()
            ..addAll(res.content);
        }
        _total = res.totalElements;
        _error = null;
        _isLoading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
        _loadingMore = false;
      });
    }
  }

  void _toast(String msg, {bool ok = false}) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: ok ? AppColors.success : null),
      );

  Future<void> _toggleLock(ManagerResult m) async {
    final reasonCtrl = TextEditingController();
    final lock = !m.locked;
    var showError = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(lock ? 'Khóa tài khoản chủ trọ?' : 'Mở khóa tài khoản?', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lock
                    ? '${m.fullName} sẽ không thể đăng nhập cho tới khi được mở khóa.'
                    : '${m.fullName} sẽ có thể đăng nhập và sử dụng hệ thống trở lại.',
                style: const TextStyle(fontSize: 13),
              ),
              if (lock) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  onChanged: (_) => setDialog(() => showError = false),
                  decoration: InputDecoration(
                    labelText: 'Lý do khóa *',
                    errorText: showError ? 'Vui lòng nhập lý do' : null,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () {
                if (lock && reasonCtrl.text.trim().isEmpty) {
                  setDialog(() => showError = true);
                  return;
                }
                Navigator.pop(ctx, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: lock ? AppColors.danger : AppColors.success,
                foregroundColor: Colors.white,
              ),
              child: Text(lock ? 'Xác nhận khóa' : 'Mở khóa ngay'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await AdminService.updateStatus(m.id, lock: lock, reason: reasonCtrl.text.trim());
      _toast(lock ? 'Đã khóa tài khoản ${m.fullName}' : 'Đã mở khóa tài khoản ${m.fullName}', ok: true);
      _load();
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          const Text('Quản Lý Chủ Trọ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('$_total tài khoản chủ trọ trên hệ thống', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
          const SizedBox(height: 12),
          TextField(
            onSubmitted: (v) {
              _query = v;
              _load();
            },
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Tìm theo tên, email, số điện thoại...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.entries.map((e) {
                final active = _status == e.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(e.value,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.textPrimaryLight)),
                    selected: active,
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    showCheckmark: false,
                    onSelected: (_) {
                      setState(() => _status = e.key);
                      _load();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Padding(padding: EdgeInsets.only(top: 80), child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Column(children: [
                Text(_error!, style: const TextStyle(color: AppColors.danger)),
                TextButton(onPressed: _load, child: const Text('Thử lại')),
              ]),
            )
          else if (_managers.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Column(children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
                  child: const Icon(Icons.people_outline_rounded, size: 36, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                const Text('Không có chủ trọ phù hợp', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('Thử đổi bộ lọc hoặc từ khóa tìm kiếm', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
              ]),
            )
          else ...[
            ..._managers.map((m) => ManagerCard(manager: m, onToggleLock: () => _toggleLock(m))),
            if (_hasMore)
              Center(
                child: TextButton(
                  onPressed: _loadingMore ? null : () => _load(more: true),
                  child: _loadingMore
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Xem thêm'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Thẻ chủ trọ, dùng ở danh sách và dashboard Admin.
class ManagerCard extends StatelessWidget {
  final ManagerResult manager;
  final VoidCallback? onToggleLock;

  const ManagerCard({Key? key, required this.manager, this.onToggleLock}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final m = manager;
    final locked = m.locked;
    final pending = m.status == 'PENDING_VERIFICATION';
    final color = locked ? AppColors.danger : (pending ? AppColors.warning : AppColors.success);
    final label = locked ? 'Bị khóa' : (pending ? 'Chờ xác minh' : 'Hoạt động');
    final contact = [if ((m.phone ?? '').isNotEmpty) m.phone!, if ((m.email ?? '').isNotEmpty) m.email!].join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(m.fullName.isNotEmpty ? m.fullName.trim().split(' ').last[0].toUpperCase() : 'C',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                  if ((m.tenantName ?? '').isNotEmpty)
                    Text(m.tenantName!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight), overflow: TextOverflow.ellipsis),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ]),
            if (contact.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.contact_phone_outlined, size: 14, color: AppColors.textSecondaryLight),
                const SizedBox(width: 6),
                Expanded(child: Text(contact, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight), overflow: TextOverflow.ellipsis)),
              ]),
            ],
            if (m.createdAt != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.event_outlined, size: 14, color: AppColors.textSecondaryLight),
                const SizedBox(width: 6),
                Text('Đăng ký ${DateFormat('dd/MM/yyyy').format(m.createdAt!.toLocal())}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
              ]),
            ],
            if (locked && (m.lockReason ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
                child: Text('Lý do khóa: ${m.lockReason}', style: const TextStyle(fontSize: 11, color: AppColors.danger)),
              ),
            ],
            if (onToggleLock != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: onToggleLock,
                  icon: Icon(locked ? Icons.lock_open_rounded : Icons.lock_outline_rounded, size: 16),
                  label: Text(locked ? 'Mở khóa' : 'Khóa tài khoản', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: locked ? AppColors.success : AppColors.danger,
                    side: BorderSide(color: locked ? AppColors.success : AppColors.danger),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
