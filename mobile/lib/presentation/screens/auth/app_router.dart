import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/app_models.dart';
import '../../../core/network/api_client.dart';
import '../main_navigation_screen.dart';
import 'login_screen.dart';

/// AppRouter kiểm tra session, nếu đã login → vào đúng UI theo role.
/// Nếu chưa login → hiển thị LoginScreen.
class AppRouter extends StatefulWidget {
  const AppRouter({Key? key}) : super(key: key);

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  bool _loading = true;
  UserRole? _initialRole;
  String? _savedUserName;
  UserRole? _loggedInRole;
  String? _loggedInUserName;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await ApiClient.init();
    final prefs = await SharedPreferences.getInstance();
    final token = ApiClient.accessToken;
    final roleStr = prefs.getString('user_role');
    final userName = prefs.getString('user_fullname');

    if (token != null && token.isNotEmpty && roleStr != null) {
      _initialRole = _parseRole(roleStr);
      _savedUserName = userName ?? 'Người dùng';
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  UserRole _parseRole(String role) {
    switch (role.toUpperCase()) {
      case 'MANAGER':
      case 'OWNER':
        return UserRole.manager;
      case 'TENANT':
      case 'RESIDENT':
        return UserRole.tenant;
      case 'TECHNICIAN':
      case 'STAFF':
        return UserRole.technician;
      case 'ADMIN':
        return UserRole.admin;
      default:
        return UserRole.tenant;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.home_work_rounded, size: 48, color: Color(0xFF2563EB)),
              SizedBox(height: 16),
              CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF2563EB),
              ),
            ],
          ),
        ),
      );
    }

    if (_initialRole != null) {
      return MainNavigationScreen(
        initialRole: _initialRole!,
        userName: _savedUserName ?? 'Người dùng',
      );
    }

    if (_loggedInRole != null) {
      return MainNavigationScreen(
        initialRole: _loggedInRole!,
        userName: _loggedInUserName ?? 'Người dùng',
      );
    }

    return LoginScreen(
      onLoginSuccess: (UserRole role, String userName) {
        if (mounted) {
          setState(() {
            _loggedInRole = role;
            _loggedInUserName = userName;
          });
        }
      },
    );
  }
}
