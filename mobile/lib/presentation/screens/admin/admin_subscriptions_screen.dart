import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AdminSubscriptionsScreen extends StatelessWidget {
  const AdminSubscriptionsScreen({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> _plans = const [
    {
      'name': 'Gói Cơ Bản (Starter)',
      'price': '199.000đ / tháng',
      'rooms': 'Tối đa 15 phòng',
      'activeUsers': 45,
      'color': Colors.blue,
    },
    {
      'name': 'Gói Chuyên Nghiệp (Pro)',
      'price': '499.000đ / tháng',
      'rooms': 'Tối đa 50 phòng',
      'activeUsers': 120,
      'color': Colors.purple,
    },
    {
      'name': 'Gói Doanh Nghiệp (Enterprise)',
      'price': '999.000đ / tháng',
      'rooms': 'Không giới hạn số phòng',
      'activeUsers': 28,
      'color': Colors.amber,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _plans.length,
        itemBuilder: (context, index) {
          final plan = _plans[index];
          final color = plan['color'] as Color;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.shield_rounded, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(plan['rooms'], style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                      const SizedBox(height: 4),
                      Text(plan['price'], style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text('${plan['activeUsers']} Chủ trọ', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
