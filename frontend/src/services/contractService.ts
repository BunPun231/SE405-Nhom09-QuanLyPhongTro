import { api } from "@/lib/api";
import type { ApiResponse, PageResponse } from "./motelService";

// ============ TYPES ============

export interface ContractResult {
  id: number;
  contractCode?: string;
  tenantId: string;
  roomId: number;
  primaryResidentUserId: string;
  startDate: string;
  endDate: string;
  /** Backend returns rentPrice (not monthlyRent) */
  rentPrice: number;
  depositAmount: number;
  depositStatus: "PENDING" | "UNPAID" | "HOLDING" | "PAID" | "REFUNDED" | "DEDUCTED";
  status: "ACTIVE" | "DRAFT" | "PENDING_LIQUIDATION" | "LIQUIDATED" | "CANCELLED" | "CANCELED";
  billingDate?: string;
  billingCycleDay?: number;
  paymentCycleMonths?: number;
  intendedMoveOutDate?: string;
  pdfUrl?: string;
  createdAt?: string;
  updatedAt?: string;
  notes?: string;
  residentUserIds?: string[];
}

export interface ContractAppendix {
  id: number;
  contractId: number;
  type: string;
  effectiveDate?: string;
  newEndDate?: string;
  newRentPrice?: number;
  intendedMoveOutDate?: string;
  metadata?: string;
  createdAt: string;
}

export interface ContractCreateRequest {
  roomId: number;
  /** Pass existing resident's userId */
  primaryResidentUserId?: string;
  /** Or pass phone to create a new resident inline */
  primaryResidentPhone?: string;
  primaryResidentFullName?: string;
  primaryResidentEmail?: string;
  primaryResidentIdCardNumber?: string;
  primaryResidentIdCardFrontUrl?: string;
  primaryResidentIdCardBackUrl?: string;
  startDate: string;
  endDate: string;
  /** billingDate: day of month when rent is due (optional) */
  billingDate?: string;
  billingCycleDay?: number;
  paymentCycleMonths?: number;
  rentPrice: number;
  depositAmount: number;
  /** UNPAID | PAID */
  depositStatus?: string;
  residentUserIds?: string[];
  serviceItems?: Array<{ serviceId: number; quantity?: number }>;
}

export interface ContractAdjustmentRequest {
  /** PRICE_CHANGE | RENEW | MOVE_OUT_NOTICE | MANUAL_CLAUSE */
  type: string;
  effectiveDate?: string;
  newRentPrice?: number;
  newEndDate?: string;
  intendedMoveOutDate?: string;
  metadata?: string;
}

export interface DepositDeductRequest {
  deductAmount: number;
  reason: string;
}

export interface DamageItemInput {
  itemName: string;
  penaltyFee: number;
  imageUrl?: string;
}

export interface SettlementRequest {
  contractId: number;
  moveOutDate: string;
  finalElectricReading?: number;
  finalWaterReading?: number;
  damages?: DamageItemInput[];
}

export interface SettlementCalculateResult {
  contractId: number;
  deposit: number;
  currentDebt: number;
  proRatedRent: number;
  finalUtilities: number;
  repairFees: number;
  netAmount: number;
  itemBreakdown: Array<{ description: string; amount: number }>;
}

export interface SettlementConfirmRequest {
  moveOutDate: string;
  finalElectricReading?: number;
  finalWaterReading?: number;
  damages?: DamageItemInput[];
}

// ============ CONTRACT APIs ============

export const contractService = {
  /** UC64: List contracts (all, by tenant) */
  async list(page = 0, size = 20): Promise<PageResponse<ContractResult>> {
    const res = await api.get<ApiResponse<PageResponse<ContractResult>>>("/api/contracts", {
      params: { page, size },
    });
    return res.data.data;
  },

  /** UC64: List contracts for a motel */
  async listByMotel(motelId: number, page = 0, size = 20, status?: string): Promise<PageResponse<ContractResult>> {
    const res = await api.get<ApiResponse<PageResponse<ContractResult>>>(
      `/api/contracts/motels/${motelId}`,
      { params: { page, size, status } }
    );
    return res.data.data;
  },

  /** UC64: List all active contracts */
  async listActive(): Promise<ContractResult[]> {
    const res = await api.get<ApiResponse<ContractResult[]>>("/api/contracts/active");
    return res.data.data;
  },

  /** UC65: Get contract detail */
  async get(contractId: number): Promise<ContractResult> {
    const res = await api.get<ApiResponse<ContractResult>>(`/api/contracts/${contractId}`);
    return res.data.data;
  },

  /** UC65: Get full contract detail (with residents & services) */
  async getDetail(contractId: number): Promise<ContractResult & { residentUserIds: string[]; serviceItems: unknown[]; appendicesCount: number }> {
    const res = await api.get<ApiResponse<ContractResult & { residentUserIds: string[]; serviceItems: unknown[]; appendicesCount: number }>>(`/api/contracts/${contractId}/detail`);
    return res.data.data;
  },

  /** UC63: Create contract */
  async create(data: ContractCreateRequest): Promise<ContractResult> {
    const res = await api.post<ApiResponse<ContractResult>>("/api/contracts", data);
    return res.data.data;
  },

  /** UC66: Add appendix (extension, rent change, notice) */
  async addAppendix(contractId: number, data: ContractAdjustmentRequest): Promise<ContractAppendix> {
    const res = await api.post<ApiResponse<ContractAppendix>>(
      `/api/contracts/${contractId}/adjustments`,
      data
    );
    return res.data.data;
  },

  /** UC67: Cancel contract (reason as query param) */
  async cancel(contractId: number, reason?: string): Promise<ContractResult> {
    const res = await api.post<ApiResponse<ContractResult>>(
      `/api/contracts/${contractId}/cancel`,
      null,
      { params: reason ? { reason } : {} }
    );
    return res.data.data;
  },

  /** UC69: Collect deposit (mark as PAID, no body needed) */
  async collectDeposit(contractId: number): Promise<ContractResult> {
    const res = await api.post<ApiResponse<ContractResult>>(
      `/api/contracts/${contractId}/deposit/collect`
    );
    return res.data.data;
  },

  /** UC69: Deduct from deposit */
  async deductDeposit(contractId: number, data: DepositDeductRequest): Promise<void> {
    await api.post(`/api/contracts/${contractId}/deposit/deduct`, data);
  },

  /** UC69: Refund deposit */
  async refundDeposit(contractId: number, notes?: string): Promise<void> {
    await api.post(`/api/contracts/${contractId}/deposit/refund`, { notes });
  },

  async calculateSettlement(data: SettlementRequest): Promise<SettlementCalculateResult> {
    const res = await api.post<SettlementCalculateResult>(
      "/api/v1/settlements/calculate",
      data
    );
    return res.data;
  },

  /** UC80: Confirm settlement */
  async confirmSettlement(contractId: number, data: SettlementConfirmRequest): Promise<void> {
    await api.post(`/api/v1/settlements/${contractId}/confirm`, data);
  },

  /** UC68: Export PDF */
  async exportPdf(contractId: number): Promise<Blob> {
    const res = await api.get(`/api/contracts/${contractId}/pdf`, { responseType: "blob" });
    return res.data;
  },

  /** List contracts for a resident */
  async listByResident(residentUserId: string): Promise<ContractResult[]> {
    const res = await api.get<ApiResponse<ContractResult[]>>(`/api/contracts/resident/${residentUserId}`);
    return res.data.data;
  },
};
