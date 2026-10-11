import { api } from "@/lib/api";

export interface DeviceResponse {
  id: number;
  motelId: number;
  name: string;
  brand?: string;
  purchasePrice?: number;
  purchaseDate?: string;
  totalQuantity: number;
  inUseQuantity: number;
  availableQuantity: number;
  status: "IN_STOCK" | "IN_USE" | "BROKEN" | "REPAIRING";
}

export interface DeviceUsageResponse {
  id: number;
  deviceId: number;
  deviceName: string;
  brand?: string;
  roomId: number;
  assignedQuantity: number;
  condition: string;
  assignedAt: string;
  updatedAt?: string;
}

export interface DeviceMovementLogResponse {
  id: number;
  deviceId: number;
  fromRoomId?: number;
  toRoomId?: number;
  action: "ASSIGN" | "RECALL";
  changedBy: string;
  timestamp: string;
  note?: string;
}

export interface CreateDeviceRequest {
  name: string;
  brand?: string;
  purchasePrice?: number;
  purchaseDate?: string;
  totalQuantity?: number;
}

export interface UpdateDeviceRequest {
  name?: string;
  brand?: string;
  purchasePrice?: number;
  purchaseDate?: string;
  status?: string;
  totalQuantity?: number;
}

export interface AssignDeviceRequest {
  roomId: number;
  assignedQuantity?: number;
  condition?: string;
  note?: string;
}

export interface PageResponse<T> {
  content: T[];
  pageNumber: number;
  pageSize: number;
  totalElements: number;
  totalPages: number;
  last: boolean;
}

export const deviceService = {
  /** UC40 - Create device */
  async createDevice(motelId: number, body: CreateDeviceRequest): Promise<DeviceResponse> {
    const res = await api.post<{ data: DeviceResponse }>(`/api/motels/${motelId}/devices`, body);
    return res.data.data;
  },

  /** UC41 - List devices */
  async getDevices(motelId: number, params?: { page?: number; size?: number }): Promise<PageResponse<DeviceResponse>> {
    const res = await api.get<{ data: PageResponse<DeviceResponse> }>(`/api/motels/${motelId}/devices`, { params });
    return res.data.data;
  },

  /** UC42 - Get device detail */
  async getDevice(motelId: number, deviceId: number): Promise<DeviceResponse> {
    const res = await api.get<{ data: DeviceResponse }>(`/api/motels/${motelId}/devices/${deviceId}`);
    return res.data.data;
  },

  /** UC44 - Update device */
  async updateDevice(motelId: number, deviceId: number, body: UpdateDeviceRequest): Promise<DeviceResponse> {
    const res = await api.patch<{ data: DeviceResponse }>(`/api/motels/${motelId}/devices/${deviceId}`, body);
    return res.data.data;
  },

  /** UC45 - Delete device */
  async deleteDevice(motelId: number, deviceId: number): Promise<void> {
    await api.delete(`/api/motels/${motelId}/devices/${deviceId}`);
  },

  /** UC43 - Get devices by room */
  async getDevicesByRoom(motelId: number, roomId: number): Promise<DeviceUsageResponse[]> {
    const res = await api.get<{ data: DeviceUsageResponse[] }>(`/api/motels/${motelId}/rooms/${roomId}/devices`);
    return res.data.data;
  },

  /** UC46 - Assign device to room */
  async assignDevice(motelId: number, deviceId: number, body: AssignDeviceRequest): Promise<DeviceUsageResponse> {
    const res = await api.post<{ data: DeviceUsageResponse }>(`/api/motels/${motelId}/devices/${deviceId}/assign`, body);
    return res.data.data;
  },

  /** UC47 - Recall device from room */
  async recallDevice(motelId: number, deviceId: number, roomId: number, note?: string): Promise<void> {
    await api.post(`/api/motels/${motelId}/devices/${deviceId}/recall`, { note }, { params: { roomId } });
  },

  /** Get movement history */
  async getMovementLogs(motelId: number, deviceId: number): Promise<DeviceMovementLogResponse[]> {
    const res = await api.get<{ data: DeviceMovementLogResponse[] }>(`/api/motels/${motelId}/devices/${deviceId}/movement-logs`);
    return res.data.data;
  }
};
