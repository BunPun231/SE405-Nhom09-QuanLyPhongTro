import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/contract_service.dart';
import '../manager/contracts/contract_detail_screen.dart';
import '../manager/contracts/contract_ui.dart';

/// UC65 (phía Khách thuê): chỉ hiển thị hợp đồng mà khách đứng tên hoặc ở cùng
/// (backend kiểm tra quyền – BR65.1); chạm để xem chi tiết đầy đủ.
class TenantContractScreen extends StatefulWidget {
  const TenantContractScreen({super.key});

  @override
  State<TenantContractScreen> createState() => _TenantContractScreenState();
}

class _TenantContractScreenState extends State<TenantContractScreen> {
  List<ContractResult> _contracts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await ContractService.listMine(activeOnly: false);
      res.sort((a, b) {
        int rank(ContractResult c) => c.status == 'ACTIVE' ? 0 : (c.status == 'DRAFT' || c.status == 'PENDING_LIQUIDATION') ? 1 : 2;
        final r = rank(a).compareTo(rank(b));
        return r != 0 ? r : b.startDate.compareTo(a.startDate);
      });
      if (mounted) setState(() => _contracts = res);
    } catch (e) {
      if (mounted) setState(() => _error = Fmt.errorText(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
            : _contracts.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 80),
                      const Icon(Icons.description_outlined, size: 56, color: AppColors.textSecondaryLight),
                      const SizedBox(height: 12),
                      Text(
                        _error == null ? 'Bạn chưa có hợp đồng nào' : 'Không thể tải dữ liệu hợp đồng',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ContractTokens.heading),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _error ?? 'Liên hệ chủ trọ để lập hoặc cập nhật hợp đồng thuê.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount: _contracts.length,
                    itemBuilder: (context, index) => _card(_contracts[index]),
                  ),
      ),
    );
  }

  Widget _card(ContractResult c) {
    final tone = contractTone(c.status, c.endDate);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ContractDetailScreen(contractId: c.id, isManager: false)),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Hợp đồng ${c.displayCode}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: ContractTokens.heading),
                      ),
                    ),
                    StatusBadge(label: contractStatusText(c.status, c.endDate), tone: tone),
                  ],
                ),
                const SizedBox(height: 8),
                InfoRow(label: 'Thời hạn', value: '${Fmt.date(c.startDate)} → ${Fmt.date(c.endDate)}'),
                InfoRow(label: 'Tiền nhà hàng tháng', value: Fmt.vnd(c.rentPrice), emphasize: true),
                InfoRow(
                  label: 'Tiền cọc',
                  value: '${Fmt.vnd(c.depositAmount)} · ${ContractRules.depositLabel(c.depositStatus)}',
                  valueColor: depositTone(c.depositStatus).fg,
                ),
                const SizedBox(height: 4),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Xem chi tiết', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
