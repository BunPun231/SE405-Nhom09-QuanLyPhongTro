import '../network/api_client.dart';
import 'motel_service.dart';

// ─── Types (mirror reportService.ts) ───────────────────────────────────────

typedef DashboardSummaryModel = DashboardSummaryResult;
typedef ReportApiService = ReportService;

class DashboardSummaryResult {
  final int totalRooms;
  final int rentedRooms;
  final int availableRooms;
  final double occupancyRate;
  final double expectedRevenue;
  final double collectedRevenue;
  final double pendingDebt;
  final int expiringContractsCount;
  final int activeContractsCount;
  final int unpaidInvoicesCount;
  final int pendingMeterReadingsCount;
  final List<RecentActivity> recentActivities;
  final List<RecentInvoice> recentInvoices;

  DashboardSummaryResult({
    required this.totalRooms,
    required this.rentedRooms,
    required this.availableRooms,
    required this.occupancyRate,
    required this.expectedRevenue,
    required this.collectedRevenue,
    required this.pendingDebt,
    required this.expiringContractsCount,
    required this.activeContractsCount,
    required this.unpaidInvoicesCount,
    required this.pendingMeterReadingsCount,
    required this.recentActivities,
    required this.recentInvoices,
  });

  factory DashboardSummaryResult.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryResult(
      totalRooms: json['totalRooms'] ?? 0,
      rentedRooms: json['rentedRooms'] ?? 0,
      availableRooms: json['availableRooms'] ?? 0,
      occupancyRate: (json['occupancyRate'] as num?)?.toDouble() ?? 0,
      expectedRevenue: (json['expectedRevenue'] as num?)?.toDouble() ?? 0,
      collectedRevenue: (json['collectedRevenue'] as num?)?.toDouble() ?? 0,
      pendingDebt: (json['pendingDebt'] as num?)?.toDouble() ?? 0,
      expiringContractsCount: json['expiringContractsCount'] ?? 0,
      activeContractsCount: json['activeContractsCount'] ?? 0,
      unpaidInvoicesCount: json['unpaidInvoicesCount'] ?? 0,
      pendingMeterReadingsCount: json['pendingMeterReadingsCount'] ?? 0,
      recentActivities: (json['recentActivities'] as List<dynamic>? ?? []).map((e) => RecentActivity.fromJson(e as Map<String, dynamic>)).toList(),
      recentInvoices: (json['recentInvoices'] as List<dynamic>? ?? []).map((e) => RecentInvoice.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class RecentActivity {
  final String action;
  final String? entityType;
  final String description;
  final String createdAt;

  RecentActivity({
    required this.action,
    this.entityType,
    required this.description,
    required this.createdAt,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      action: json['action'] ?? '',
      entityType: json['entityType'],
      description: json['description'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class RecentInvoice {
  final int invoiceId;
  final String? roomNumber;
  final String? residentName;
  final double amount;
  final String status;
  final String billingMonth;

  RecentInvoice({
    required this.invoiceId,
    this.roomNumber,
    this.residentName,
    required this.amount,
    required this.status,
    required this.billingMonth,
  });

  factory RecentInvoice.fromJson(Map<String, dynamic> json) {
    return RecentInvoice(
      invoiceId: json['invoiceId'] ?? 0,
      roomNumber: json['roomNumber'],
      residentName: json['residentName'],
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: json['status'] ?? '',
      billingMonth: json['billingMonth'] ?? '',
    );
  }
}

class AuditLogResult {
  final int id;
  final String actorId;
  final String actorRole;
  final String action;
  final String? entityType;
  final String? entityId;
  final String? oldValue;
  final String? newValue;
  final String? ipAddress;
  final String timestamp;

  AuditLogResult({
    required this.id,
    required this.actorId,
    required this.actorRole,
    required this.action,
    this.entityType,
    this.entityId,
    this.oldValue,
    this.newValue,
    this.ipAddress,
    required this.timestamp,
  });

  factory AuditLogResult.fromJson(Map<String, dynamic> json) {
    return AuditLogResult(
      id: json['id'] ?? 0,
      actorId: json['actorId'] ?? '',
      actorRole: json['actorRole'] ?? '',
      action: json['action'] ?? '',
      entityType: json['entityType'],
      entityId: json['entityId'],
      oldValue: json['oldValue'],
      newValue: json['newValue'],
      ipAddress: json['ipAddress'],
      timestamp: json['timestamp'] ?? '',
    );
  }
}

// ─── ReportService (mirror reportService.ts) ──────────────────────────────

class ReportService {
  /// UC94: Dashboard summary — GET /api/v1/reports/dashboard-summary
  static Future<DashboardSummaryResult?> getDashboardSummary() async {
    final data = await ApiClient.get('/api/v1/reports/dashboard-summary');
    if (data == null) return null;
    return DashboardSummaryResult.fromJson(data as Map<String, dynamic>);
  }

  /// UC90: Revenue report — GET /api/v1/reports/revenue
  static Future<Map<String, dynamic>?> getRevenue(int motelId, int year) async {
    final data = await ApiClient.get('/api/v1/reports/revenue', params: {'motelId': motelId, 'year': year});
    return data as Map<String, dynamic>?;
  }

  /// UC91: Occupancy report — GET /api/v1/reports/occupancy
  static Future<Map<String, dynamic>?> getOccupancy(int motelId) async {
    final data = await ApiClient.get('/api/v1/reports/occupancy', params: {'motelId': motelId});
    return data as Map<String, dynamic>?;
  }

  /// UC92: Debt report — GET /api/v1/reports/debt
  static Future<Map<String, dynamic>?> getDebt(int motelId, {String sort = 'days'}) async {
    final data = await ApiClient.get('/api/v1/reports/debt', params: {'motelId': motelId, 'sort': sort});
    return data as Map<String, dynamic>?;
  }
}

// ─── AuditService (mirror auditService.ts) ────────────────────────────────

class AuditService {
  /// UC13: Get audit logs — GET /api/v1/audit-logs
  static Future<PageResponse<AuditLogResult>> list({int page = 0, int size = 20}) async {
    final data = await ApiClient.get('/api/v1/audit-logs', params: {'page': page, 'size': size});
    return PageResponse.fromJson(data as Map<String, dynamic>, AuditLogResult.fromJson);
  }

  /// UC14: Get activity logs (Manager) — GET /api/v1/activity-logs
  static Future<PageResponse<AuditLogResult>> listActivity({int page = 0, int size = 20}) async {
    final data = await ApiClient.get('/api/v1/activity-logs', params: {'page': page, 'size': size});
    return PageResponse.fromJson(data as Map<String, dynamic>, AuditLogResult.fromJson);
  }
}
