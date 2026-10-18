import { api } from "@/lib/api";
import { PageResponse } from "./adminService";

export interface UsedDeviceItem {
  deviceId: number;
  quantityUsed: number;
  unitPrice?: number;
}

export interface MaintenanceDetailResponse {
  id: number;
  ticketId: number;
  deviceId: number;
  deviceName: string;
  quantityUsed: number;
  unitPriceSnapshot: number;
  afterImages: string[];
  note?: string;
}

export interface MaintenanceTicketResponse {
  id: number;
  motelId?: number;
  roomId: number;
  roomNumber: string;
  reportedBy: string;
  reporterName: string;
  assignedTo?: string;
  technicianName?: string;
  category: string;
  description: string;
  beforeImages: string[];
  status: "OPEN" | "PROCESSING" | "COMPLETED" | "ESCALATED" | "CANCELLED";
  priority: "LOW" | "MEDIUM" | "HIGH" | "URGENT";
  details: MaintenanceDetailResponse[];
  createdAt: string;
  updatedAt?: string;
  completedAt?: string;
}

export interface CreateTicketRequestData {
  roomId: number;
  category?: string;
  description: string;
  priority?: string;
}

export interface CompleteTicketRequestData {
  usedDevices?: UsedDeviceItem[];
  note?: string;
}

export const maintenanceService = {
  /** UC70 - Create maintenance ticket with MultipartFiles sent to Spring Boot Backend */
  async createTicket(data: CreateTicketRequestData, files?: File[]): Promise<MaintenanceTicketResponse> {
    const formData = new FormData();
    formData.append("roomId", String(data.roomId));
    if (data.category) formData.append("category", data.category);
    formData.append("description", data.description);
    if (data.priority) formData.append("priority", data.priority);

    if (files && files.length > 0) {
      files.forEach((file) => formData.append("files", file));
    }

    const res = await api.post<{ data: MaintenanceTicketResponse }>("/api/maintenance/tickets", formData, {
      headers: { "Content-Type": "multipart/form-data" },
    });
    return res.data.data;
  },

  /** Get ticket detail */
  async getTicketDetail(ticketId: number): Promise<MaintenanceTicketResponse> {
    const res = await api.get<{ data: MaintenanceTicketResponse }>(`/api/maintenance/tickets/${ticketId}`);
    return res.data.data;
  },

  /** UC72 - Assign technician */
  async assignTechnician(ticketId: number, technicianId: string): Promise<MaintenanceTicketResponse> {
    const res = await api.post<{ data: MaintenanceTicketResponse }>(`/api/maintenance/tickets/${ticketId}/assign`, {
      technicianId,
    });
    return res.data.data;
  },

  /** UC74 - Complete ticket with after images uploaded via Spring Boot Backend */
  async completeTicket(ticketId: number, data?: CompleteTicketRequestData, files?: File[]): Promise<MaintenanceTicketResponse> {
    const formData = new FormData();
    if (data?.note) {
      formData.append("note", data.note);
    }
    if (data?.usedDevices && data.usedDevices.length > 0) {
      formData.append("usedDeviceId", String(data.usedDevices[0].deviceId));
      formData.append("usedQuantity", String(data.usedDevices[0].quantityUsed));
    }

    if (files && files.length > 0) {
      files.forEach((file) => formData.append("files", file));
    }

    const res = await api.post<{ data: MaintenanceTicketResponse }>(`/api/maintenance/tickets/${ticketId}/complete`, formData, {
      headers: { "Content-Type": "multipart/form-data" },
    });
    return res.data.data;
  },

  /** List tickets for Manager */
  async getMotelTickets(motelId: number, params?: { page?: number; size?: number }): Promise<PageResponse<MaintenanceTicketResponse>> {
    const res = await api.get<{ data: PageResponse<MaintenanceTicketResponse> }>(`/api/maintenance/motels/${motelId}/tickets`, { params });
    return res.data.data;
  },

  /** List assigned tasks for Technician */
  async getMyTasks(params?: { page?: number; size?: number }): Promise<PageResponse<MaintenanceTicketResponse>> {
    const res = await api.get<{ data: PageResponse<MaintenanceTicketResponse> }>("/api/maintenance/my-tasks", { params });
    return res.data.data;
  },

  /** List reported tickets for Tenant */
  async getMyTickets(params?: { page?: number; size?: number }): Promise<PageResponse<MaintenanceTicketResponse>> {
    const res = await api.get<{ data: PageResponse<MaintenanceTicketResponse> }>("/api/maintenance/my-tickets", { params });
    return res.data.data;
  }
};
