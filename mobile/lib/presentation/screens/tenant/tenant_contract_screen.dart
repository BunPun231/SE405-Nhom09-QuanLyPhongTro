import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/contract_service.dart';

class TenantContractScreen extends StatefulWidget {
  const TenantContractScreen({Key? key}) : super(key: key);

  @override
  State<TenantContractScreen> createState() => _TenantContractScreenState();
}

class _TenantContractScreenState extends State<TenantContractScreen> {
  List<ContractResult> _contracts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActiveContracts();
  }

  Future<void> _loadActiveContracts() async {
    setState(() => _isLoading = true);
    try {
      final res = await ContractService.listMine();
      if (mounted) {
        setState(() {
          _contracts = res;
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
        onRefresh: _loadActiveContracts,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _contracts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.description_outlined, size: 64, color: AppColors.textSecondaryLight),
                        const SizedBox(height: 12),
                        const Text('Không có hợp đồng active nào', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        const Text('Liên hệ chủ trọ để tạo hoặc cập nhật hợp đồng thuê', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _contracts.length,
                    itemBuilder: (context, index) {
                      final c = _contracts[index];
                      final rentStr = c.rentPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
                      final depositStr = c.depositAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Hợp Đồng Thuê #${c.contractCode ?? c.id}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                    child: const Text('ĐANG HIỆU LỰC', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),
                              _buildInfoRow('Phòng thuê', 'Phòng #${c.roomId}'),
                              _buildInfoRow('Tiền đặt cọc', '${depositStr}đ'),
                              _buildInfoRow('Tiền nhà hàng tháng', '${rentStr}đ'),
                              _buildInfoRow('Ngày bắt đầu', c.startDate),
                              _buildInfoRow('Ngày hết hạn', c.endDate),
                              _buildInfoRow('Trạng thái cọc', c.depositStatus),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
