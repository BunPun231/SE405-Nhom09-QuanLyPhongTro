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
