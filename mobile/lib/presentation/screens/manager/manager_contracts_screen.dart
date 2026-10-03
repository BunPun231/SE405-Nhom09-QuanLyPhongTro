import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/contract_service.dart';
import '../../../core/services/motel_service.dart';
import '../../../core/services/resident_service.dart';

class ManagerContractsScreen extends StatefulWidget {
  const ManagerContractsScreen({Key? key}) : super(key: key);

  @override
  State<ManagerContractsScreen> createState() => _ManagerContractsScreenState();
}

class _ManagerContractsScreenState extends State<ManagerContractsScreen> {
  List<ContractResult> _contracts = [];
  bool _isLoading = true;
  String _selectedStatus = 'ALL';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadContracts();
  }

  Future<void> _loadContracts() async {
    setState(() => _isLoading = true);
    try {
      final res = await ContractService.list();
      if (mounted) {
        setState(() {
          _contracts = res.content;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _contracts.where((c) {
      if (_selectedStatus != 'ALL') {
        if (_selectedStatus == 'ACTIVE' && c.status != 'ACTIVE') return false;
        if (_selectedStatus == 'DRAFT' && c.status != 'DRAFT') return false;
        if (_selectedStatus == 'LIQUIDATED' &&
            c.status != 'LIQUIDATED' &&
            c.status != 'CANCELED' &&
            c.status != 'CANCELLED') {
          return false;
        }
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final code = (c.contractCode ?? '#${c.id}').toLowerCase();
        final room = 'phòng ${c.roomId}'.toLowerCase();
        return code.contains(q) || room.contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateContractSheet,
        backgroundColor: AppColors.primary,
        elevation: 2,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Column(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Tìm theo mã HĐ hoặc số phòng...',
                hintStyle: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondaryLight),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              ),
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                _filterChip('Tất cả (${_contracts.length})', 'ALL'),
                _filterChip('Hiệu lực (${_contracts.where((c) => c.status == 'ACTIVE').length})', 'ACTIVE'),
                _filterChip('Bản nháp (${_contracts.where((c) => c.status == 'DRAFT').length})', 'DRAFT'),
                _filterChip('Đã thanh lý (${_contracts.where((c) => c.status == 'LIQUIDATED' || c.status == 'CANCELED' || c.status == 'CANCELLED').length})', 'LIQUIDATED'),
              ],
            ),
          ),

          // Contracts list
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadContracts,
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
                                child: const Icon(Icons.description_outlined, size: 36, color: AppColors.primary),
                              ),
                              const SizedBox(height: 16),
                              const Text('Chưa có hợp đồng nào', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              const SizedBox(height: 6),
                              const Text('Nhấn nút + bên dưới để tạo hợp đồng thuê phòng', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) => _buildContractCard(filtered[index]),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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

  Widget _buildContractCard(ContractResult c) {
    Color statusColor;
    String statusText;

    if (c.status == 'ACTIVE') {
      statusColor = AppColors.success;
      statusText = 'Hiệu lực';
    } else if (c.status == 'DRAFT') {
      statusColor = AppColors.warning;
      statusText = 'Bản nháp';
    } else {
      statusColor = Colors.grey;
      statusText = 'Đã hủy / Thanh lý';
    }

    final rentStr = c.rentPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    final depositStr = c.depositAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showContractDetailSheet(c),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.description_outlined, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.contractCode ?? 'HĐ-#${c.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                            Text('Phòng #${c.roomId}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                          ],
                        ),
                      ],
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
                    Text('Giá thuê: ${rentStr}đ/tháng', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                    Text('Cọc: ${depositStr}đ (${c.depositStatus})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Thời hạn: ${c.startDate} ➔ ${c.endDate}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                    const Row(
                      children: [
                        Text('Chi tiết', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                        SizedBox(width: 2),
                        Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                      ],
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

  // ============ CHI TIẾT HỢP ĐỒNG (DETAIL + GIA HẠN + PHỤ LỤC + QUẢN LÝ CỌC + HỦY) ============
  void _showContractDetailSheet(ContractResult c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDetailState) {
          final rentStr = c.rentPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
          final depositStr = c.depositAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
          final isDepositUnpaid = c.depositStatus == 'PENDING' || c.depositStatus == 'UNPAID';

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: SingleChildScrollView(
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
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.contractCode ?? 'HĐ-#${c.id}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          Text('Phòng #${c.roomId}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: Text(c.status, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (isDepositUnpaid)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Chưa thu tiền đặt cọc', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E))),
                                Text('Số tiền cọc cần thu: $depositStrđ', style: const TextStyle(fontSize: 11, color: Color(0xFF92400E))),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              try {
                                await ContractService.collectDeposit(c.id);
                                _loadContracts();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xác nhận thu tiền cọc!')));
                                }
                              } catch (e) {
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber[800],
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Thu cọc', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),

                  // Contract Info items
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _detailRow('Thời hạn hợp đồng', '${c.startDate} ➔ ${c.endDate}'),
                        const Divider(height: 16),
                        _detailRow('Giá thuê hàng tháng', '$rentStrđ / tháng'),
                        const Divider(height: 16),
                        _detailRow('Tiền đặt cọc', '$depositStrđ (${c.depositStatus})'),
                        const Divider(height: 16),
                        _detailRow('Ngày tính phí', c.billingDate ?? 'Đầu tháng'),
                        const Divider(height: 16),
                        _detailRow('Kỳ đóng tiền', '${c.paymentCycleMonths ?? 1} tháng / lần'),
                        if (c.intendedMoveOutDate != null) ...[
                          const Divider(height: 16),
                          _detailRow('Ngày báo chuyển đi', c.intendedMoveOutDate!),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons row matching Web Frontend
                  const Text('Thao tác hợp đồng', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showManageDepositSheet(c);
                          },
                          icon: const Icon(Icons.shield_outlined, size: 16),
                          label: const Text('Quản lý cọc', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.success,
                            side: BorderSide(color: AppColors.success.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showRenewContractSheet(c);
                          },
                          icon: const Icon(Icons.autorenew_rounded, size: 16),
                          label: const Text('Gia hạn', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.amber[800],
                            side: BorderSide(color: Colors.amber.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showAppendixSheet(c);
                          },
                          icon: const Icon(Icons.post_add_rounded, size: 16),
                          label: const Text('Phụ lục', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelContract(c),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Hủy / Thanh lý hợp đồng', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: BorderSide(color: AppColors.danger.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
      ],
    );
  }

  // ============ GIA HẠN HỢP ĐỒNG (RENEW FORM) ============
  void _showRenewContractSheet(ContractResult c) {
    final endDateCtrl = TextEditingController(
      text: DateTime.parse(c.endDate).add(const Duration(days: 365)).toIso8601String().substring(0, 10),
    );

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
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.autorenew_rounded, color: Colors.amber[800], size: 24),
                  const SizedBox(width: 10),
                  const Text('Gia Hạn Hợp Đồng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                ],
              ),
              const SizedBox(height: 16),
              Text('Hợp đồng hiện tại kết thúc vào: ${c.endDate}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
              const SizedBox(height: 14),
              _buildField('Ngày kết thúc mới (YYYY-MM-DD) *', endDateCtrl, '2027-10-01', Icons.event_outlined),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (endDateCtrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx);
                    try {
                      await ContractService.addAppendix(c.id, {
                        'type': 'RENEW',
                        'newEndDate': endDateCtrl.text.trim(),
                      });
                      _loadContracts();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gia hạn hợp đồng thành công!')));
                      }
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi gia hạn: $e')));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Xác nhận gia hạn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============ PHỤ LỤC HỢP ĐỒNG (APPENDIX FORM) ============
  void _showAppendixSheet(ContractResult c) {
    String appendixType = 'PRICE_CHANGE';
    final effectiveDateCtrl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
    final newPriceCtrl = TextEditingController(text: c.rentPrice.toStringAsFixed(0));
    final newEndDateCtrl = TextEditingController();
    final moveOutCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: SingleChildScrollView(
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
                  const SizedBox(height: 20),
                  const Row(
                    children: [
                      Icon(Icons.post_add_rounded, color: AppColors.primary, size: 24),
                      SizedBox(width: 10),
                      Text('Tạo Phụ Lục Hợp Đồng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    ],
                  ),
                  const SizedBox(height: 18),

                  const Text('Loại điều chỉnh *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: appendixType,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'PRICE_CHANGE', child: Text('Thay đổi giá thuê')),
                      DropdownMenuItem(value: 'RENEW', child: Text('Gia hạn hợp đồng')),
                      DropdownMenuItem(value: 'MOVE_OUT_NOTICE', child: Text('Báo ngày chuyển đi')),
                      DropdownMenuItem(value: 'MANUAL_CLAUSE', child: Text('Điều khoản phụ khác')),
                    ],
                    onChanged: (val) {
                      if (val != null) setSheetState(() => appendixType = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  _buildField('Ngày hiệu lực (YYYY-MM-DD)', effectiveDateCtrl, '2026-10-01', Icons.calendar_today_outlined),
                  const SizedBox(height: 14),

                  if (appendixType == 'PRICE_CHANGE') ...[
                    _buildField('Giá thuê mới (đ/tháng) *', newPriceCtrl, '4000000', Icons.payments_outlined, inputType: TextInputType.number),
                    const SizedBox(height: 14),
                  ],

                  if (appendixType == 'RENEW') ...[
                    _buildField('Ngày kết thúc mới (YYYY-MM-DD) *', newEndDateCtrl, '2027-10-01', Icons.event_outlined),
                    const SizedBox(height: 14),
                  ],

                  if (appendixType == 'MOVE_OUT_NOTICE') ...[
                    _buildField('Ngày dự kiến dời đi *', moveOutCtrl, '2026-11-30', Icons.exit_to_app_outlined),
                    const SizedBox(height: 14),
                  ],

                  _buildField('Nội dung ghi chú điều khoản', notesCtrl, 'Ví dụ: Điều chỉnh theo thỏa thuận hai bên...', Icons.note_outlined),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        try {
                          await ContractService.addAppendix(c.id, {
                            'type': appendixType,
                            if (effectiveDateCtrl.text.isNotEmpty) 'effectiveDate': effectiveDateCtrl.text.trim(),
                            if (appendixType == 'PRICE_CHANGE') 'newRentPrice': double.tryParse(newPriceCtrl.text),
                            if (appendixType == 'RENEW') 'newEndDate': newEndDateCtrl.text.trim(),
                            if (appendixType == 'MOVE_OUT_NOTICE') 'intendedMoveOutDate': moveOutCtrl.text.trim(),
                            if (notesCtrl.text.isNotEmpty) 'metadata': notesCtrl.text.trim(),
                          });
                          _loadContracts();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu phụ lục hợp đồng!')));
                          }
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Lưu Phụ Lục', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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

  // ============ QUẢN LÝ TIỀN CỌC (COLLECT, REFUND, DEDUCT) ============
  void _showManageDepositSheet(ContractResult c) {
    String action = 'COLLECT';
    final amountCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
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
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: AppColors.success, size: 24),
                    SizedBox(width: 10),
                    Text('Quản Lý Tiền Đặt Cọc', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  ],
                ),
                const SizedBox(height: 18),

                const Text('Hành động cọc *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: action,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'COLLECT', child: Text('Thu tiền cọc (UNPAID ➔ PAID)')),
                    DropdownMenuItem(value: 'REFUND', child: Text('Hoàn cọc lại cho khách')),
                    DropdownMenuItem(value: 'DEDUCT', child: Text('Khấu trừ cọc (đền bù hư hại)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setSheetState(() => action = val);
                  },
                ),
                const SizedBox(height: 14),

                if (action == 'DEDUCT') ...[
                  _buildField('Số tiền khấu trừ (đ) *', amountCtrl, '500000', Icons.payments_outlined, inputType: TextInputType.number),
                  const SizedBox(height: 14),
                ],

                if (action == 'REFUND' || action == 'DEDUCT') ...[
                  _buildField('Lý do ghi nhận *', reasonCtrl, 'Đền bù thiết bị hỏng, trả phòng...', Icons.note_outlined),
                  const SizedBox(height: 14),
                ],

                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        if (action == 'COLLECT') {
                          await ContractService.collectDeposit(c.id);
                        } else if (action == 'DEDUCT') {
                          final amt = double.tryParse(amountCtrl.text) ?? 0;
                          await ContractService.deductDeposit(c.id, deductAmount: amt, reason: reasonCtrl.text.trim());
                        } else if (action == 'REFUND') {
                          await ContractService.refundDeposit(c.id, notes: reasonCtrl.text.trim());
                        }
                        _loadContracts();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật trạng thái cọc thành công!')));
                        }
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Xác nhận', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============ HỦY HỢP ĐỒNG (CANCEL) ============
  void _cancelContract(ContractResult c) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy hợp đồng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bạn có chắc muốn hủy hợp đồng ${c.contractCode ?? '#${c.id}'}? Phòng sẽ được giải phóng trạng thái.'),
            const SizedBox(height: 12),
            TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Lý do hủy (tùy chọn)', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Đóng')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận hủy', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ContractService.cancel(c.id, reason: reasonCtrl.text.trim());
        _loadContracts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã hủy hợp đồng!')));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  // ============ TẠO HỢP ĐỒNG MỚI (CREATE CONTRACT MODAL) ============
  void _showCreateContractSheet() async {
    List<MotelResult> motels = [];
    List<ResidentResult> residents = [];
    try {
      final motelRes = await MotelService.list();
      final residentRes = await ResidentService.list();
      motels = motelRes.content;
      residents = residentRes.content;
    } catch (_) {}

    if (!mounted) return;

    final roomIdCtrl = TextEditingController();
    final rentPriceCtrl = TextEditingController(text: '3500000');
    final depositCtrl = TextEditingController(text: '3500000');
    final startCtrl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
    final endCtrl = TextEditingController(text: DateTime.now().add(const Duration(days: 365)).toIso8601String().substring(0, 10));
    final phoneCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final idCardCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    String repType = 'new'; // 'existing' | 'new'
    ResidentResult? selectedResident = residents.isNotEmpty ? residents.first : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setCreateState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: SingleChildScrollView(
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
                  const SizedBox(height: 20),
                  const Row(
                    children: [
                      Icon(Icons.note_add_rounded, color: AppColors.primary, size: 24),
                      SizedBox(width: 10),
                      Text('Lập Hợp Đồng Thuê Phòng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    ],
                  ),
                  const SizedBox(height: 18),

                  _buildField('Mã ID Phòng *', roomIdCtrl, 'Nhập ID phòng (ví dụ: 1)', Icons.meeting_room_outlined, inputType: TextInputType.number),
                  const SizedBox(height: 14),

                  // Tab chọn khách cũ hay tạo khách mới
                  Container(
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setCreateState(() => repType = 'new'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: repType == 'new' ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: repType == 'new' ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : [],
                              ),
                              alignment: Alignment.center,
                              child: Text('Khách thuê mới', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: repType == 'new' ? AppColors.primary : AppColors.textSecondaryLight)),
                            ),
                          ),
                        ),
                        if (residents.isNotEmpty)
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setCreateState(() => repType = 'existing'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: repType == 'existing' ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: repType == 'existing' ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : [],
                                ),
                                alignment: Alignment.center,
                                child: Text('Khách đã có sẵn', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: repType == 'existing' ? AppColors.primary : AppColors.textSecondaryLight)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (repType == 'existing' && residents.isNotEmpty) ...[
                    DropdownButtonFormField<ResidentResult>(
                      value: selectedResident,
                      decoration: InputDecoration(
                        labelText: 'Chọn khách thuê đại diện',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      items: residents.map((r) => DropdownMenuItem(value: r, child: Text('${r.fullName} - ${r.phone}'))).toList(),
                      onChanged: (val) => setCreateState(() => selectedResident = val),
                    ),
                    const SizedBox(height: 14),
                  ] else ...[
                    _buildField('Họ tên khách thuê chính *', nameCtrl, 'Nguyễn Văn A', Icons.person_outline),
                    const SizedBox(height: 14),
                    _buildField('Số điện thoại *', phoneCtrl, '0901234567', Icons.phone_outlined, inputType: TextInputType.phone),
                    const SizedBox(height: 14),
                    _buildField('Số CCCD/CMND *', idCardCtrl, '079090000000', Icons.badge_outlined, inputType: TextInputType.number),
                    const SizedBox(height: 14),
                    _buildField('Email (không bắt buộc)', emailCtrl, 'email@example.com', Icons.email_outlined, inputType: TextInputType.emailAddress),
                    const SizedBox(height: 14),
                  ],

                  Row(
                    children: [
                      Expanded(child: _buildField('Giá thuê (đ/tháng) *', rentPriceCtrl, '3500000', Icons.payments_outlined, inputType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField('Tiền cọc (đ) *', depositCtrl, '3500000', Icons.shield_outlined, inputType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(child: _buildField('Ngày bắt đầu', startCtrl, '2026-10-01', Icons.calendar_today_outlined)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField('Ngày kết thúc', endCtrl, '2027-10-01', Icons.event_outlined)),
                    ],
                  ),
                  const SizedBox(height: 24),

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
                            final rent = double.tryParse(rentPriceCtrl.text);
                            final dep = double.tryParse(depositCtrl.text);

                            if (rId == null || rent == null || dep == null) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng điền đủ các mục bắt buộc!')));
                              return;
                            }

                            Navigator.pop(ctx);
                            try {
                              final body = {
                                'roomId': rId,
                                'rentPrice': rent,
                                'depositAmount': dep,
                                'startDate': startCtrl.text.trim(),
                                'endDate': endCtrl.text.trim(),
                                'depositStatus': 'UNPAID',
                              };

                              if (repType == 'existing' && selectedResident != null) {
                                body['primaryResidentUserId'] = selectedResident!.userId;
                              } else {
                                body['primaryResidentFullName'] = nameCtrl.text.trim();
                                body['primaryResidentPhone'] = phoneCtrl.text.trim();
                                body['primaryResidentIdCardNumber'] = idCardCtrl.text.trim();
                                if (emailCtrl.text.isNotEmpty) body['primaryResidentEmail'] = emailCtrl.text.trim();
                              }

                              await ContractService.create(body);
                              _loadContracts();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Đã tạo hợp đồng thành công!'),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tạo HĐ: $e')));
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Tạo Hợp Đồng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
