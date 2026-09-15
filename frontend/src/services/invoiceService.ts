import { api } from "@/lib/api";
import type { ApiResponse, PageResponse } from "./motelService";

// ============ TYPES ============

export interface InvoiceResult {
  id: number;
  tenantId: string;
  contractId: number;
  roomId: number;
  roomNumber?: string;
  billingMonth: string;
  totalAmount: number;
  paidAmount: number;
  balanceDeduction: number;
  status: "PENDING" | "PARTIAL" | "PAID" | "VOID";
  invoiceType: string;
  cancelReason?: string;
  dueDate?: string;
  calculationSnapshot?: string;
  details?: InvoiceDetail[];
}

export interface InvoiceDetail {
  id: number;
  serviceId: number;
  serviceName: string;
  chargeType: string;
  oldReading?: number;
  newReading?: number;
  consumption?: number;
  unitPrice: number;
  totalCost: number;
}

export interface InvoiceGenerationResult {
  generatedCount: number;
  invoiceIds: number[];
  billingMonth: string;
  motelId: number;
}

export interface InvoiceGenerateRequest {
  motelId: number;
  billingMonth: string; // Format: "YYYY-MM" → mapped to LocalDate
}

export interface MeterReadingResult {
  id: number;
  tenantId: string;
  roomId: number;
  serviceId: number;
  serviceName: string;
  serviceUsageId: number;
  billingMonth: string;
  oldReading: number;
  newReading?: number;
  consumption?: number;
  status: "PENDING" | "SUBMITTED" | "APPROVED" | "REJECTED";
  imageUrl?: string;
  ocrReading?: number;
}

export interface MeterReadingSubmitRequest {
  roomId: number;
  serviceId: number;
  billingMonth: string;
  newReading: number;
  readingImageUrl?: string;
}

export interface PaymentRequest {
  invoiceId: number;
  amount: number;
  paymentMethod: string;
}

export interface InvoiceAdjustRequest {
  reason: string;
  correctedReadings?: Record<number, number>;
  customAdjustments?: Record<number, number>;
}

// ============ INVOICE APIs ============

export const invoiceService = {
  /** UC73: Generate invoices for a motel */
  async generate(data: InvoiceGenerateRequest): Promise<InvoiceGenerationResult> {
    const billingMonth = data.billingMonth.includes('T') ? data.billingMonth.slice(0, 7) + '-01' : data.billingMonth.endsWith('-01') ? data.billingMonth : data.billingMonth + '-01';
    const res = await api.post<{ invoices: unknown[]; skippedRooms: unknown[] }>("/api/v1/invoices/generate", {
      motelId: data.motelId,
      billingMonth,
    });
    // Backend returns {invoices, skippedRooms} - map to our type
    return {
      generatedCount: (res.data.invoices || []).length,
      invoiceIds: [],
      billingMonth: data.billingMonth,
      motelId: data.motelId,
    };
  },

  /** UC74: List invoices (backend returns raw PageResponse) */
  async list(motelId?: number, status?: string, page = 0, size = 50): Promise<PageResponse<InvoiceResult>> {
    const res = await api.get<PageResponse<InvoiceResult>>("/api/v1/invoices", {
      params: { motelId, status, page, size },
    });
    return res.data;
  },

  /** UC74 (Resident): List my invoices */
  async listMine(status?: string, page = 0, size = 20): Promise<PageResponse<InvoiceResult>> {
    const res = await api.get<PageResponse<InvoiceResult>>("/api/v1/invoices/me", {
      params: { status, page, size },
    });
    return res.data;
  },

  /** UC75: Get invoice details (backend returns raw InvoiceResult) */
  async get(invoiceId: number): Promise<InvoiceResult> {
    const res = await api.get<InvoiceResult>(`/api/v1/invoices/${invoiceId}`);
    return res.data;
  },

  /** UC76: Adjust invoice */
  async adjust(invoiceId: number, data: InvoiceAdjustRequest): Promise<InvoiceResult> {
    const res = await api.post<InvoiceResult>(`/api/v1/invoices/${invoiceId}/adjust`, data);
    return res.data;
  },

  /** UC77: Delete (void) invoice */
  async delete(invoiceId: number): Promise<void> {
    await api.delete(`/api/v1/invoices/${invoiceId}`);
  },

  /** Get my current credit balance */
  async getMyBalance(): Promise<number> {
    const res = await api.get<number>("/api/v1/invoices/my-balance");
    return res.data;
  },

  /** Get any resident's credit balance (Manager/Admin) */
  async getResidentBalance(residentId: string): Promise<number> {
    const res = await api.get<number>(`/api/v1/invoices/balance/${residentId}`);
    return res.data;
  },

  /** Get multiple residents' credit balances (Manager/Admin) */
  async getResidentBalances(residentIds: string[]): Promise<Record<string, number>> {
    const res = await api.get<Record<string, number>>("/api/v1/invoices/balances", {
      params: { residentIds: residentIds.join(",") },
    });
    return res.data;
  },

  /** Activate automatic payments using SePay */
  async activateAutomaticPayment(motelId: number, data: { sePayApiKey: string; accountNumber: string; bankName: string }): Promise<void> {
    await api.post(`/api/v1/invoices/payment-config/${motelId}`, data);
  },
};

// ============ METER READING APIs ============

export const meterReadingService = {
  /** List meter readings (UC72) - backend returns raw PageResponse */
  async list(roomId?: number, status?: string, page = 0, size = 100): Promise<PageResponse<MeterReadingResult>> {
    const res = await api.get<PageResponse<MeterReadingResult>>("/api/v1/meter-readings", {
      params: { roomId, status, page, size },
    });
    return res.data;
  },

  /** UC70: Submit meter reading */
  async submit(data: MeterReadingSubmitRequest): Promise<MeterReadingResult> {
    const res = await api.post<MeterReadingResult>("/api/v1/meter-readings", data);
    return res.data;
  },

  /** UC71: Extract reading using OCR and submit */
  async submitWithOcr(data: {
    roomId: number;
    serviceId: number;
    billingMonth: string;
    base64Image: string;
    mimeType: string;
  }): Promise<MeterReadingResult> {
    const res = await api.post<MeterReadingResult>("/api/v1/meter-readings/ocr", data);
    return res.data;
  },

  /** UC72: Get reading history for a room */
  async getHistory(roomId: number): Promise<MeterReadingResult[]> {
    const res = await api.get<MeterReadingResult[]>(`/api/v1/meter-readings/rooms/${roomId}/history`);
    return res.data;
  },

  /** UC70: Approve meter reading */
  async approve(readingId: number): Promise<MeterReadingResult> {
    const res = await api.post<MeterReadingResult>(`/api/v1/meter-readings/${readingId}/approve`);
    return res.data;
  },

  /** UC70: Reject meter reading */
  async reject(readingId: number, reason?: string): Promise<MeterReadingResult> {
    const res = await api.post<MeterReadingResult>(
      `/api/v1/meter-readings/${readingId}/reject`,
      null,
      { params: { reason } }
    );
    return res.data;
  },

  /** UC70: Bulk approve meter readings */
  async bulkApprove(ids: number[]): Promise<MeterReadingResult[]> {
    const res = await api.post<MeterReadingResult[]>("/api/v1/meter-readings/bulk-approve", ids);
    return res.data;
  },
};

// ============ PAYMENT APIs ============

export const paymentService = {
  /** UC78: Process manual payment for invoice */
  async pay(data: PaymentRequest): Promise<void> {
    await api.post(`/api/v1/payments/manual`, data);
  },
};
