import { useEffect } from "react";
import { useNotificationStore } from "@/store/notificationStore";
import { useNavigate } from "react-router-dom";
import { CheckCheck, ExternalLink, Inbox, Loader2 } from "lucide-react";
import { Button } from "@/components/ui/Button";

export function NotificationListPage() {
  const navigate = useNavigate();
  const {
    notifications,
    loading,
    unreadCount,
    fetchNotifications,
    markAllAsRead,
    markAsRead,
  } = useNotificationStore();

  useEffect(() => {
    fetchNotifications();
  }, [fetchNotifications]);

  const handleNotificationClick = async (id: number, actionUrl?: string) => {
    await markAsRead(id);
    if (actionUrl) {
      const invoiceMatch = actionUrl.match(/\/(resident|manager)\/invoices\/(\d+)/);
      if (invoiceMatch) {
        navigate(`/invoices?id=${invoiceMatch[2]}`);
      } else {
        navigate(actionUrl);
      }
    }
  };

  return (
    <div className="space-y-6 max-w-4xl mx-auto">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold font-display text-brand-ink">Thông báo của bạn</h1>
          <p className="text-sm text-slate-500 mt-1 font-medium">
            Bạn đang có {unreadCount} thông báo chưa đọc.
          </p>
        </div>
        {unreadCount > 0 && (
          <Button
            onClick={markAllAsRead}
            variant="outline"
            className="flex items-center gap-2 border-slate-200 text-slate-600 hover:text-slate-800"
          >
            <CheckCheck size={16} />
            Đánh dấu tất cả đã đọc
          </Button>
        )}
      </div>

      <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
        {loading ? (
          <div className="p-16 flex flex-col items-center justify-center space-y-3">
            <Loader2 className="animate-spin text-brand-deep" size={32} />
            <p className="text-sm text-slate-500 font-medium">Đang tải danh sách thông báo...</p>
          </div>
        ) : notifications.length === 0 ? (
          <div className="p-20 flex flex-col items-center text-center">
            <div className="bg-slate-50 p-4 rounded-full mb-3 border border-slate-100">
              <Inbox size={32} className="text-slate-400" />
            </div>
            <p className="text-slate-700 font-bold text-lg">Hộp thư trống</p>
            <p className="text-sm text-slate-400 mt-1 max-w-xs leading-relaxed">
              Bạn không có bất kỳ thông báo nào tại thời điểm này.
            </p>
          </div>
        ) : (
          <div className="divide-y divide-slate-100">
            {notifications.map((notif) => (
              <div
                key={notif.id}
                onClick={() => handleNotificationClick(notif.id, notif.actionUrl)}
                className={`flex items-start p-6 hover:bg-slate-50/50 transition-colors cursor-pointer text-left relative gap-4 ${
                  !notif.isRead ? "bg-brand-deep/[0.01]" : ""
                }`}
              >
                {!notif.isRead && (
                  <span className="mt-2 h-2.5 w-2.5 shrink-0 rounded-full bg-brand-deep" />
                )}
                <div className="flex-1 space-y-1">
                  <div className="flex flex-wrap items-center justify-between gap-2">
                    <span className="text-[11px] text-slate-400 font-medium">
                      {new Date(notif.createdAt).toLocaleDateString("vi-VN", {
                        hour: "2-digit",
                        minute: "2-digit",
                        day: "2-digit",
                        month: "2-digit",
                        year: "numeric",
                      })}
                    </span>
                    <span className="text-[9px] uppercase font-bold tracking-wider text-slate-500 bg-slate-100 px-2 py-0.5 rounded-md">
                      {notif.type}
                    </span>
                  </div>
                  <h3 className={`text-base font-bold text-slate-800 ${!notif.isRead ? "font-extrabold" : ""}`}>
                    {notif.title}
                  </h3>
                  <p className="text-sm text-slate-600 leading-relaxed">
                    {notif.content}
                  </p>
                  {notif.actionUrl && (
                    <div className="pt-1.5">
                      <span className="inline-flex items-center gap-1.5 text-xs font-semibold text-brand-deep hover:text-brand-ink">
                        <ExternalLink size={12} />
                        Đi tới liên kết hành động
                      </span>
                    </div>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
