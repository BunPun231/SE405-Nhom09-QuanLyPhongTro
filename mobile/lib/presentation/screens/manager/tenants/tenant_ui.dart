import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Bảng màu chữ trạng thái đậm (đủ tương phản trên nền tint) cho module Khách thuê.
class TenantTone {
  final Color fg;
  final Color bg;
  const TenantTone(this.fg, this.bg);

  static const green = TenantTone(Color(0xFF047857), Color(0xFFECFDF5));
  static const amber = TenantTone(Color(0xFFB45309), Color(0xFFFFFBEB));
  static const red = TenantTone(Color(0xFFB91C1C), Color(0xFFFEF2F2));
  static const violet = TenantTone(Color(0xFF6D28D9), Color(0xFFF5F3FF));
  static const blue = TenantTone(Color(0xFF1D4ED8), Color(0xFFEFF6FF));
  static const slate = TenantTone(Color(0xFF475569), Color(0xFFF1F5F9));
}

/// Nhãn + màu cho các trạng thái của module (thuần logic, có kiểm thử).
class TenantLabels {
  TenantLabels._();

  static String residency(String status) {
    switch (status) {
      case 'LIVING':
        return 'Đang ở';
      case 'PENDING':
        return 'Chờ vào ở';
      case 'FORMER':
        return 'Đã trả phòng';
      default:
        return 'Chưa có hợp đồng';
    }
  }

  static TenantTone residencyTone(String status) {
    switch (status) {
      case 'LIVING':
        return TenantTone.green;
      case 'PENDING':
        return TenantTone.violet;
      case 'FORMER':
        return TenantTone.slate;
      default:
        return TenantTone.amber;
    }
  }

  static String contract(String? status) {
    switch (status) {
      case 'ACTIVE':
        return 'HĐ đang hiệu lực';
      case 'DRAFT':
        return 'HĐ chờ cọc';
      case 'PENDING_LIQUIDATION':
        return 'HĐ chờ thanh lý';
      case 'LIQUIDATED':
        return 'HĐ đã thanh lý';
      case 'CANCELED':
      case 'CANCELLED':
        return 'HĐ đã hủy';
      default:
        return 'Chưa có hợp đồng';
    }
  }

  static TenantTone contractTone(String? status) {
    switch (status) {
      case 'ACTIVE':
        return TenantTone.green;
      case 'DRAFT':
        return TenantTone.violet;
      case 'PENDING_LIQUIDATION':
        return TenantTone.amber;
      case 'LIQUIDATED':
        return TenantTone.slate;
      case 'CANCELED':
      case 'CANCELLED':
        return TenantTone.red;
      default:
        return TenantTone.slate;
    }
  }

  static String account(String status) {
    switch (status) {
      case 'ACTIVE':
        return 'Tài khoản hoạt động';
      case 'INACTIVE':
        return 'Đã vô hiệu hóa';
      case 'LOCKED':
        return 'Tài khoản bị khóa';
      case 'PENDING':
        return 'Chờ kích hoạt';
      default:
        return status;
    }
  }

  static String invoice(String status) {
    switch (status) {
      case 'PAID':
        return 'Đã thu';
      case 'PARTIAL':
        return 'Thu một phần';
      case 'PENDING':
        return 'Chưa thu';
      case 'VOID':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  static TenantTone invoiceTone(String status) {
    switch (status) {
      case 'PAID':
        return TenantTone.green;
      case 'PARTIAL':
        return TenantTone.amber;
      case 'PENDING':
        return TenantTone.red;
      default:
        return TenantTone.slate;
    }
  }

  static String maintenance(String status) {
    switch (status) {
      case 'OPEN':
        return 'Mới báo';
      case 'PROCESSING':
        return 'Đang sửa';
      case 'COMPLETED':
        return 'Đã xong';
      case 'ESCALATED':
        return 'Đã chuyển cấp';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  static TenantTone maintenanceTone(String status) {
    switch (status) {
      case 'COMPLETED':
        return TenantTone.green;
      case 'OPEN':
      case 'PROCESSING':
      case 'ESCALATED':
        return TenantTone.amber;
      default:
        return TenantTone.slate;
    }
  }

  static String deposit(String? status) {
    switch (status) {
      case 'PAID':
        return 'Đã nhận cọc';
      case 'UNPAID':
        return 'Chưa nhận cọc';
      case 'REFUNDED':
        return 'Đã hoàn cọc';
      case 'DEDUCTED':
        return 'Đã trừ cọc';
      default:
        return status ?? '—';
    }
  }

  static String gender(String? g) {
    switch (g) {
      case 'MALE':
        return 'Nam';
      case 'FEMALE':
        return 'Nữ';
      case 'OTHER':
        return 'Khác';
      default:
        return '—';
    }
  }

  static String field(String? f) {
    switch (f) {
      case 'phone':
        return 'Số điện thoại';
      case 'email':
        return 'Email';
      case 'notes':
        return 'Ghi chú';
      case 'fullName':
        return 'Họ tên';
      case 'idCardNumber':
        return 'Số CCCD';
      case 'dateOfBirth':
        return 'Ngày sinh';
      case 'gender':
        return 'Giới tính';
      case 'avatar':
        return 'Ảnh đại diện';
      default:
        return f ?? 'Thông tin';
    }
  }

  static String activity(String action) {
    switch (action) {
      case 'CREATE_RESIDENT':
        return 'Tạo hồ sơ';
      case 'UPDATE_RESIDENT':
        return 'Cập nhật hồ sơ';
      case 'DEACTIVATE_RESIDENT':
        return 'Vô hiệu hóa hồ sơ';
      case 'REACTIVATE_RESIDENT':
        return 'Kích hoạt lại hồ sơ';
      case 'AUTO_REVOKE_ACCESS':
        return 'Tự động thu hồi quyền truy cập';
      default:
        return action;
    }
  }
}

/// Định dạng tiền / ngày theo kiểu Việt Nam.
class TenantFormat {
  TenantFormat._();

  static String money(double v) {
    final s = v.round().abs().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '${v < 0 ? '-' : ''}$s đ';
  }

  static String date(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  static String month(DateTime? d) {
    if (d == null) return '—';
    return 'Tháng ${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  /// "1 năm 2 tháng", "3 tháng 5 ngày", "12 ngày".
  static String duration(int days) {
    if (days <= 0) return 'Dưới 1 ngày';
    final years = days ~/ 365;
    final months = (days % 365) ~/ 30;
    final rest = (days % 365) % 30;
    final parts = <String>[];
    if (years > 0) parts.add('$years năm');
    if (months > 0) parts.add('$months tháng');
    if (years == 0 && rest > 0) parts.add('$rest ngày');
    return parts.join(' ');
  }

  static String initials(String name) {
    final t = name.trim();
    if (t.isEmpty) return 'K';
    final parts = t.split(RegExp(r'\s+'));
    return parts.last.characters.first.toUpperCase();
  }
}

/// Giải mã ảnh `data:image/...;base64,...` (ảnh lưu trực tiếp trong hồ sơ).
Uint8List? decodeDataImage(String? url) {
  if (url == null || !url.startsWith('data:image')) return null;
  try {
    return base64Decode(url.substring(url.indexOf(',') + 1));
  } catch (_) {
    return null;
  }
}

/// Chuyển bytes ảnh thành data URI để gửi API lưu hồ sơ.
String toDataImageUri(String base64) => 'data:image/jpeg;base64,$base64';

/// Nhãn trạng thái: nền tint + chữ đậm cùng màu (≥ 12sp).
class TenantBadge extends StatelessWidget {
  final String label;
  final TenantTone tone;
  final IconData? icon;
  const TenantBadge({super.key, required this.label, required this.tone, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: tone.fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: tone.fg),
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar khách: ảnh (data URI hoặc URL) hoặc chữ cái đầu tên.
class TenantAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double radius;
  const TenantAvatar({super.key, required this.name, this.imageUrl, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    final bytes = decodeDataImage(imageUrl);
    ImageProvider? provider;
    if (bytes != null) {
      provider = MemoryImage(bytes);
    } else if (imageUrl != null && imageUrl!.startsWith('http')) {
      provider = NetworkImage(imageUrl!);
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      foregroundImage: provider,
      child: Text(
        TenantFormat.initials(name),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          fontSize: radius * 0.75,
        ),
      ),
    );
  }
}

/// Ảnh hồ sơ (CCCD) có khung bo góc; chạm để phóng to.
class TenantImageBox extends StatelessWidget {
  final String label;
  final String? url;
  final List<int>? bytes;
  final double height;
  const TenantImageBox({
    super.key,
    required this.label,
    this.url,
    this.bytes,
    this.height = 110,
  });

  @override
  Widget build(BuildContext context) {
    Widget? image;
    final memory = bytes != null ? Uint8List.fromList(bytes!) : decodeDataImage(url);
    if (memory != null) {
      image = Image.memory(memory, fit: BoxFit.cover, width: double.infinity, height: height);
    } else if (url != null && url!.startsWith('http')) {
      image = Image.network(url!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: height,
          errorBuilder: (_, __, ___) => _placeholder(Icons.broken_image_outlined, 'Không tải được ảnh'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: image == null
              ? _placeholder(Icons.image_not_supported_outlined, 'Chưa có ảnh')
              : Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (ctx) => Dialog(
                        insetPadding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InteractiveViewer(child: image!),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Đóng'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    child: Semantics(label: 'Phóng to $label', button: true, child: image),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _placeholder(IconData icon, String text) => Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textSecondaryLight),
            const SizedBox(height: 4),
            Text(text,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
          ],
        ),
      );
}

/// Thẻ trắng chuẩn của module.
class TenantCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const TenantCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

/// Dòng thông tin: nhãn xám bên trái, giá trị đậm bên phải.
class TenantInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  const TenantInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondaryLight),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
          ),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Trạng thái rỗng / lỗi có nút hành động.
class TenantEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const TenantEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: Icon(icon, size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(message!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(minimumSize: const Size(160, 48)),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

/// Lấy thông báo lỗi gọn từ Exception của ApiClient.
String tenantErrorText(Object e) {
  final s = e.toString();
  return s.startsWith('Exception: ') ? s.substring(11) : s;
}
