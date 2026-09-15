import React from "react";
import { cn } from "@/lib/utils";

interface BadgeProps extends React.HTMLAttributes<HTMLDivElement> {
  variant?: "success" | "warning" | "danger" | "default" | "brand";
}

export function Badge({ className, variant = "default", ...props }: BadgeProps) {
  const variants = {
    success: "bg-green-100 text-green-700",
    warning: "bg-yellow-100 text-yellow-700",
    danger: "bg-red-100 text-red-700",
    default: "bg-slate-100 text-slate-700",
    brand: "bg-brand-deep/10 text-brand-deep"
  };

  return (
    <div
      className={cn(
        "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium w-fit",
        variants[variant],
        className
      )}
      {...props}
    />
  );
}
