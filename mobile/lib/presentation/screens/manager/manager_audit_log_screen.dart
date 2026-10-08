import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/report_service.dart';

// ─── Label Maps (mirror AuditLogPage.tsx) ────────────────────────────────────
const _actionLabels = {
  'CREATE': 'Tạo mới', 'UPDATE': 'Cập nhật', 'DELETE': 'Xóa',
  'LOGIN': 'Đăng nhập', 'LOGOUT': 'Đăng xuất',
  'DEACTIVATE': 'Ngừng hoạt động', 'REACTIVATE': 'Kích hoạt lại',
  'USER_LOGIN': 'Đăng nhập hệ thống', 'REGISTER_MANAGER': 'Đăng ký tài khoản Quản lý',
  'CHANGE_PASSWORD': 'Thay đổi mật khẩu', 'RESET_PASSWORD': 'Đặt lại mật khẩu',
  'LOCK_TECHNICIAN': 'Khóa tài khoản kỹ thuật viên',
  'RESET_TECHNICIAN_PASSWORD': 'Đặt lại mật khẩu kỹ thuật viên',
  'CREATE_TECHNICIAN': 'Tạo tài khoản kỹ thuật viên',
  'CREATE_SERVICE': 'Thêm dịch vụ mới', 'UPDATE_SERVICE': 'Cập nhật dịch vụ', 'DELETE_SERVICE': 'Xóa dịch vụ',
  'CREATE_ROOM': 'Thêm phòng trọ mới', 'UPDATE_ROOM': 'Cập nhật thông tin phòng',
  'UPDATE_ROOM_STATUS': 'Thay đổi trạng thái phòng', 'DELETE_ROOM': 'Xóa phòng trọ',
  'CREATE_RESIDENT': 'Thêm khách thuê mới',
  'DEACTIVATE_RESIDENT': 'Ngừng hoạt động khách thuê', 'REACTIVATE_RESIDENT': 'Kích hoạt lại khách thuê',
  'CREATE_MOTEL': 'Thêm khu trọ mới', 'UPDATE_MOTEL': 'Cập nhật thông tin khu trọ', 'DELETE_MOTEL': 'Xóa khu trọ',
  'SUBMIT_METER_READING': 'Ghi chỉ số điện nước', 'APPROVE_METER_READING': 'Duyệt chỉ số điện nước',
  'COMPLETE_SETTLEMENT': 'Tất toán hợp đồng', 'RECEIVE_PAYMENT': 'Thu tiền hóa đơn',
  'CREATE_INVOICE': 'Tạo hóa đơn thanh toán', 'CANCEL_INVOICE': 'Hủy hóa đơn', 'DELETE_INVOICE': 'Xóa hóa đơn',
  'CREATE_CONTRACT': 'Tạo hợp đồng thuê phòng', 'ACTIVATE_CONTRACT': 'Kích hoạt hợp đồng',
  'CANCEL_CONTRACT': 'Hủy hợp đồng', 'ADJUST_CONTRACT': 'Điều chỉnh hợp đồng',
  'COLLECT_DEPOSIT': 'Thu tiền cọc', 'REFUND_DEPOSIT': 'Hoàn trả tiền cọc', 'DEDUCT_DEPOSIT': 'Khấu trừ tiền cọc',
  'CREATE_DEVICE': 'Thêm thiết bị mới', 'UPDATE_DEVICE': 'Cập nhật thiết bị', 'DELETE_DEVICE': 'Xóa thiết bị',
};

const _entityLabels = {
  'CONTRACT': 'Hợp đồng', 'ROOM': 'Phòng trọ', 'MOTEL': 'Khu trọ',
  'INVOICE': 'Hóa đơn', 'RESIDENT': 'Khách thuê', 'METER_READING': 'Chỉ số điện nước',
  'SERVICE': 'Dịch vụ', 'SERVICE_USAGE': 'Đăng ký dịch vụ',
  'TRANSACTION': 'Giao dịch', 'USER': 'Người dùng', 'DEVICE': 'Thiết bị',
};

const _roleLabels = {
  'ADMIN': 'Quản trị viên', 'MANAGER': 'Quản lý', 'OWNER': 'Chủ nhà',
  'RESIDENT': 'Khách thuê', 'TECHNICIAN': 'Kỹ thuật viên',
};

String _getActionLabel(String? action) {
  final key = (action ?? '').toUpperCase();
  return _actionLabels[key] ?? action ?? '';
}

String _getEntityLabel(String? entity) {
  final key = (entity ?? '').toUpperCase();
  return _entityLabels[key] ?? entity ?? '';
}

String _getRoleLabel(String? role) {
  final key = (role ?? '').toUpperCase();
  return _roleLabels[key] ?? role ?? '';
}

String _getEntityDesc(String? type, String? id) {
  if (type == null || type.isEmpty) return '-';
  final label = _getEntityLabel(type);
  if (id == null || id.isEmpty) return label;
  final isUuid = id.length == 36 && id.contains('-');
  if (isUuid) return label;
  final t = type.toUpperCase();
  if (t == 'ROOM') return 'Phòng (Mã #$id)';
  if (t == 'CONTRACT') return 'Hợp đồng (Mã #$id)';
  if (t == 'INVOICE') return 'Hóa đơn (Mã #$id)';
  if (t == 'MOTEL') return 'Khu trọ (Mã #$id)';
  if (t == 'METER_READING') return 'Chỉ số (Mã #$id)';
  if (t == 'SERVICE') return 'Dịch vụ (Mã #$id)';
  return '$label (Mã #$id)';
}

Color _badgeColor(String? action) {
  final key = (action ?? '').toUpperCase();
  if (key.contains('DELETE') || key.contains('CANCEL')) return const Color(0xFFEF4444);
  if (key.contains('CREATE') || key.contains('REACTIVATE') || key.contains('APPROVE')) return const Color(0xFF10B981);
  if (key.contains('DEACTIVATE') || key.contains('LOCK')) return const Color(0xFFF59E0B);
  return const Color(0xFF6366F1);
}

Color _badgeBg(String? action) => _badgeColor(action).withValues(alpha: 0.1);

String _fmtTimestamp(String ts) {
  try {
    final d = DateTime.parse(ts).toLocal();
    return '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')} ${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
  } catch (_) { return ts.length > 16 ? ts.substring(0, 16) : ts; }
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class ManagerAuditLogScreen extends StatefulWidget {
  const ManagerAuditLogScreen({Key? key}) : super(key: key);

  @override
  State<ManagerAuditLogScreen> createState() => _ManagerAuditLogScreenState();
}

class _ManagerAuditLogScreenState extends State<ManagerAuditLogScreen> {
  List<AuditLogResult> _logs = [];
  bool _isLoading = true;
  String? _error;
  int _page = 0;
  int _totalPages = 0;
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadAuditLogs();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAuditLogs({int page = 0}) async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await AuditService.listActivity(page: page, size: 20);
      if (mounted) {
        setState(() {
          _logs = res.content;
          _page = page;
          _totalPages = res.totalPages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<AuditLogResult> get _filtered {
    if (_search.isEmpty) return _logs;
    final q = _search.toLowerCase();
    return _logs.where((log) {
      return _getActionLabel(log.action).toLowerCase().contains(q) ||
          _getEntityLabel(log.entityType).toLowerCase().contains(q) ||
          _getRoleLabel(log.actorRole).toLowerCase().contains(q) ||
          _getEntityDesc(log.entityType, log.entityId).toLowerCase().contains(q) ||
          (log.ipAddress?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(children: [
        // Search bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo hành động, đối tượng...',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear_rounded, size: 18), onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); })
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              filled: true, fillColor: const Color(0xFFF8FAFC),
            ),
          ),
        ),
        // Content
        Expanded(child: RefreshIndicator(
          onRefresh: () => _loadAuditLogs(page: _page),
          color: AppColors.primary,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
              : _error != null
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.08), shape: BoxShape.circle),
                          child: const Icon(Icons.error_outline_rounded, size: 32, color: AppColors.danger)),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF475569), fontSize: 13)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: () => _loadAuditLogs(page: _page),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                          child: const Text('Thử lại')),
                    ]))
                  : _filtered.isEmpty
                      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.history_toggle_off_rounded, size: 56, color: Color(0xFFCBD5E1)),
                          const SizedBox(height: 12),
                          const Text('Chưa có nhật ký nào', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                          const SizedBox(height: 4),
                          Text(_search.isNotEmpty ? 'Không tìm thấy kết quả phù hợp' : 'Mọi thao tác quản lý sẽ được ghi nhận tại đây',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)), textAlign: TextAlign.center),
                        ]))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length + (_totalPages > 1 ? 1 : 0),
                          itemBuilder: (ctx, i) {
                            if (i == _filtered.length) return _buildPagination();
                            return _buildLogItem(_filtered[i]);
                          },
                        ),
        )),
      ]),
    );
  }

  Widget _buildLogItem(AuditLogResult log) {
    final actionLabel = _getActionLabel(log.action);
    final entityDesc = _getEntityDesc(log.entityType, log.entityId);
    final roleLabel = _getRoleLabel(log.actorRole);
    final badgeColor = _badgeColor(log.action);
    final badgeBg = _badgeBg(log.action);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(8)),
            child: Text(actionLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor)),
          ),
          const Spacer(),
          Text(_fmtTimestamp(log.timestamp), style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
        ]),
        const SizedBox(height: 8),
        // Entity description
        Text(entityDesc, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
        const SizedBox(height: 4),
        // Role + IP
        Row(children: [
          const Icon(Icons.person_outline_rounded, size: 12, color: Color(0xFF94A3B8)),
          const SizedBox(width: 4),
          Text(roleLabel.isNotEmpty ? roleLabel : 'Hệ thống', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          if (log.ipAddress != null && log.ipAddress!.isNotEmpty) ...[
            const SizedBox(width: 12),
            const Icon(Icons.router_outlined, size: 12, color: Color(0xFF94A3B8)),
            const SizedBox(width: 4),
            Text('IP: ${log.ipAddress}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          ],
        ]),
      ]),
    );
  }

  Widget _buildPagination() => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _pageBtn('Trước', _page > 0, () => _loadAuditLogs(page: _page - 1)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('${_page + 1} / $_totalPages', style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
      ),
      _pageBtn('Sau', _page < _totalPages - 1, () => _loadAuditLogs(page: _page + 1)),
    ]),
  );

  Widget _pageBtn(String label, bool enabled, VoidCallback onTap) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: enabled ? Colors.white : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
          color: enabled ? const Color(0xFF1E293B) : const Color(0xFF94A3B8))),
    ),
  );
}
