import 'package:flutter/material.dart';

class TechnicianProfileScreen extends StatelessWidget {
  const TechnicianProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(radius: 40, child: Icon(Icons.handyman_rounded, size: 40)),
            SizedBox(height: 10),
            Text('Trần Văn Thợ - Kỹ Thuật Viên', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('SĐT: 0912 345 678', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
