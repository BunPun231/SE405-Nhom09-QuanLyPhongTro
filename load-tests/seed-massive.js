#!/usr/bin/env node
/**
 * MASSIVE Seed Script cho Load Test / Spike Test Demo
 * =====================================================
 * Tạo dữ liệu khổng lồ để làm phình Database:
 *   - 5 Khu trọ (Motel)
 *   - 20 Phòng / khu trọ  → 100 phòng tổng
 *   - 100 Khách thuê
 *   - ~80 Hợp đồng ACTIVE (mỗi phòng chẵn 1 HĐ)
 *   - Chỉ số Điện/Nước + Hóa đơn cho tất cả
 *
 * KHÔNG SỬA FILE NÀY SANG frontend/scripts/seed.js !
 *
 * Sử dụng:
 *   node load-tests/seed-massive.js
 *
 * Xóa data cũ trước: node frontend/scripts/clean.js
 */
import axios from 'axios';

// ─── Config ────────────────────────────────────────────────────────────────────
const API_URL = 'http://localhost:8080';

// ⚠ Giữ nguyên thông tin đăng nhập của Manager mặc định — dùng cho K6 spike test
const SEED_PHONE    = '0911222333';
const SEED_PASSWORD = 'Demo@123456';
const SEED_TENANT   = 'Khu trọ SmartDemo';
const SEED_MANAGER_NAME = 'Nguyễn Demo Manager';

const NUM_MOTELS       = 5;
const ROOMS_PER_MOTEL  = 20;

// ─── Axios Client ─────────────────────────────────────────────────────────────
const client = axios.create({
  baseURL: API_URL,
  headers: { 'Content-Type': 'application/json' },
  timeout: 30000,
});

// ─── Helpers ──────────────────────────────────────────────────────────────────
const rnd     = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;
const sleep   = (ms) => new Promise(r => setTimeout(r, ms));
const log     = (msg) => console.log(msg);
const ok      = (msg) => console.log(`  ✅ ${msg}`);
const err = (msg, e) => {
  const status  = e?.response?.status ?? '?';
  const apiMsg  = e?.response?.data?.message || e?.response?.data?.error || e?.message || String(e);
  const apiCode = e?.response?.data?.code ? ` [${e.response.data.code}]` : '';
  console.error(`  ❌ ${msg}: HTTP ${status}${apiCode} — ${apiMsg}`);
};
const fmt     = (d) => d.toISOString().slice(0, 10);

// Date helpers
const today         = new Date();
const oneYearLater  = new Date(today); oneYearLater.setFullYear(today.getFullYear() + 1);
const sixMonthsLater = new Date(today); sixMonthsLater.setMonth(today.getMonth() + 6);
const billingMonth  = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-01`;

// Vietnamese name pools for generating realistic tenant data
const firstNames  = ['Nguyễn', 'Trần', 'Lê', 'Phạm', 'Hoàng', 'Huỳnh', 'Phan', 'Vũ', 'Võ', 'Đặng'];
const midNames    = ['Văn', 'Thị', 'Minh', 'Đức', 'Hữu', 'Quốc', 'Thành', 'Ngọc', 'Thu', 'Bảo'];
const lastNames   = ['An', 'Bình', 'Cường', 'Dung', 'Em', 'Phương', 'Hùng', 'Ký', 'Long', 'Mai',
                     'Nam', 'Oanh', 'Phát', 'Quân', 'Rộng', 'Sơn', 'Tài', 'Uyên', 'Vinh', 'Xuân'];

function generateTenant(index) {
  const fn = firstNames[index % firstNames.length];
  const mn = midNames[(index * 3) % midNames.length];
  const ln = lastNames[index % lastNames.length];
  // 09 + 8 digits = 10 ký tự (đúng format SĐT Việt Nam)
  // Offset 1000 để tránh trùng với tenant từ lần seed trước (idex 0 → 0900001000)
  const phone = `09${String(100001000 + index).slice(1)}`;
  // 0792 + 8 digits = 12 ký tự (đúng format CCCD)
  const idCard = `0792${String(100001000 + index * 13).slice(1)}`;
  return {
    fullName: `${fn} ${mn} ${ln} ${index + 1}`,
    phone,
    email: index % 3 !== 0 ? `tenant${index + 1}@loadtest.vn` : undefined,
    idCardNumber: idCard,
  };
}

// Suffix ngắn để tránh UNIQUE constraint với record cũ đã soft-delete
const RUN_SUFFIX = Date.now().toString().slice(-4);

// ─── Main ─────────────────────────────────────────────────────────────────────
async function main() {
  log('\n🚀 ===== BẮT ĐẦU MASSIVE SEED DATA CHO LOAD TEST =====\n');
  log(`📊 Mục tiêu: ${NUM_MOTELS} khu trọ × ${ROOMS_PER_MOTEL} phòng = ${NUM_MOTELS * ROOMS_PER_MOTEL} phòng tổng`);

  // ────────────────────────────────────────────────────────────────────────────
  // BƯỚC 1: Đăng ký hoặc đăng nhập Manager
  // ────────────────────────────────────────────────────────────────────────────
  log('\n📌 BƯỚC 1: Đăng ký / Đăng nhập Manager');
  try {
    await client.post('/api/public/auth/register', {
      phone: SEED_PHONE,
      password: SEED_PASSWORD,
      fullName: SEED_MANAGER_NAME,
      tenantName: SEED_TENANT,
    });
    ok(`Tài khoản Manager mới: ${SEED_PHONE}`);
  } catch (e) {
    if (e?.response?.data?.code === 'PHONE_EXISTS') {
      ok(`Tài khoản đã tồn tại: ${SEED_PHONE} — tiếp tục đăng nhập`);
    } else {
      err('Đăng ký Manager', e);
      process.exit(1);
    }
  }

  let token;
  try {
    const res = await client.post('/api/public/auth/login', {
      identity: SEED_PHONE,
      password: SEED_PASSWORD,
    });
    token = res.data.data.accessToken;
    client.defaults.headers.common['Authorization'] = `Bearer ${token}`;
    ok('Đăng nhập thành công, đã lưu token');
  } catch (e) {
    err('Đăng nhập', e);
    process.exit(1);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // BƯỚC 2: Tạo 5 Khu trọ
  // ────────────────────────────────────────────────────────────────────────────
  log(`\n📌 BƯỚC 2: Tạo ${NUM_MOTELS} Khu trọ`);
  const motelNames = [
    `Khu trọ Sinh Viên Bách Khoa ${RUN_SUFFIX}`,
    `Nhà Trọ Gia Đình Quận 7 ${RUN_SUFFIX}`,
    `Khu Phòng Trọ Cao Cấp Thủ Đức ${RUN_SUFFIX}`,
    `Nhà Trọ Giá Rẻ Bình Dương ${RUN_SUFFIX}`,
    `Khu Trọ An Khang Gò Vấp ${RUN_SUFFIX}`,
  ];
  const motelAddresses = [
    '268 Lý Thường Kiệt, Phường 14, Quận 10, TP.HCM',
    '12 Nguyễn Thị Thập, Phường Tân Phú, Quận 7, TP.HCM',
    '88 Võ Văn Ngân, Phường Linh Chiểu, TP. Thủ Đức, TP.HCM',
    '56 Nguyễn An Ninh, Phường Lái Thiêu, TP. Thuận An, Bình Dương',
    '34 Phan Văn Trị, Phường 11, Quận Gò Vấp, TP.HCM',
  ];

  const motels = [];
  for (let i = 0; i < NUM_MOTELS; i++) {
    try {
      const res = await client.post('/api/motels', {
        name: motelNames[i],
        address: motelAddresses[i],
        // Cố định 5 tầng để khớp với layout 20 phòng (4 phòng/tầng × 5 tầng)
        totalFloors: 5,
        description: `Khu trọ số ${i + 1} dùng cho Load Test Demo.`,
      });
      motels.push(res.data.data);
      ok(`Khu trọ ${i + 1}: ${motelNames[i]} (ID: ${res.data.data.id})`);
    } catch (e) {
      err(`Tạo khu trọ ${i + 1}`, e);
    }
  }

  if (motels.length === 0) {
    console.error('\n🚨 Không tạo được khu trọ! Dừng seed.\n');
    process.exit(1);
  }

  // Dùng khu trọ đầu tiên làm master cho dịch vụ
  const masterMotel = motels[0];

  // ────────────────────────────────────────────────────────────────────────────
  // BƯỚC 3: Tạo Dịch vụ cho khu trọ đầu
  // ────────────────────────────────────────────────────────────────────────────
  log('\n📌 BƯỚC 3: Tạo Dịch vụ');
  const services = {};
  const serviceSpecs = [
    { name: 'Điện sinh hoạt',       chargeType: 'PER_INDEX', unit: 'kWh',          basePrice: 3500 },
    { name: 'Nước sinh hoạt',       chargeType: 'PER_INDEX', unit: 'm³',           basePrice: 20000 },
    { name: 'Internet Cáp Quang',   chargeType: 'FIXED',     unit: 'Phòng/tháng',  basePrice: 100000 },
    { name: 'Phí Vệ Sinh',         chargeType: 'FIXED',     unit: 'Phòng/tháng',  basePrice: 30000 },
    { name: 'Phòng cháy chữa cháy', chargeType: 'FIXED',     unit: 'Phòng/tháng',  basePrice: 20000, mandatory: true },
  ];

  for (const spec of serviceSpecs) {
    try {
      const res = await client.post(`/api/motels/${masterMotel.id}/services`, spec);
      services[spec.name] = res.data.data;
      ok(`Dịch vụ: ${spec.name}`);
    } catch (e) {
      err(`Tạo dịch vụ ${spec.name}`, e);
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // BƯỚC 4: Tạo 100 Phòng (20 phòng × 5 khu trọ)
  // ────────────────────────────────────────────────────────────────────────────
  log(`\n📌 BƯỚC 4: Tạo ${NUM_MOTELS * ROOMS_PER_MOTEL} phòng`);
  // allRooms[motelIndex] = [roomEntity, ...]
  const allRooms = [];

  for (let mi = 0; mi < motels.length; mi++) {
    const motel = motels[mi];
    const motelRooms = [];
    log(`  → Khu trọ ${mi + 1}: ${motel.name}`);

    for (let ri = 0; ri < ROOMS_PER_MOTEL; ri++) {
      const floor     = Math.floor(ri / 4) + 1;    // 4 rooms per floor → 5 floors
      const roomNum   = `${floor}${String(ri % 4 + 1).padStart(2, '0')}`;
      const basePrice = rnd(2500000, 4500000);
      const area      = rnd(18, 35);

      try {
        const res = await client.post(`/api/motels/${motel.id}/rooms`, {
          roomNumber: roomNum,
          floor,
          area,
          basePrice,
          description: `Phòng ${roomNum} khu ${mi + 1} - Load Test`,
        });
        motelRooms.push(res.data.data);
      } catch (e) {
        err(`Tạo phòng ${roomNum} khu ${mi + 1}`, e);
      }
    }

    allRooms.push(motelRooms);
    ok(`Đã tạo ${motelRooms.length}/${ROOMS_PER_MOTEL} phòng cho khu trọ ${mi + 1}`);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // BƯỚC 5: Gán Dịch vụ hàng loạt cho tất cả phòng khu trọ 1
  // ────────────────────────────────────────────────────────────────────────────
  log('\n📌 BƯỚC 5: Gán Dịch vụ cho phòng khu trọ 1');
  const masterRooms = allRooms[0] ?? [];
  const masterRoomIds = masterRooms.map(r => r.id).filter(Boolean);

  for (const svcKey of ['Điện sinh hoạt', 'Nước sinh hoạt', 'Phí Vệ Sinh', 'Phòng cháy chữa cháy']) {
    const svc = services[svcKey];
    if (!svc || masterRoomIds.length === 0) continue;
    try {
      await client.post(`/api/motels/${masterMotel.id}/services/${svc.id}/assign-to-rooms`, {
        roomIds: masterRoomIds,
      });
      ok(`Gán "${svcKey}" cho ${masterRoomIds.length} phòng`);
    } catch (e) {
      err(`Gán dịch vụ ${svcKey}`, e);
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // BƯỚC 6: Tạo 100 Khách thuê
  // ────────────────────────────────────────────────────────────────────────────
  const totalRooms  = NUM_MOTELS * ROOMS_PER_MOTEL;
  log(`\n📌 BƯỚC 6: Tạo ${totalRooms} Khách thuê`);
  const tenants = [];

  for (let i = 0; i < totalRooms; i++) {
    const spec = generateTenant(i);
    try {
      const body = { ...spec };
      if (!body.email) delete body.email;
      const res = await client.post('/api/residents', body);
      tenants.push(res.data.data);
      if ((i + 1) % 20 === 0) ok(`Đã tạo ${i + 1} khách thuê...`);
      await sleep(50); // Throttle để tránh overwhelm API
    } catch (e) {
      err(`Tạo khách thuê ${spec.fullName}`, e);
    }
  }
  ok(`Tổng cộng: ${tenants.length} khách thuê đã tạo`);

  // ────────────────────────────────────────────────────────────────────────────
  // BƯỚC 7: Tạo Hợp đồng cho 80 phòng (4 phòng / tầng đầu × 5 khu)
  // ────────────────────────────────────────────────────────────────────────────
  log('\n📌 BƯỚC 7: Tạo Hợp đồng (80/100 phòng)');
  const contracts = [];
  let tenantIdx = 0;

  for (let mi = 0; mi < allRooms.length; mi++) {
    const motelRooms = allRooms[mi];
    // Tạo HĐ cho 16 phòng đầu (80%) của mỗi khu
    const contractRooms = motelRooms.slice(0, Math.floor(ROOMS_PER_MOTEL * 0.8));

    for (const room of contractRooms) {
      if (tenantIdx >= tenants.length) break;
      const tenant = tenants[tenantIdx++];
      const endDate = rnd(0, 1) === 0 ? fmt(oneYearLater) : fmt(sixMonthsLater);

      try {
        const res = await client.post('/api/contracts', {
          roomId: room.id,
          primaryResidentUserId: tenant.userId,
          startDate: fmt(today),
          endDate,
          billingDate: fmt(today),
          rentPrice: room.basePrice ?? rnd(2500000, 4500000),
          depositAmount: room.basePrice ?? rnd(2500000, 4500000),
          depositStatus: 'UNPAID',
        });
        contracts.push(res.data.data);
        await sleep(30);
      } catch (e) {
        err(`Tạo HĐ phòng ${room.roomNumber} khu ${mi + 1}`, e);
      }
    }
    ok(`Khu ${mi + 1}: ${contractRooms.length} hợp đồng`);
  }
  ok(`Tổng cộng: ${contracts.length} hợp đồng đã tạo`);

  // ────────────────────────────────────────────────────────────────────────────
  // BƯỚC 8: Ghi chỉ số Điện/Nước cho phòng khu trọ 1
  // ────────────────────────────────────────────────────────────────────────────
  log('\n📌 BƯỚC 8: Ghi chỉ số Điện/Nước khu trọ 1');
  const electricService = services['Điện sinh hoạt'];
  const waterService    = services['Nước sinh hoạt'];

  for (const room of masterRooms) {
    if (electricService) {
      try {
        await client.post('/api/v1/meter-readings', {
          roomId: room.id,
          serviceId: electricService.id,
          billingMonth,
          newReading: rnd(100, 500),
          readingImageUrl: 'https://images.unsplash.com/photo-1558449028-b53a39d100fc?w=400',
        });
        await sleep(30);
      } catch (e) { /* ignore individual failures */ }
    }
    if (waterService) {
      try {
        await client.post('/api/v1/meter-readings', {
          roomId: room.id,
          serviceId: waterService.id,
          billingMonth,
          newReading: rnd(10, 50),
          readingImageUrl: 'https://images.unsplash.com/photo-1558449028-b53a39d100fc?w=400',
        });
        await sleep(30);
      } catch (e) { /* ignore individual failures */ }
    }
  }
  ok('Ghi chỉ số Điện/Nước xong');

  // ────────────────────────────────────────────────────────────────────────────
  // BƯỚC 9: Tạo Hóa đơn hàng loạt cho khu trọ 1
  // ────────────────────────────────────────────────────────────────────────────
  log('\n📌 BƯỚC 9: Tạo Hóa đơn hàng loạt');
  try {
    const res = await client.post('/api/v1/invoices/generate', {
      motelId: masterMotel.id,
      billingMonth,
    });
    const result = res.data.data;
    ok(`Tạo ${result?.generatedCount ?? '?'} hóa đơn cho tháng ${billingMonth}`);
  } catch (e) {
    err('Tạo hóa đơn batch', e);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // SUMMARY
  // ────────────────────────────────────────────────────────────────────────────
  log(`
╔══════════════════════════════════════════════════════════════╗
║        🎉 MASSIVE SEED DATA HOÀN TẤT!                      ║
╠══════════════════════════════════════════════════════════════╣
║  📱 SĐT đăng nhập:   ${SEED_PHONE}                         ║
║  🔑 Mật khẩu:        ${SEED_PASSWORD}                      ║
║  🏢 Tên khu trọ:     ${SEED_TENANT}                        ║
╠══════════════════════════════════════════════════════════════╣
║  📦 Đã tạo:                                                 ║
║    - ${NUM_MOTELS} Khu trọ                                          ║
║    - ${NUM_MOTELS * ROOMS_PER_MOTEL} Phòng (${ROOMS_PER_MOTEL} phòng/khu)                           ║
║    - ${tenants.length} Khách thuê                                     ║
║    - ${contracts.length} Hợp đồng ACTIVE                              ║
║    - Chỉ số điện/nước tháng ${billingMonth}               ║
║    - Hóa đơn tháng này (khu 1)                             ║
╠══════════════════════════════════════════════════════════════╣
║  🚀 Sẵn sàng chạy K6 Spike Test!                           ║
║  👉 k6 run load-tests/dashboard_spike_test.js              ║
╚══════════════════════════════════════════════════════════════╝
`);
}

main().catch((e) => {
  console.error('\n🚨 Lỗi không mong đợi:', e.message);
  process.exit(1);
});
