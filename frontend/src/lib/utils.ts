import { type ClassValue, clsx } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat("vi-VN", {
    style: "currency",
    currency: "VND",
    maximumFractionDigits: 0
  }).format(amount);
}

export function formatDate(dateStr: string | Date): string {
  const date = new Date(dateStr);
  return new Intl.DateTimeFormat("vi-VN", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric"
  }).format(date);
}

export function formatVnStyle(value: string | number | undefined | null): string {
  if (value === undefined || value === null || value === "") return "";
  const numStr = typeof value === "number" ? String(value) : value.replace(/[^\d]/g, "");
  return numStr ? Number(numStr).toLocaleString("de-DE") : "";
}

export function stripVnStyle(value: string): string {
  return value.replace(/\./g, "");
}

/**
 * Extract a human-readable detail text from an activity/audit log `metadata` field.
 * Backend may store plain text or a JSON object such as {"value": "..."}.
 */
export function extractActivityDetail(metadata: unknown): string | null {
  if (metadata === null || metadata === undefined) return null;

  let value: unknown = metadata;
  if (typeof metadata === "string") {
    const trimmed = metadata.trim();
    if (!trimmed) return null;
    if (trimmed.startsWith("{") || trimmed.startsWith("[")) {
      try {
        value = JSON.parse(trimmed);
      } catch {
        return trimmed;
      }
    } else {
      return trimmed;
    }
  }

  if (value && typeof value === "object") {
    const obj = value as Record<string, unknown>;
    for (const key of ["value", "description", "details", "message", "note"]) {
      const candidate = obj[key];
      if (typeof candidate === "string" && candidate.trim()) return candidate.trim();
    }
    return null;
  }

  return typeof value === "string" && value.trim() ? value.trim() : null;
}
