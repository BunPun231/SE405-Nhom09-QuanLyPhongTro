import 'package:flutter/material.dart';

class TechnicianEquipmentScreen extends StatelessWidget {
  const TechnicianEquipmentScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text('Danh Mục Thiết Bị & Vật Tư', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: Icon(Icons.ac_unit_rounded),
            title: Text('Điều hòa Panasonic 9000BTU (P205)'),
            subtitle: Text('Bảo trì định kỳ: 15/11/2026 | Trạng thái: Tốt'),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.water_damage_rounded),
            title: Text('Máy bơm nước tổng Tòa A'),
            subtitle: Text('Bảo trì định kỳ: 01/10/2026 | Trạng thái: Bình thường'),
          ),
        ),
      ],
    );
  }
}
