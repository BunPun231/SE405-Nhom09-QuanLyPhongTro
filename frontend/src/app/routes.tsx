import { createBrowserRouter, Navigate } from "react-router-dom";
import { MainLayout } from "@/components/layout/MainLayout";
import { SuperAdminLayout } from "@/components/layout/SuperAdminLayout";
import { LoginPage } from "@/features/auth/pages/LoginPage";
import { RegisterPage } from "@/features/auth/pages/RegisterPage";
import { ForgotPasswordPage } from "@/features/auth/pages/ForgotPasswordPage";
import { DashboardPage } from "@/features/dashboard/pages/DashboardPage";
import { MotelListPage } from "@/features/motels/pages/MotelListPage";
import { ServiceListPage } from "@/features/services/pages/ServiceListPage";
import { ResidentListPage } from "@/features/residents/pages/ResidentListPage";
import { ContractListPage } from "@/features/contracts/pages/ContractListPage";
import { MeterReadingPage } from "@/features/meter/pages/MeterReadingPage";
import { InvoiceListPage } from "@/features/invoices/pages/InvoiceListPage";
import { ReportPage } from "@/features/reports/pages/ReportPage";
import { AuditLogPage } from "@/features/reports/pages/AuditLogPage";
import { SettingsPage } from "@/features/settings/pages/SettingsPage";
import { NotificationListPage } from "@/features/notifications/pages/NotificationListPage";
import { SuperAdminDashboardPage } from "@/features/admin/pages/SuperAdminDashboardPage";
import { ManagerListPage } from "@/features/admin/pages/ManagerListPage";
import { DeviceListPage } from "@/features/devices/pages/DeviceListPage";
import { TechnicianListPage } from "@/features/technicians/pages/TechnicianListPage";
import { MaintenancePage } from "@/features/maintenance/pages/MaintenancePage";

export const router = createBrowserRouter([
  {
    path: "/login",
    element: <LoginPage />
  },
  {
    path: "/register",
    element: <RegisterPage />
  },
  {
    path: "/forgot-password",
    element: <ForgotPasswordPage />
  },
  {
    path: "/admin",
    element: <SuperAdminLayout />,
    children: [
      {
        path: "",
        element: <Navigate to="/admin/dashboard" replace />
      },
      {
        path: "dashboard",
        element: <SuperAdminDashboardPage />
      },
      {
        path: "managers",
        element: <ManagerListPage />
      },
      {
        path: "audit-logs",
        element: <AuditLogPage />
      },
      {
        path: "settings",
        element: <SettingsPage />
      }
    ]
  },
  {
    path: "/",
    element: <MainLayout />,
    children: [
      {
        path: "dashboard",
        element: <DashboardPage />
      },
      {
        path: "motels",
        element: <MotelListPage />
      },
      {
        path: "devices",
        element: <DeviceListPage />
      },
      {
        path: "technicians",
        element: <TechnicianListPage />
      },
      {
        path: "maintenance",
        element: <MaintenancePage />
      },
      {
        path: "services",
        element: <ServiceListPage />
      },
      {
        path: "residents",
        element: <ResidentListPage />
      },
      {
        path: "contracts",
        element: <ContractListPage />
      },
      {
        path: "meter",
        element: <MeterReadingPage />
      },
      {
        path: "invoices",
        element: <InvoiceListPage />
      },
      {
        path: "reports",
        element: <ReportPage />
      },
      {
        path: "audit-log",
        element: <AuditLogPage />
      },
      {
        path: "settings",
        element: <SettingsPage />
      },
      {
        path: "notifications",
        element: <NotificationListPage />
      }
    ]
  }
]);
