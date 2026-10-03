import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/app_models.dart';
import '../../core/services/motel_service.dart';

class MobileHeader extends StatefulWidget {
  final UserRole currentRole;
  final String userName;
  final VoidCallback onOpenMenu;
  final VoidCallback onOpenNotifications;
  final int unreadCount;
  final String selectedBuilding;

  const MobileHeader({
    Key? key,
    required this.currentRole,
    this.userName = 'Nguyễn Văn Quyền',
    required this.onOpenMenu,
    required this.onOpenNotifications,
    this.unreadCount = 3,
    this.selectedBuilding = '',
  }) : super(key: key);

  @override
  State<MobileHeader> createState() => _MobileHeaderState();
}

class _MobileHeaderState extends State<MobileHeader> {
  bool _showSearch = false;
  String _searchQuery = '';
  late String _currentBuilding;
  final _searchController = TextEditingController();
  List<MotelResult> _buildings = [];

  @override
  void initState() {
    super.initState();
    _currentBuilding = widget.selectedBuilding;
    _loadBuildings();
  }

  Future<void> _loadBuildings() async {
    try {
      final res = await MotelService.list();
      if (mounted) {
        setState(() {
          _buildings = res.content;
          if (_buildings.isNotEmpty && _currentBuilding == widget.selectedBuilding) {
            _currentBuilding = _buildings.first.name;
          }
        });
      }
    } catch (_) {}
  }

  String get _roleTitle {
    switch (widget.currentRole) {
      case UserRole.manager:
        return 'Chủ trọ / Quản lý';
      case UserRole.tenant:
        return 'Phòng P205 - Khách thuê';
      case UserRole.technician:
        return 'Kỹ thuật viên điện nước';
      case UserRole.admin:
        return 'Quản trị viên Hệ thống';
    }
  }

  String get _avatarLetter {
    final parts = widget.userName.trim().split(' ');
    return parts.isNotEmpty ? parts.last[0].toUpperCase() : 'U';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.borderLight, width: 1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Row: Avatar + Name + Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    // Menu Button
                    GestureDetector(
                      onTap: widget.onOpenMenu,
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppColors.borderLight),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.menu_rounded, size: 18, color: AppColors.textPrimaryLight),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Avatar
                    Stack(
                      children: [
                        Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _avatarLetter,
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        Positioned(
                          right: 0, bottom: 0,
                          child: Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    // Name & Role
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_roleTitle, style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w500)),
                          Text(
                            widget.userName,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Bell Button
                    GestureDetector(
                      onTap: widget.onOpenNotifications,
                      child: Stack(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: AppColors.borderLight),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.notifications_none_rounded, size: 18, color: AppColors.textPrimaryLight),
                          ),
                          if (widget.unreadCount > 0)
                            Positioned(
                              top: 6, right: 6,
                              child: Container(
                                width: 8, height: 8,
                                decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),



              // Search Bar
              if (_showSearch)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            onChanged: (v) => setState(() => _searchQuery = v),
                            decoration: InputDecoration(
                              hintText: 'Tìm theo phòng, tên khách...',
                              hintStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                              prefixIcon: const Icon(Icons.search_rounded, size: 16, color: AppColors.textSecondaryLight),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () { _searchController.clear(); setState(() => _searchQuery = ''); },
                                      child: const Icon(Icons.close_rounded, size: 14, color: AppColors.textSecondaryLight),
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() { _showSearch = false; _searchQuery = ''; _searchController.clear(); }),
                        child: const Text('Hủy', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
