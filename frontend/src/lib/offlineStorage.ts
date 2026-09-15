const OFFLINE_KEY = "room-rental-offline-queue";

export function saveOfflineQueue(payload: unknown[]) {
  localStorage.setItem(OFFLINE_KEY, JSON.stringify(payload));
}

export function loadOfflineQueue(): unknown[] {
  const raw = localStorage.getItem(OFFLINE_KEY);
  return raw ? (JSON.parse(raw) as unknown[]) : [];
}
