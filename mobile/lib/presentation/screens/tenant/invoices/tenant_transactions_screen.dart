import 'package:flutter/material.dart';

import '../../manager/invoices/transaction_history_screen.dart';

/// UC79 (Khách thuê): lịch sử các lần thanh toán của chính mình, có tìm kiếm và xuất file.
class TenantTransactionsScreen extends StatelessWidget {
  const TenantTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) => const TransactionHistoryScreen(isManager: false);
}
