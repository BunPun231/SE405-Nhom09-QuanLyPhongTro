import { AlertTriangle } from "lucide-react";

interface ValidationErrorTooltipProps {
  message: string;
}

export function ValidationErrorTooltip({ message }: ValidationErrorTooltipProps) {
  if (!message) return null;

  return (
    <div className="relative inline-flex items-center group cursor-pointer select-none">
      <AlertTriangle className="h-5 w-5 text-amber-500 animate-pulse hover:text-amber-600 transition-colors" />
      <div className="absolute bottom-full right-0 mb-2 hidden group-hover:block z-50 w-56 bg-slate-900/95 backdrop-blur-sm text-white text-xs rounded-xl p-3 shadow-xl border border-slate-800 transition-all duration-200">
        <div className="relative">
          <p className="font-medium text-slate-100">{message}</p>
          <div className="absolute top-full right-3 border-4 border-transparent border-t-slate-900/95 content-['']" />
        </div>
      </div>
    </div>
  );
}
