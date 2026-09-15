import { useState, useEffect, useRef } from "react";
import { Bell, CheckCheck, ExternalLink, Inbox } from "lucide-react";
import { useNotificationStore } from "@/store/notificationStore";
import { useNavigate } from "react-router-dom";

export function NotificationBell() {
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);
  const navigate = useNavigate();

  const {
    notifications,
    unreadCount,
    fetchNotifications,
    markAllAsRead,
    markAsRead,
  } = useNotificationStore();

  useEffect(() => {
    fetchNotifications();
  }, [fetchNotifications]);

  // Click outside to close dropdown
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const handleNotificationClick = async (id: number, actionUrl?: string) => {
    await markAsRead(id);
    setIsOpen(false);
    if (actionUrl) {
      const invoiceMatch = actionUrl.match(/\/(resident|manager)\/invoices\/(\d+)/);
      if (invoiceMatch) {
        navigate(`/invoices?id=${invoiceMatch[2]}`);
      } else {
        navigate(actionUrl);
      }
    }
  };

  const handleMarkAllRead = (e: React.MouseEvent) => {
    e.stopPropagation();
    markAllAsRead();
  };

  return (
    <div className="relative" ref={dropdownRef}>
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="relative p-2 text-slate-500 hover:text-brand-deep rounded-full hover:bg-slate-100 transition-all active:scale-95"
        aria-label="Thông báo"
      >
        <Bell size={20} className="hover:rotate-12 transition-transform duration-200" />
        {unreadCount > 0 && (
          <span className="absolute top-1 right-1 flex h-4.5 min-w-4.5 items-center justify-center rounded-full bg-rose-500 px-1.5 text-[9px] font-extrabold text-white animate-pulse">
            {unreadCount > 99 ? "99+" : unreadCount}
          </span>
        )}
      </button>

      {isOpen && (
        <div className="absolute right-0 mt-2.5 w-80 sm:w-96 origin-top-right rounded-2xl border border-slate-100 bg-white shadow-xl ring-1 ring-black/5 z-50 animate-in fade-in slide-in-from-top-3 duration-200">
          <div className="flex items-center justify-between border-b border-slate-100 p-4">
            <h3 className="font-bold text-slate-800 font-display">Thông báo</h3>
            {unreadCount > 0 && (
              <button
                onClick={handleMarkAllRead}
                className="flex items-center text-xs font-semibold text-brand-deep hover:text-brand-ink transition-colors gap-1 bg-none border-none cursor-pointer"
              >
                <CheckCheck size={14} />
                Đọc tất cả
              </button>
            )}
          </div>

          <div className="max-h-80 overflow-y-auto divide-y divide-slate-50">
            {notifications.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-10 text-center">
                <div className="bg-slate-50 p-3 rounded-full mb-2">
                  <Inbox size={24} className="text-slate-400" />
                </div>
                <p className="text-sm font-semibold text-slate-500">Bạn không có thông báo nào</p>
                <p className="text-xs text-slate-400 mt-0.5">Chúng tôi sẽ báo cho bạn khi có tin mới</p>
              </div>
            ) : (
              notifications.slice(0, 5).map((notif) => (
                <div
                  key={notif.id}
                  onClick={() => handleNotificationClick(notif.id, notif.actionUrl)}
                  className={`flex flex-col p-4 hover:bg-slate-50/70 transition-colors cursor-pointer text-left relative ${!notif.isRead ? "bg-brand-deep/[0.02] font-medium" : ""
                    }`}
                >
                  {!notif.isRead && (
                    <span className="absolute top-4 right-4 h-2 w-2 rounded-full bg-brand-deep" />
                  )}
                  <span className="text-[10px] text-slate-400 mb-1">
                    {new Date(notif.createdAt).toLocaleDateString("vi-VN", {
                      hour: "2-digit",
                      minute: "2-digit",
                      day: "2-digit",
                      month: "2-digit",
                    })}
                  </span>
                  <h4 className="text-sm font-bold text-slate-800 leading-snug">{notif.title}</h4>
                  <p className="text-xs text-slate-500 mt-1 line-clamp-2 leading-relaxed">{notif.content}</p>

                  {notif.actionUrl && (
                    <span className="flex items-center gap-1 text-[10px] font-semibold text-brand-deep mt-2">
                      <ExternalLink size={10} />
                      Chi tiết
                    </span>
                  )}
                </div>
              ))
            )}
          </div>

          <div className="border-t border-slate-100 p-3 text-center">
            <button
              onClick={() => {
                setIsOpen(false);
                navigate("/notifications");
              }}
              className="text-xs font-bold text-brand-deep hover:text-brand-ink transition-colors block w-full py-1 bg-none border-none cursor-pointer"
            >
              Xem tất cả thông báo
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
