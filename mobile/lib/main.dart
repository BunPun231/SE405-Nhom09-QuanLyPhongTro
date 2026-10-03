import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/auth/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RoomRentalMobileApp());
}

class RoomRentalMobileApp extends StatelessWidget {
  const RoomRentalMobileApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Room Rental Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppRouter(),
    );
  }
}
