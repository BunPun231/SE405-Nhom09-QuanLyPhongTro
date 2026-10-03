import 'package:flutter/material.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text('Quản Lý Người Dùng Hệ Thống', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: Icon(Icons.person),
            title: Text('Chủ Trọ Nguyễn Văn A'),
            subtitle: Text('Email: admin@roomrental.com | Khu trọ: 3'),
          ),
        ),
      ],
    );
  }
}
