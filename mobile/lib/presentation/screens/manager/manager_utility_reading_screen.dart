import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/invoice_service.dart';

class ManagerUtilityReadingScreen extends StatefulWidget {
  const ManagerUtilityReadingScreen({Key? key}) : super(key: key);

  @override
  State<ManagerUtilityReadingScreen> createState() => _ManagerUtilityReadingScreenState();
}

class _ManagerUtilityReadingScreenState extends State<ManagerUtilityReadingScreen> {
  List<MeterReadingResult> _readings = [];
  bool _isLoading = true;
  String _selectedStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadMeterReadings();
  }

  Future<void> _loadMeterReadings() async {
    setState(() => _isLoading = true);
    try {
      final res = await MeterReadingService.list();
      if (mounted) {
        setState(() {
          _readings = res.content;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _readings.where((r) {
      if (_selectedStatus == 'ALL') return true;
      return r.status == _selectedStatus;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSubmitReadingSheet,
        backgroundColor: AppColors.primary,
        elevation: 2,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _filterChip('Tất cả (${_readings.length})', 'ALL'),
                _filterChip('Chờ duyệt (${_readings.where((r) => r.status == 'PENDING' || r.status == 'SUBMITTED').length})', 'PENDING'),
                _filterChip('Đã duyệt (${_readings.where((r) => r.status == 'APPROVED').length})', 'APPROVED'),
                _filterChip('Từ chối (${_readings.where((r) => r.status == 'REJECTED').length})', 'REJECTED'),
              ],
            ),
          ),

          // List of Readings
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadMeterReadings,
              color: AppColors.primary,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 70, height: 70,
                                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
                                child: const Icon(Icons.bolt_rounded, size: 36, color: AppColors.primary),
                              ),
                              const SizedBox(height: 16),
                              const Text('Chưa có chỉ số điện nước nào', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              const SizedBox(height: 6),
                              const Text('Nhấn nút + bên dưới để nhập chỉ số điện nước tháng này', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) => _buildReadingCard(filtered[index]),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _selectedStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedStatus = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0)),
            boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))] : [],
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.textSecondaryLight),
          ),
        ),
      ),
    );
  }

  Widget _buildReadingCard(MeterReadingResult r) {
    Color statusColor;
    String statusText;

    if (r.status == 'APPROVED') {
      statusColor = AppColors.success;
      statusText = 'Đã duyệt';
    } else if (r.status == 'REJECTED') {
      statusColor = AppColors.danger;
      statusText = 'Từ chối';
    } else {
      statusColor = AppColors.warning;
      statusText = 'Chờ duyệt';
    }

    final isElectric = r.serviceName.toLowerCase().contains('điện');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: (isElectric ? Colors.amber : Colors.blue).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isElectric ? Icons.bolt_rounded : Icons.water_drop_rounded,
                    color: isElectric ? Colors.amber[800] : Colors.blue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${r.serviceName} · Phòng #${r.roomId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                      const SizedBox(height: 3),
                      Text('Kỳ: ${r.billingMonth}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: const Color(0xFFF1F5F9)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chỉ số cũ: ${r.oldReading.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                    const SizedBox(height: 2),
                    Text('Chỉ số mới: ${r.newReading?.toStringAsFixed(0) ?? 'Chưa ghi'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Tiêu thụ', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                    Text('${r.consumption?.toStringAsFixed(0) ?? '0'} đơn vị', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
              ],
            ),
            if (r.status == 'PENDING' || r.status == 'SUBMITTED') ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () async {
                      try {
                        await MeterReadingService.reject(r.id, reason: 'Chỉ số không khớp');
                        _loadMeterReadings();
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                      }
                    },
                    child: const Text('Từ chối', style: TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await MeterReadingService.approve(r.id);
                        _loadMeterReadings();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã phê duyệt chỉ số thành công!')));
                        }
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Phê duyệt', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSubmitReadingSheet() {
    final roomIdCtrl = TextEditingController();
    final serviceIdCtrl = TextEditingController(text: '1');
    final now = DateTime.now();
    final defaultMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final monthCtrl = TextEditingController(text: defaultMonth);
    final newReadingCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              const Row(
                children: [
                  Icon(Icons.bolt_rounded, color: AppColors.primary, size: 24),
                  SizedBox(width: 10),
                  Text('Ghi Chỉ Số Điện Nước', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                ],
              ),
              const SizedBox(height: 20),

              _buildField('Mã ID Phòng *', roomIdCtrl, 'Nhập ID phòng (ví dụ: 1)', Icons.meeting_room_outlined, inputType: TextInputType.number),
              const SizedBox(height: 14),

              _buildField('Mã ID Dịch Vụ (Điện/Nước) *', serviceIdCtrl, '1', Icons.design_services_outlined, inputType: TextInputType.number),
              const SizedBox(height: 14),

              _buildField('Kỳ chốt (YYYY-MM) *', monthCtrl, defaultMonth, Icons.calendar_month_outlined),
              const SizedBox(height: 14),

              _buildField('Chỉ số mới ghi nhận *', newReadingCtrl, 'Ví dụ: 1540', Icons.speed_outlined, inputType: TextInputType.number),
              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondaryLight, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        final rId = int.tryParse(roomIdCtrl.text);
                        final sId = int.tryParse(serviceIdCtrl.text);
                        final reading = double.tryParse(newReadingCtrl.text);
                        if (rId == null || sId == null || reading == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng điền đủ các mục!')));
                          return;
                        }
                        Navigator.pop(ctx);
                        try {
                          await MeterReadingService.submit(
                            roomId: rId,
                            serviceId: sId,
                            billingMonth: monthCtrl.text.trim(),
                            newReading: reading,
                          );
                          _loadMeterReadings();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Đã gửi chỉ số thành công!'),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi gửi chỉ số: $e')));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Lưu Chỉ Số', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint, IconData icon, {TextInputType inputType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: inputType,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
            prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondaryLight),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
        ),
      ],
    );
  }
}
