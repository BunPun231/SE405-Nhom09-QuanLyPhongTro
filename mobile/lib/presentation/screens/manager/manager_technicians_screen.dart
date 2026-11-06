import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/motel_service.dart';
import '../../../core/services/technician_service.dart';
import '../../widgets/maintenance_widgets.dart';

/// Quản lý kỹ thuật viên (UC56–62): danh sách, thêm, khóa, reset mật khẩu.
class ManagerTechniciansScreen extends StatefulWidget {
  const ManagerTechniciansScreen({Key? key}) : super(key: key);

  @override
  State<ManagerTechniciansScreen> createState() => _ManagerTechniciansScreenState();
}

class _ManagerTechniciansScreenState extends State<ManagerTechniciansScreen> {
  List<TechnicianResult> _techs = [];
  List<MotelResult> _motels = [];
  String _query = '';
  bool _isLoading = true;
  String? _error;

  static const _expertiseSuggestions = ['Điện', 'Nước', 'Điện lạnh', 'Internet', 'Đồ gỗ', 'Khóa cửa'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
    try {
      final results = await Future.wait([TechnicianService.list(), MotelService.list()]);
      if (!mounted) return;
      setState(() {
        _techs = (results[0] as PageResponse<TechnicianResult>).content;
        _motels = (results[1] as PageResponse<MotelResult>).content;
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

  void _toast(String msg, {bool ok = false}) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: ok ? AppColors.success : null),
      );

  String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');

  List<TechnicianResult> get _visible {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _techs;
    return _techs.where((t) => t.fullName.toLowerCase().contains(q) || t.phone.contains(q)).toList();
  }

  String _motelNames(TechnicianResult t) {
    final names = t.assignedMotelIds
        .map((id) {
          for (final m in _motels) {
            if (m.id == id) return m.name;
          }
          return null;
        })
        .whereType<String>()
        .toList();
    return names.isEmpty ? 'Chưa phân công khu trọ' : names.join(', ');
  }

  // ─── Hành động ────────────────────────────────────────────────────────────

  Future<void> _lock(TechnicianResult t) async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Khóa tài khoản KTV?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${t.fullName} sẽ không thể đăng nhập cho tới khi được mở khóa.', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(labelText: 'Lý do (không bắt buộc)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            child: const Text('Khóa tài khoản'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await TechnicianService.lock(t.userId, reason: reasonCtrl.text.trim());
      _toast('Đã khóa tài khoản ${t.fullName}', ok: true);
      _load(showLoading: false);
    } catch (e) {
      _toast(_msg(e));
    }
  }

  Future<void> _resetPassword(TechnicianResult t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset mật khẩu?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Mật khẩu của ${t.fullName} sẽ được đặt lại về số điện thoại (${t.phone}).', style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await TechnicianService.resetPassword(t.userId);
      _toast('Đã reset mật khẩu về số điện thoại', ok: true);
    } catch (e) {
      _toast(_msg(e));
    }
  }

  void _showCreateSheet() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final selectedExpertise = <String>{};
    final selectedMotels = <int>{};
    var saving = false;
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetCtx).size.height * 0.9),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Thêm Kỹ Thuật Viên', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Tài khoản được tạo tự động, mật khẩu mặc định là số điện thoại',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                  const SizedBox(height: 16),
                  if (error != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                    ),
                  TextField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: maintenanceInputDecoration('Họ và tên *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: maintenanceInputDecoration('Số điện thoại *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: maintenanceInputDecoration('Email (không bắt buộc)'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Chuyên môn', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _expertiseSuggestions.map((e) {
                      final on = selectedExpertise.contains(e);
                      return FilterChip(
                        label: Text(e, style: TextStyle(fontSize: 12, color: on ? Colors.white : AppColors.textPrimaryLight)),
                        selected: on,
                        selectedColor: AppColors.primary,
                        backgroundColor: const Color(0xFFF8FAFC),
                        showCheckmark: false,
                        onSelected: (v) => setSheet(() => v ? selectedExpertise.add(e) : selectedExpertise.remove(e)),
                      );
                    }).toList(),
                  ),
                  if (_motels.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Khu trọ phụ trách', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    ..._motels.map((m) => CheckboxListTile(
                          value: selectedMotels.contains(m.id),
                          onChanged: (v) => setSheet(() => v == true ? selectedMotels.add(m.id) : selectedMotels.remove(m.id)),
                          title: Text(m.name, style: const TextStyle(fontSize: 13)),
                          activeColor: AppColors.primary,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        )),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              final name = nameCtrl.text.trim();
                              final phone = phoneCtrl.text.trim();
                              final email = emailCtrl.text.trim();
                              if (name.isEmpty || phone.isEmpty) {
                                setSheet(() => error = 'Vui lòng nhập họ tên và số điện thoại');
                                return;
                              }
                              if (!RegExp(r'^(84|0)(3|5|7|8|9)[0-9]{8}$').hasMatch(phone)) {
                                setSheet(() => error = 'Số điện thoại không hợp lệ (VD: 0912345678)');
                                return;
                              }
                              if (email.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                                setSheet(() => error = 'Email không hợp lệ');
                                return;
                              }
                              setSheet(() {
                                saving = true;
                                error = null;
                              });
                              try {
                                await TechnicianService.create(
                                  phone: phone,
                                  fullName: name,
                                  email: email,
                                  expertise: selectedExpertise.toList(),
                                  assignedMotelIds: selectedMotels.toList(),
                                );
                                if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                                _toast('Đã thêm KTV $name. Mật khẩu mặc định: $phone', ok: true);
                                _load(showLoading: false);
                              } catch (e) {
                                setSheet(() {
                                  saving = false;
                                  error = _msg(e);
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Thêm kỹ thuật viên', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Giao diện ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: const Text('Thêm KTV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(showLoading: false),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(children: [
                    const SizedBox(height: 120),
                    Center(child: Text(_error!, style: const TextStyle(color: AppColors.danger))),
                    const SizedBox(height: 12),
                    Center(child: TextButton(onPressed: _load, child: const Text('Thử lại'))),
                  ])
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    children: [
                      const Text('Kỹ Thuật Viên', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('${_techs.length} kỹ thuật viên', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (v) => setState(() => _query = v),
                        decoration: InputDecoration(
                          hintText: 'Tìm theo tên hoặc số điện thoại...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_visible.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 50),
                          child: Column(children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
                              child: const Icon(Icons.engineering_outlined, size: 36, color: AppColors.primary),
                            ),
                            const SizedBox(height: 16),
                            Text(_techs.isEmpty ? 'Chưa có kỹ thuật viên' : 'Không tìm thấy kết quả',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            const Text('Nhấn "Thêm KTV" để tạo tài khoản cho thợ sửa chữa',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                          ]),
                        ),
                      ..._visible.map(_buildCard),
                    ],
                  ),
      ),
    );
  }

  Widget _buildCard(TechnicianResult t) {
    final locked = t.locked;
    final statusColor = locked ? AppColors.danger : (t.available ? AppColors.success : AppColors.warning);
    final statusText = locked ? 'Đã khóa' : (t.available ? 'Sẵn sàng' : 'Đang bận');
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
                child: Text(t.fullName.isNotEmpty ? t.fullName.trim().split(' ').last[0].toUpperCase() : 'K',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(t.phone, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textSecondaryLight),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (v) => v == 'lock' ? _lock(t) : _resetPassword(t),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'reset', child: Text('Reset mật khẩu')),
                  if (!locked) const PopupMenuItem(value: 'lock', child: Text('Khóa tài khoản', style: TextStyle(color: AppColors.danger))),
                ],
              ),
            ]),
            if (t.expertise.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: t.expertise
                    .map((e) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(8)),
                          child: Text(e, style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.apartment_rounded, size: 14, color: AppColors.textSecondaryLight),
              const SizedBox(width: 6),
              Expanded(
                child: Text(_motelNames(t),
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight), overflow: TextOverflow.ellipsis),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
