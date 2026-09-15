import { api } from "@/lib/api";
import type { ApiResponse, PageResponse } from "./motelService";

// ============ TYPES ============

export interface RevenueReportResult {
  year: number;
  month?: number;
  motelId: number;
  totalProjected: number;
  totalActual: number;
  collectionRate: number;
  monthly: MonthlyRevenue[];
}

export interface MonthlyRevenue {
  month: number;
  projected: number;
  actual: number;
}

export interface OccupancyReportResult {
  motelId: number;
  motelName: string;
  totalRooms: number;
  rentedRooms: number;
  depositedRooms: number;
  availableRooms: number;
  repairingRooms: number;
  occupancyRate: number;
  emptyRooms: RoomSummary[];
}

export interface RoomSummary {
  roomId: number;
  roomNumber: string;
  floor: string;
  basePrice: number;
  status: string;
  lastVacantSince?: string;
}

export interface DebtReportResult {
  motelId: number;
  totalDebt: number;
  debtorCount: number;
  entries: DebtEntry[];
}

export interface DebtEntry {
  invoiceId: number;
  roomId: number;
  roomNumber: string;
  residentName?: string;
  residentPhone?: string;
  billingMonth: string;
  totalAmount: number;
  paidAmount: number;
  debtAmount: number;
  dueDate: string;
  daysOverdue: number;
  agingBucket: "NEW" | "OVERDUE" | "BAD_DEBT";
}

export interface DashboardSummaryResult {
  totalRooms: number;
  rentedRooms: number;
  availableRooms: number;
  occupancyRate: number;
  expectedRevenue: number;
  collectedRevenue: number;
  pendingDebt: number;
  expiringContractsCount: number;
  activeContractsCount: number;
  unpaidInvoicesCount: number;
  pendingMeterReadingsCount: number;
  recentActivities: RecentActivity[];
  recentInvoices: RecentInvoice[];
}

export interface RecentActivity {
  action: string;
  entityType?: string;
  description: string;
  createdAt: string;
}

export interface RecentInvoice {
  invoiceId: number;
  roomNumber?: string;
  residentName?: string;
  amount: number;
  status: string;
  billingMonth: string;
}

export interface AuditLogResult {
  id: number;
  actorId: string;
  actorRole: string;
  action: string;
  entityType?: string;
  entityId?: string;
  oldValue?: string;
  newValue?: string;
  ipAddress?: string;
  timestamp: string;
  metadata?: unknown;
}

// ============ REPORT APIs ============

export const reportService = {
  /** UC90: Revenue report */
  async getRevenue(motelId: number, year: number): Promise<RevenueReportResult> {
    const res = await api.get<ApiResponse<RevenueReportResult>>("/api/v1/reports/revenue", {
      params: { motelId, year },
    });
    return res.data.data;
  },

  /** UC91: Occupancy report */
  async getOccupancy(motelId: number): Promise<OccupancyReportResult> {
    const res = await api.get<ApiResponse<OccupancyReportResult>>("/api/v1/reports/occupancy", {
      params: { motelId },
    });
    return res.data.data;
  },

  /** UC92: Debt report */
  async getDebt(motelId: number, sort = "days"): Promise<DebtReportResult> {
    const res = await api.get<ApiResponse<DebtReportResult>>("/api/v1/reports/debt", {
      params: { motelId, sort },
    });
    return res.data.data;
  },

  /** UC94: Dashboard summary */
  async getDashboardSummary(): Promise<DashboardSummaryResult> {
    const res = await api.get<ApiResponse<DashboardSummaryResult>>(
      "/api/v1/reports/dashboard-summary"
    );
    return res.data.data;
  },
};

// ============ AUDIT LOG API ============

export const auditService = {
  /** UC13: Get audit logs */
  async list(
    page = 0,
    size = 20,
    filters?: {
      action?: string;
      entityType?: string;
      fromDate?: string;
      toDate?: string;
    }
  ): Promise<PageResponse<AuditLogResult>> {
    const res = await api.get<ApiResponse<PageResponse<AuditLogResult>>>("/api/v1/audit-logs", {
      params: { page, size, ...filters },
    });
    return res.data.data;
  },
};

export const activityService = {
  /** UC14: Get activity logs for manager */
  async list(
    page = 0,
    size = 20,
    filters?: {
      action?: string;
      entityType?: string;
      fromDate?: string;
      toDate?: string;
    }
  ): Promise<PageResponse<AuditLogResult>> {
    const res = await api.get<ApiResponse<PageResponse<AuditLogResult>>>("/api/v1/activity-logs", {
      params: { page, size, ...filters },
    });
    return res.data.data;
  },
};
