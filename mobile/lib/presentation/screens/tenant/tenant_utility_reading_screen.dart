import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/contract_service.dart';
import '../../../core/services/service_service.dart';
import '../../../core/services/invoice_service.dart';

class _TenantServiceCell {
  final int serviceId;
  final String serviceName;
  final double oldReading;
  final MeterReadingResult? currentReading;

  _TenantServiceCell({
    required this.serviceId,
    required this.serviceName,
    required this.oldReading,
    this.currentReading,
  });
}

class TenantUtilityReadingScreen extends StatefulWidget {
  const TenantUtilityReadingScreen({Key? key}) : super(key: key);

  @override
  State<TenantUtilityReadingScreen> createState() => _TenantUtilityReadingScreenState();
}

class _TenantUtilityReadingScreenState extends State<TenantUtilityReadingScreen> {
  ContractResult? _contract;
  int? _roomId;
  int? _motelId;
  String? _roomNumber;
  List<ServiceResult> _services = [];
  List<MeterReadingResult> _readings = [];
  bool _isLoading = true;
  String? _error;
  late String _billingMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _billingMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final contracts = await ContractService.listMine();
      if (contracts.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'Bạn chưa có hợp đồng thuê phòng nào đang hoạt động.';
          });
        }
        return;
      }

      final activeContract = contracts.first;
      _contract = activeContract;
      _roomId = activeContract.roomId;
      _roomNumber = '${activeContract.roomId}';

      final detail = await ContractService.getDetail(activeContract.id);
      _motelId = detail.motelId;

      if (_motelId == null || _roomId == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'Không tìm thấy thông tin khu trọ hoặc phòng thuê.';
          });
        }
        return;
      }

      final servicesRes = await ServiceService.listByRoom(_motelId!, _roomId!);
      final readingsRes = await MeterReadingService.list(roomId: _roomId!, size: 500);

      if (mounted) {
        setState(() {
          _services = servicesRes
              .where((s) => ['METERED', 'TIERED', 'PER_QUANTITY', 'PER_INDEX'].contains(s.chargeType))
              .toList();
          _readings = readingsRes.content;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  List<_TenantServiceCell> get _serviceCells {
    final cells = <_TenantServiceCell>[];
    final targetMonth = '$_billingMonth-01';

    for (final svc in _services) {
      MeterReadingResult? currentReading;
      try {
        currentReading = _readings.firstWhere(
          (r) => r.serviceId == svc.id && r.billingMonth.startsWith(_billingMonth),
        );
      } catch (_) {
        currentReading = null;
      }

      final pastApproved = _readings
          .where((r) => r.serviceId == svc.id && r.status == 'APPROVED' && r.billingMonth.compareTo(targetMonth) < 0)
          .toList()
        ..sort((a, b) => b.billingMonth.compareTo(a.billingMonth));

      final oldReading = pastApproved.isNotEmpty ? (pastApproved.first.newReading ?? 0) : 0.0;
      cells.add(_TenantServiceCell(
        serviceId: svc.id,
        serviceName: svc.name,
        oldReading: oldReading,
        currentReading: currentReading,
      ));
    }
    return cells;
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse('$_billingMonth-01'),
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      helpText: 'CHỌN THÁNG GHI CHỈ SỐ',
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        _billingMonth = '${picked.year}-${picked.month.toString().padLeft(2, '0')}';
      });
      _loadData();
    }
  }

  void _showSubmitSheet() {
    if (_roomId == null) return;
    final cells = _serviceCells;
    final ctrls = <int, TextEditingController>{};

    for (final cell in cells) {
      ctrls[cell.serviceId] = TextEditingController(
        text: cell.currentReading?.newReading?.toStringAsFixed(0) ?? '',
      );
    }

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
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.speed_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tự báo chỉ số - Phòng ${_roomNumber ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Kỳ tháng: $_billingMonth',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
                child: SingleChildScrollView(
                  child: Column(
                    children: cells.map((cell) {
                      final approved = cell.currentReading?.status == 'APPROVED';
                      final isElectric = cell.serviceName.toLowerCase().contains('điện');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: approved ? AppColors.success.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: approved ? AppColors.success.withValues(alpha: 0.2) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isElectric ? Icons.bolt_rounded : Icons.water_drop_rounded,
                                  size: 16,
                                  color: isElectric ? Colors.amber[700] : Colors.blue,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  cell.serviceName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const Spacer(),
                                if (approved)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('Đã duyệt', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Đầu kỳ: ${cell.oldReading.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 140,
                                  child: TextField(
                                    controller: ctrls[cell.serviceId],
                                    keyboardType: TextInputType.number,
                                    enabled: !approved,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      hintText: 'Cuối kỳ',
                                      hintStyle: const TextStyle(fontSize: 12),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        for (final c in ctrls.values) c.dispose();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Đóng'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        bool submitted = false;

                        for (final cell in cells) {
                          if (cell.currentReading?.status == 'APPROVED') continue;
                          final text = ctrls[cell.serviceId]?.text.trim() ?? '';
                          if (text.isEmpty) continue;
                          final val = double.tryParse(text);
                          if (val == null) continue;

                          if (val < cell.oldReading) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Chỉ số ${cell.serviceName} phải >= ${cell.oldReading}!'), backgroundColor: AppColors.danger),
                              );
                            }
                            return;
                          }

                          submitted = true;
                          try {
                            await MeterReadingService.submit(
                              roomId: _roomId!,
                              serviceId: cell.serviceId,
                              billingMonth: '$_billingMonth-01',
                              newReading: val,
                            );
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Lỗi gửi ${cell.serviceName}: $e'), backgroundColor: AppColors.danger),
                              );
                            }
                          }
                        }

                        for (final c in ctrls.values) c.dispose();

                        if (submitted) {
                          _loadData();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã gửi chỉ số thành công! Chờ quản lý duyệt.'), backgroundColor: AppColors.success),
                            );
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Vui lòng nhập chỉ số mới.')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Gửi Báo Chỉ Số', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildStatusBadge(String? status) {
    Color color;
    String label;
    switch (status) {
      case 'APPROVED':
        color = AppColors.success;
        label = 'Đã duyệt';
        break;
      case 'REJECTED':
        color = AppColors.danger;
        label = 'Từ chối';
        break;
      case 'SUBMITTED':
        color = const Color(0xFF3B82F6);
        label = 'Đã nộp';
        break;
      default:
        color = AppColors.warning;
        label = 'Chưa ghi';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cells = _serviceCells;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSubmitSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_task_rounded, color: Colors.white),
        label: const Text('Báo Chỉ Số', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Filter Month Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phòng ${_roomNumber != null ? 'P$_roomNumber' : 'thuê'}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    Text(
                      'HĐ: ${_contract?.contractCode ?? '#${_contract?.id ?? ''}'}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _pickMonth,
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      color: const Color(0xFFF8FAFC),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Kỳ: $_billingMonth',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Body Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
                                const SizedBox(height: 12),
                                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondaryLight)),
                                const SizedBox(height: 12),
                                ElevatedButton(onPressed: _loadData, child: const Text('Thử lại')),
                              ],
                            ),
                          ),
                        )
                      : cells.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.speed_rounded, size: 32, color: AppColors.primary),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text('Chưa có dịch vụ tính chỉ số', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 6),
                                  const Text('Phòng chưa gán dịch vụ điện hoặc nước theo số.', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                              itemCount: cells.length,
                              itemBuilder: (context, index) {
                                final cell = cells[index];
                                final isElectric = cell.serviceName.toLowerCase().contains('điện');
                                final newReading = cell.currentReading?.newReading;
                                final consumption = cell.currentReading?.consumption ??
                                    (newReading != null && newReading >= cell.oldReading ? (newReading - cell.oldReading) : null);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFF1F5F9)),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
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
                                              padding: const EdgeInsets.all(10),
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
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(cell.serviceName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                                  const SizedBox(height: 2),
                                                  Text('Kỳ tháng: $_billingMonth', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                                                ],
                                              ),
                                            ),
                                            _buildStatusBadge(cell.currentReading?.status),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                                            children: [
                                              Column(
                                                children: [
                                                  const Text('Chỉ số cũ', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                                                  const SizedBox(height: 4),
                                                  Text('${cell.oldReading.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                                ],
                                              ),
                                              Container(width: 1, height: 26, color: const Color(0xFFE2E8F0)),
                                              Column(
                                                children: [
                                                  const Text('Chỉ số mới', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    newReading != null ? newReading.toStringAsFixed(0) : 'Chưa ghi',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 15,
                                                      color: newReading != null ? const Color(0xFF1E293B) : AppColors.textSecondaryLight,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Container(width: 1, height: 26, color: const Color(0xFFE2E8F0)),
                                              Column(
                                                children: [
                                                  const Text('Tiêu thụ', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    consumption != null ? consumption.toStringAsFixed(0) : '-',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}
