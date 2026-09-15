import { createBrowserRouter } from "react-router-dom";
import { Providers } from "@/app/providers";
import { MainLayout } from "@/components/layout/MainLayout";
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
