# Finance Module API Guide (UC70 - UC80)

This document provides a comprehensive guide for testing and using the Finance module endpoints. It includes sample requests, expected responses, and the database setup required to satisfy foreign key constraints (such as `service_usages`).

---

## 1. Database Setup & Seed Script

Because the `meter_readings` table has a foreign key referencing `service_usages(id)`, you must seed prerequisite data before submitting a meter reading. 

> [!TIP]
> **Automated Seeding (Recommended)**: You can easily seed a complete demo environment (including Motels, Rooms, Services, Contracts, Residents, Meter Readings, and Invoices) by running the automated script from the project root:
> ```bash
> node frontend/scripts/seed.js
> ```
> This script will create a manager account with `0911222333` / `Demo@123456` and automatically link all prerequisite data.

### Manual SQL Seeding (Alternative)

If you prefer to manually seed the database, copy and run the following script in your database client (DBeaver, pgAdmin, etc.).

> [!IMPORTANT]
> Replace `'YOUR_TENANT_ID_HERE'` and `'YOUR_USER_ID_HERE'` with the actual UUIDs of the Tenant and User you created during registration / login.

```sql
-- 1. Find your tenant_id and user_id
-- SELECT id FROM tenants;
-- SELECT id FROM users WHERE role = 'MANAGER';

-- 2. Insert Motel
INSERT INTO motels (id, tenant_id, name, address, total_floors, description)
VALUES (1, 'YOUR_TENANT_ID_HERE', 'Nhà Trọ Mẫu', '123 Đường ABC, TP.HCM', 3, 'Khu trọ thử nghiệm')
ON CONFLICT DO NOTHING;

-- 3. Insert Room
INSERT INTO rooms (id, motel_id, room_number, floor, base_price, status)
VALUES (1, 1, '101', 1, 3500000.00, 'RENTED')
ON CONFLICT DO NOTHING;

-- 4. Insert services
INSERT INTO services (id, motel_id, name, charge_type, unit, is_mandatory)
VALUES (1, 1, 'Điện', 'PER_INDEX', 'kWh', true),
       (2, 1, 'Nước', 'PER_INDEX', 'm3', true)
ON CONFLICT DO NOTHING;

-- 5. Insert service pricing (Required for invoice calculations)
INSERT INTO service_pricing (id, service_id, effective_from, base_price)
VALUES (1, 1, '2026-01-01', 3500.00), -- 3,500 VND per kWh
       (2, 2, '2026-01-01', 15000.00) -- 15,000 VND per m3
ON CONFLICT DO NOTHING;

-- 6. Register room service usage (Prerequisite for Meter Readings)
INSERT INTO service_usages (id, room_id, service_id, registered_quantity, start_index, status)
VALUES (1, 1, 1, 1, 100.00, 'ACTIVE'), -- Electricity usage id = 1
       (2, 1, 2, 1, 10.00, 'ACTIVE')   -- Water usage id = 2
ON CONFLICT DO NOTHING;

-- 7. Insert Contract (Prerequisite for Invoices)
INSERT INTO contracts (id, tenant_id, room_id, primary_resident_user_id, rent_price, start_date, end_date, deposit_amount, status, created_by)
VALUES (1, 'YOUR_TENANT_ID_HERE', 1, 'YOUR_USER_ID_HERE', 3500000.00, '2026-01-01', '2027-01-01', 3500000.00, 'ACTIVE', 'YOUR_USER_ID_HERE')
ON CONFLICT DO NOTHING;

-- 8. Assign services to Contract
INSERT INTO contract_service_items (tenant_id, contract_id, service_id, quantity)
VALUES ('YOUR_TENANT_ID_HERE', 1, 1, 1),
       ('YOUR_TENANT_ID_HERE', 1, 2, 1)
ON CONFLICT DO NOTHING;
```

---

## 2. API Endpoints Reference

All endpoints below require authentication. Remember to click **Authorize** in Swagger UI and log in.

### A. Meter Readings (Chốt chỉ số điện/nước - UC70, UC71, UC72)

#### 1. Submit Manual Meter Reading (UC70)
* **Endpoint**: `POST /api/v1/meter-readings`
* **Request Body**:
```json
{
  "roomId": 1,
  "serviceUsageId": 1,
  "billingMonth": "2026-05-01",
  "newReading": 150.00,
  "readingImageUrl": "https://example.com/images/reading.jpg"
}
```
* **Expected Response** (`200 OK`):
```json
{
  "id": 1,
  "roomId": 1,
  "billingMonth": "2026-05-01",
  "oldReading": 100.00,
  "newReading": 150.00,
  "consumption": 50.00,
  "status": "PENDING",
  "readingImageUrl": "https://example.com/images/reading.jpg",
  "confidence": null,
  "createdAt": "2026-05-19T14:30:00Z",
  "updatedAt": "2026-05-19T14:30:00Z"
}
```

#### 2. Submit with OCR Image Extraction (UC71)
Extracts numbers from an image without immediately saving the reading.
* **Endpoint**: `POST /api/v1/meter-readings/ocr`
* **Request Body**:
```json
{
  "roomId": 1,
  "serviceUsageId": 1,
  "billingMonth": "2026-05-01",
  "base64Image": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==",
  "mimeType": "image/png"
}
```
* **Expected Response** (`200 OK`):
```json
{
  "id": null,
  "roomId": 1,
  "billingMonth": "2026-05-01",
  "oldReading": 0.00,
  "newReading": 185.00,
  "consumption": 185.00,
  "status": "PENDING",
  "readingImageUrl": null,
  "confidence": 85.0,
  "createdAt": null,
  "updatedAt": null
}
```

#### 3. Approve Meter Reading (UC70)
* **Endpoint**: `POST /api/v1/meter-readings/{id}/approve` (e.g. `/api/v1/meter-readings/1/approve`)
* **Request Body**: *None*
* **Response**: `200 OK` with status changed to `"APPROVED"`.

#### 4. Reject Meter Reading (UC70)
* **Endpoint**: `POST /api/v1/meter-readings/{id}/reject?reason=Image too blurry`
* **Request Body**: *None*
* **Response**: `200 OK` with status changed to `"REJECTED"`.

#### 5. Get History & Trend (UC72)
* **History**: `GET /api/v1/meter-readings/rooms/{roomId}/history` (e.g. `/api/v1/meter-readings/rooms/1/history`)
* **Trend**: `GET /api/v1/meter-readings/rooms/{roomId}/trend?months=6`

---

### B. Invoices (Hóa đơn hàng tháng - UC73 - UC77)

#### 1. Generate Invoice (UC73)
Generates the monthly rent + services bill for a contract.
* **Endpoint**: `POST /api/v1/invoices/generate`
* **Request Body**:
```json
{
  "contractId": 1,
  "billingMonth": "2026-05-01"
```
* **Expected Response** (`200 OK`):
```json
{
  "id": 1,
  "contractId": 1,
  "billingMonth": "2026-05-01",
  "totalAmount": 3690000.00,
  "paidAmount": 0.00,
  "status": "PENDING",
  "dueDate": "2026-05-10",
  "details": [
    {
      "description": "Tiền phòng tháng 05/2026",
      "quantity": 1.00,
      "unitPrice": 3500000.00,
      "lineTotal": 3500000.00
    },
    {
      "description": "Tiền Điện (Tiêu thụ: 50.00 kWh)",
      "quantity": 50.00,
      "unitPrice": 3500.00,
      "lineTotal": 175000.00
    },
    {
      "description": "Tiền Nước (Tiêu thụ: 1.00 m3)",
      "quantity": 1.00,
      "unitPrice": 15000.00,
      "lineTotal": 15000.00
    }
  ]
}
```

#### 2. Get Invoice Detail (UC74)
* **Endpoint**: `GET /api/v1/invoices/{id}` (e.g. `/api/v1/invoices/1`)

#### 3. Send Notification to Resident (UC76)
* **Endpoint**: `POST /api/v1/invoices/{id}/send`
* **Response**: `200 OK` (creates a notification in the database for the resident).

---

### C. Payments & Webhooks (Thanh toán - UC78, UC79)

#### 1. Simulate VietQR Payment Webhook (Mock UC78)
Simulates receiving an instant transfer webhook callback from bank services.
* **Endpoint**: `POST /api/v1/payments/test/webhook-simulate`
* **Request Body**:
```json
{
  "transactionRef": "VIETQR_TEST_REF_001",
  "amount": 3690000.00,
  "bankCode": "VCB",
  "memo": "THANH TOAN HOA DON HD1",
  "rawData": "{\"accountNo\":\"123456789\",\"senderName\":\"NGUYEN VAN A\"}"
}
```
* **Expected Response** (`200 OK`):
```json
{
  "id": 1,
  "invoiceId": 1,
  "amount": 3690000.00,
  "transactionRef": "VIETQR_TEST_REF_001",
  "paymentMethod": "VIETQR",
  "bankCode": "VCB",
  "status": "SUCCESS",
  "paidAt": "2026-05-19T14:35:00Z"
}
```
*(Calling this will automatically change the linked invoice status to `"PAID"`)*

#### 2. Process Manual Payment (Cash / Bank Transfer)
* **Endpoint**: `POST /api/v1/payments/manual`
* **Request Body**:
```json
{
  "invoiceId": 1,
  "amount": 2000000.00,
  "paymentMethod": "CASH"
}
```
*(If paid amount is less than total, status transitions to `"PARTIAL"`)*

---

### D. Settlements (Tất toán hợp đồng - UC80)

#### 1. Calculate Settlement Balance (UC80)
Calculates final balances, damage deductions, and returns the net refund/debt.
* **Endpoint**: `POST /api/v1/settlements/calculate`
* **Request Body**:
```json
{
  "contractId": 1,
  "finalElectricReading": 220.00,
  "finalWaterReading": 15.00,
  "damageItems": [
    {
      "deviceId": 1,
      "damageCost": 500000.00,
      "note": "Hỏng cửa tủ gỗ"
    }
  ],
  "damageImageUrls": [
    "https://example.com/damage-wardrobe.jpg"
  ]
}
```
* **Expected Response** (`200 OK`):
```json
{
  "contractId": 1,
  "depositAmount": 3500000.00,
  "unpaidInvoicesTotal": 0.00,
  "finalServicesTotal": 145000.00,
  "damageCostTotal": 500000.00,
  "netAmount": 2855000.00,
  "type": "REFUND_TO_RESIDENT"
}
```
*(Net Amount = Deposit (3.5M) - Damage (500k) - Services (145k) = 2.855M refund)*

#### 2. Confirm Refund & Close Contract (UC80)
* **Endpoint**: `POST /api/v1/settlements/{contractId}/confirm`
* **Response**: `204 No Content` (status of contract shifts to `LIQUIDATED`, deposit status to `REFUNDED`).
