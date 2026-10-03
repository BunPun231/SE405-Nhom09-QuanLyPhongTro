import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/report_service.dart';

class ManagerAuditLogScreen extends StatefulWidget {
  const ManagerAuditLogScreen({Key? key}) : super(key: key);

  @override
  State<ManagerAuditLogScreen> createState() => _ManagerAuditLogScreenState();
}

class _ManagerAuditLogScreenState extends State<ManagerAuditLogScreen> {
  List<AuditLogResult> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAuditLogs();
  }

  Future<void> _loadAuditLogs() async {
    setState(() => _isLoading = true);
    try {
      final res = await AuditService.listActivity();
      if (mounted) {
        setState(() {
          _logs = res.content;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadAuditLogs,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _logs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.history_toggle_off_rounded, size: 64, color: AppColors.textSecondaryLight),
                        const SizedBox(height: 12),
                        const Text('Chưa có nhật ký hoạt động nào', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        const Text('Mọi thao tác quản lý sẽ được ghi nhận tự động tại đây', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderLight)),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(log.action, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      Text(log.timestamp.split('T').first, style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight)),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(log.entityType != null ? '${log.entityType} (ID: ${log.entityId ?? ''})' : log.action, style: const TextStyle(fontSize: 11, color: AppColors.textPrimaryLight)),
                                  const SizedBox(height: 2),
                                  Text('Thực hiện: ${log.actorRole} (${log.actorId})', style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
