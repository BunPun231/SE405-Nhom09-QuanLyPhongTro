enum UserRole { manager, tenant, technician, admin }

class RoomModel {
  final String id;
  final String name;
  final String building;
  final String status; // 'occupied', 'available', 'maintenance'
  final double price;
  final int tenantCount;
  final int maxCapacity;

  RoomModel({
    required this.id,
    required this.name,
    required this.building,
    required this.status,
    required this.price,
    required this.tenantCount,
    required this.maxCapacity,
  });
}

class InvoiceModel {
  final String id;
  final String roomName;
  final String month;
  final double amount;
  final String dueDate;
  final String status; // 'PAID', 'UNPAID', 'OVERDUE'
  final double rentAmount;
  final double electricAmount;
  final double waterAmount;
  final double serviceAmount;

  InvoiceModel({
    required this.id,
    required this.roomName,
    required this.month,
    required this.amount,
    required this.dueDate,
    required this.status,
    required this.rentAmount,
    required this.electricAmount,
    required this.waterAmount,
    required this.serviceAmount,
  });
}

class MaintenanceTaskModel {
  final String id;
  final String roomName;
  final String title;
  final String description;
  final String priority; // 'high', 'medium', 'low'
  final String status; // 'pending', 'in_progress', 'completed'
  final String createdAt;
  final String? assignedTech;

  MaintenanceTaskModel({
    required this.id,
    required this.roomName,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.assignedTech,
  });
}

class TenantModel {
  final String id;
  final String name;
  final String phone;
  final String roomName;
  final String identityNumber;
  final String startDate;

  TenantModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.roomName,
    required this.identityNumber,
    required this.startDate,
  });
}

class NotificationItem {
  final String id;
  final String title;
  final String desc;
  final String time;
  final bool unread;

  NotificationItem({
    required this.id,
    required this.title,
    required this.desc,
    required this.time,
    this.unread = true,
  });
}
