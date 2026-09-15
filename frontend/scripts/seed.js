#!/usr/bin/env node
/**
 * Seed Script cho UAT Demo - 48 High Priority Use Cases
 * 
 * Sử dụng:
 *   node frontend/scripts/seed.js
 * 
 * Xóa data cũ:
 *   node frontend/scripts/clean.js
 */
import axios from 'axios';

const API_URL = 'http://localhost:8080';
const SEED_PHONE = '0911222333'; // Quản lý demo cố định
const SEED_PASSWORD = 'Demo@123456';
const SEED_TENANT = 'Khu trọ SmartDemo';
const SEED_MANAGER_NAME = 'Nguyễn Demo Manager';

const client = axios.create({
  baseURL: API_URL,
  headers: { 'Content-Type': 'application/json' },
  timeout: 30000,
});

function log(msg) { console.log(msg); }
function ok(msg) { console.log(`  ✅ ${msg}`); }
function err(msg, e) { console.error(`  ❌ ${msg}:`, e?.response?.data?.message || e?.message || e); }

// Utility: random int
const rnd = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;

async function main() {
  log('\n🚀 ===== BẮT ĐẦU SEED DATA CHO UAT DEMO =====\n');

  // ─────────────────────────────────────────────
  // 1. Đăng ký Quản lý (UC01)
  // ─────────────────────────────────────────────
  log('📌 BƯỚC 1: Đăng ký tài khoản Quản lý (UC01)');
  try {
    await client.post('/api/public/auth/register', {
      phone: SEED_PHONE,
      password: SEED_PASSWORD,
      fullName: SEED_MANAGER_NAME,
      tenantName: SEED_TENANT,
    });
    ok(`Tài khoản Quản lý đã tạo: ${SEED_PHONE}`);
  } catch (e) {
    if (e?.response?.data?.code === 'PHONE_EXISTS') {
      ok(`Tài khoản đã tồn tại: ${SEED_PHONE} — tiếp tục đăng nhập`);
    } else {
      err('Đăng ký Quản lý', e);
      process.exit(1);
    }
  }

  // ─────────────────────────────────────────────
  // 2. Đăng nhập (UC02)
  // ─────────────────────────────────────────────
  log('\n📌 BƯỚC 2: Đăng nhập (UC02)');
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

  // ─────────────────────────────────────────────
  // 3. Tạo Khu trọ (UC20)
  // ─────────────────────────────────────────────
  log('\n📌 BƯỚC 3: Tạo Khu trọ (UC20, UC21, UC22)');
  let motel1, motel2;
  try {
    const res = await client.post('/api/motels', {
      name: 'Khu trọ Sinh Viên Cao Cấp A',
      address: '123 Đường Điện Biên Phủ, Phường 25, Bình Thạnh, TP.HCM',
      totalFloors: 4,
      description: 'Khu trọ mới xây dựng 2024, an ninh 24/7, có camera, thang máy. Gần ĐH Bách Khoa, ĐH Sư Phạm.',
    });
    motel1 = res.data.data;
    ok(`Khu trọ 1: ${motel1.name} (ID: ${motel1.id})`);
  } catch (e) { err('Tạo khu trọ 1', e); }

  try {
    const res = await client.post('/api/motels', {
      name: 'Nhà Trọ Gia Đình Hạnh Phúc',
      address: '45A Nguyễn Đình Chiểu, Phường Đa Kao, Quận 1, TP.HCM',
      totalFloors: 3,
      description: 'Nhà trọ gia đình yên tĩnh, sạch sẽ. Gần công viên, siêu thị.',
    });
    motel2 = res.data.data;
    ok(`Khu trọ 2: ${motel2.name} (ID: ${motel2.id})`);
  } catch (e) { err('Tạo khu trọ 2', e); }

  if (!motel1) {
    console.error('\n🚨 Không tạo được khu trọ! Dừng seed.\n');
    process.exit(1);
  }

  // ─────────────────────────────────────────────
  // 4. Tạo Dịch vụ (UC32)
  // ─────────────────────────────────────────────
  log('\n📌 BƯỚC 4: Tạo Dịch vụ (UC32, UC33, UC34)');
  const services = {};
  const serviceSpecs = [
    { name: 'Điện sinh hoạt', chargeType: 'PER_INDEX', unit: 'kWh', basePrice: 3500 },
    { name: 'Nước sinh hoạt', chargeType: 'PER_INDEX', unit: 'm³', basePrice: 20000 },
    { name: 'Internet Cáp Quang', chargeType: 'FIXED', unit: 'Phòng/tháng', basePrice: 100000 },
    { name: 'Phí Vệ Sinh', chargeType: 'FIXED', unit: 'Phòng/tháng', basePrice: 30000 },
    { name: 'Giữ xe máy', chargeType: 'FIXED', unit: 'xe/tháng', basePrice: 100000 },
    { name: 'Phòng cháy chữa cháy', chargeType: 'FIXED', unit: 'Phòng/tháng', basePrice: 20000, mandatory: true },
  ];
  for (const spec of serviceSpecs) {
    try {
      const res = await client.post(`/api/motels/${motel1.id}/services`, spec);
      services[spec.name] = res.data.data;
      ok(`Dịch vụ: ${spec.name} (${spec.chargeType} - ${spec.basePrice.toLocaleString()}đ/${spec.unit})`);
    } catch (e) { err(`Tạo dịch vụ ${spec.name}`, e); }
  }

  // ─────────────────────────────────────────────
  // 5. Tạo Phòng (UC26)
  // ─────────────────────────────────────────────
  log('\n📌 BƯỚC 5: Tạo Phòng (UC26, UC27, UC28)');
  const rooms = {};
  const roomSpecs = [
    // Tầng 1 - Khu trọ 1
    { roomNumber: '101', floor: 1, area: 25.5, basePrice: 3000000, description: 'Phòng tầng trệt, view đường, tiện di chuyển', status: 'AVAILABLE' },
    { roomNumber: '102', floor: 1, area: 22.0, basePrice: 2800000, description: 'Phòng tầng trệt có gác lửng', status: 'AVAILABLE' },
    // Tầng 2 
    { roomNumber: '201', floor: 2, area: 28.0, basePrice: 3500000, description: 'Phòng rộng có ban công', status: 'AVAILABLE' },
    { roomNumber: '202', floor: 2, area: 24.0, basePrice: 3200000, description: 'Phòng tiêu chuẩn tầng 2', status: 'AVAILABLE' },
    { roomNumber: '203', floor: 2, area: 20.0, basePrice: 2700000, description: 'Phòng nhỏ gọn', status: 'AVAILABLE' },
    // Tầng 3
    { roomNumber: '301', floor: 3, area: 30.0, basePrice: 4000000, description: 'Phòng VIP tầng 3, yên tĩnh, view đẹp', status: 'AVAILABLE' },
    { roomNumber: '302', floor: 3, area: 26.0, basePrice: 3600000, description: 'Phòng tầng 3, khu vực yên tĩnh', status: 'AVAILABLE' },
    // Phòng đang sửa chữa
    { roomNumber: '303', floor: 3, area: 24.0, basePrice: 3200000, description: 'Đang nâng cấp nội thất', status: 'REPAIRING' },
    // Tầng 4
    { roomNumber: '401', floor: 4, area: 35.0, basePrice: 4500000, description: 'Penthouse tầng 4, không gian rộng', status: 'AVAILABLE' },
    { roomNumber: '402', floor: 4, area: 30.0, basePrice: 4000000, description: 'Phòng tầng 4 cao thoáng', status: 'AVAILABLE' },
  ];
  for (const spec of roomSpecs) {
    try {
      const { status, ...body } = spec;
      const res = await client.post(`/api/motels/${motel1.id}/rooms`, body);
      rooms[spec.roomNumber] = res.data.data;
      ok(`Phòng ${spec.roomNumber} (Tầng ${spec.floor}) - ${spec.basePrice.toLocaleString()}đ/tháng`);
      // Set status if not AVAILABLE
      if (status !== 'AVAILABLE') {
        await client.patch(`/api/motels/${motel1.id}/rooms/${rooms[spec.roomNumber].id}/status`, { status });
        ok(`  → Cập nhật trạng thái phòng ${spec.roomNumber}: ${status}`);
      }
    } catch (e) { err(`Tạo phòng ${spec.roomNumber}`, e); }
  }

  // ─────────────────────────────────────────────
  // 6. Gán Dịch vụ cho Phòng (UC37)
  // ─────────────────────────────────────────────
  log('\n📌 BƯỚC 6: Gán Dịch vụ cho Phòng (UC37)');
  const occupiedRooms = ['101', '102', '201', '202', '203', '301', '302'];
  const electricService = services['Điện sinh hoạt'];
  const waterService = services['Nước sinh hoạt'];
  const wifiService = services['Internet Cáp Quang'];
  const cleanService = services['Phí Vệ Sinh'];
  const pcccService = services['Phòng cháy chữa cháy'];

  const allRoomIds = occupiedRooms.map((rn) => rooms[rn]?.id).filter(Boolean);
  
  // Assign electric & water to all rooms
  for (const svc of [electricService, waterService, cleanService, pcccService]) {
    if (!svc) continue;
    try {
      await client.post(`/api/motels/${motel1.id}/services/${svc.id}/assign-to-rooms`, { roomIds: allRoomIds });
      ok(`Gán "${svc.name}" cho ${allRoomIds.length} phòng`);
    } catch (e) { err(`Gán dịch vụ ${svc?.name}`, e); }
  }
  // WiFi to only some rooms
  const wifiRoomIds = ['101', '201', '301'].map((rn) => rooms[rn]?.id).filter(Boolean);
  if (wifiService) {
    try {
      await client.post(`/api/motels/${motel1.id}/services/${wifiService.id}/assign-to-rooms`, { roomIds: wifiRoomIds });
      ok(`Gán "Internet" cho ${wifiRoomIds.length} phòng (chọn lọc)`);
    } catch (e) { err('Gán dịch vụ wifi', e); }
  }

  // ─────────────────────────────────────────────
  // 7. Tạo Khách thuê (UC49)
  // ─────────────────────────────────────────────
  log('\n📌 BƯỚC 7: Tạo hồ sơ Khách thuê (UC49, UC50, UC51)');
  const tenants = [];
  const tenantSpecs = [
    { fullName: 'Nguyễn Văn An', phone: '0901001001', email: 'nva@student.edu.vn', idCardNumber: '079201001122' },
    { fullName: 'Trần Thị Bích', phone: '0901002002', email: 'ttb@gmail.com', idCardNumber: '079201002233' },
    { fullName: 'Lê Minh Cường', phone: '0901003003', email: 'lmc@company.com', idCardNumber: '079201003344' },
    { fullName: 'Phạm Thị Dung', phone: '0901004004', email: 'ptd@yahoo.com', idCardNumber: '079201004455' },
    { fullName: 'Hoàng Văn Em', phone: '0901005005', email: null, idCardNumber: '079201005566' },
    { fullName: 'Ngô Thị Phương', phone: '0901006006', email: 'ntp@gmail.com', idCardNumber: '079201006677' },
    { fullName: 'Đinh Quốc Hùng', phone: '0901007007', email: 'dqh@tech.vn', idCardNumber: '079201007788' },
    { fullName: 'Lý Thị Ký', phone: '0901008008', email: null, idCardNumber: '079201008899' },
    { fullName: 'Bùi Văn Long', phone: '0901009009', email: 'bvl@mail.com', idCardNumber: '079201009900' },
    { fullName: 'Đỗ Thị Mai', phone: '0901010010', email: 'dtm@work.vn', idCardNumber: '079201010011' },
  ];
  for (const spec of tenantSpecs) {
    try {
      const body = { ...spec };
      if (!body.email) delete body.email;
      const res = await client.post('/api/residents', body);
      tenants.push(res.data.data);
      ok(`Khách thuê: ${spec.fullName} (${spec.phone})`);
    } catch (e) { err(`Tạo khách thuê ${spec.fullName}`, e); }
  }

  if (tenants.length < 3) {
    console.error('\n🚨 Không đủ khách thuê để tạo hợp đồng!\n');
    process.exit(1);
  }

  // ─────────────────────────────────────────────
  // 8. Tạo Hợp đồng (UC63)
  // ─────────────────────────────────────────────
  log('\n📌 BƯỚC 8: Tạo Hợp đồng (UC63, UC64, UC65)');
  const contracts = [];
  const today = new Date();
  const oneYearLater = new Date(today);
  oneYearLater.setFullYear(today.getFullYear() + 1);
  const sixMonthsLater = new Date(today);
  sixMonthsLater.setMonth(today.getMonth() + 6);
  const twoMonthsLater = new Date(today);
  twoMonthsLater.setMonth(today.getMonth() + 2);
  const fmt = (d) => d.toISOString().slice(0, 10);

  const contractSpecs = [
    // Hợp đồng đang hiệu lực
    { roomKey: '101', tenantIdx: 0, rentPrice: 3000000, depositAmount: 3000000, endDate: fmt(oneYearLater), depositStatus: 'UNPAID' },
    { roomKey: '201', tenantIdx: 1, rentPrice: 3500000, depositAmount: 7000000, endDate: fmt(oneYearLater), depositStatus: 'UNPAID' },
    { roomKey: '301', tenantIdx: 2, rentPrice: 4000000, depositAmount: 4000000, endDate: fmt(sixMonthsLater), depositStatus: 'UNPAID' },
    { roomKey: '102', tenantIdx: 3, rentPrice: 2800000, depositAmount: 2800000, endDate: fmt(oneYearLater), depositStatus: 'UNPAID' },
    { roomKey: '202', tenantIdx: 4, rentPrice: 3200000, depositAmount: 3200000, endDate: fmt(twoMonthsLater), depositStatus: 'UNPAID' }, // Sắp hết hạn
    { roomKey: '203', tenantIdx: 5, rentPrice: 2700000, depositAmount: 2700000, endDate: fmt(oneYearLater), depositStatus: 'UNPAID' },
  ];

  for (const spec of contractSpecs) {
    const room = rooms[spec.roomKey];
    const tenant = tenants[spec.tenantIdx];
    if (!room || !tenant) { err(`Thiếu phòng/khách cho hợp đồng ${spec.roomKey}`); continue; }
    try {
      const res = await client.post('/api/contracts', {
        roomId: room.id,
        primaryResidentUserId: tenant.userId,
        startDate: fmt(today),
        endDate: spec.endDate,
        billingDate: fmt(today),
        rentPrice: spec.rentPrice,
        depositAmount: spec.depositAmount,
        depositStatus: spec.depositStatus,
      });
      contracts.push(res.data.data);
      ok(`Hợp đồng: Phòng ${spec.roomKey} ← ${tenant.fullName} (${spec.rentPrice.toLocaleString()}đ/tháng)`);
    } catch (e) { err(`Tạo hợp đồng phòng ${spec.roomKey}`, e); }
  }

  // Thu tiền cọc cho 3 hợp đồng đầu (UC69)
  log('\n📌 BƯỚC 8b: Thu tiền cọc (UC69)');
  for (let i = 0; i < Math.min(3, contracts.length); i++) {
    if (contracts[i]) {
      try {
        await client.post(`/api/contracts/${contracts[i].id}/deposit/collect`);
        ok(`Thu cọc hợp đồng #${contracts[i].id} (Phòng ${contractSpecs[i].roomKey})`);
      } catch (e) { err(`Thu cọc HĐ #${contracts[i].id}`, e); }
    }
  }

  // ─────────────────────────────────────────────
  // 9. Ghi chỉ số Điện/Nước (UC70)
  // ─────────────────────────────────────────────
  log('\n📌 BƯỚC 9: Ghi chỉ số Điện/Nước (UC70, UC72)');
  const billingMonth = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-01`;
  const readingRooms = ['101', '201', '301', '102', '202', '203'];
  
  for (const roomKey of readingRooms) {
    const room = rooms[roomKey];
    if (!room || !electricService) continue;
    try {
      const newReading = rnd(100, 300);
      await client.post('/api/v1/meter-readings', {
        roomId: room.id,
        serviceId: electricService.id,
        billingMonth,
        newReading,
        readingImageUrl: 'https://images.unsplash.com/photo-1558449028-b53a39d100fc?w=400',
      });
      ok(`Ghi điện phòng ${roomKey}: ${newReading} kWh`);
    } catch (e) { err(`Ghi điện phòng ${roomKey}`, e); }

    if (!waterService) continue;
    try {
      const newReading = rnd(10, 30);
      await client.post('/api/v1/meter-readings', {
        roomId: room.id,
        serviceId: waterService.id,
        billingMonth,
        newReading,
        readingImageUrl: 'https://images.unsplash.com/photo-1558449028-b53a39d100fc?w=400',
      });
      ok(`Ghi nước phòng ${roomKey}: ${newReading} m³`);
    } catch (e) { err(`Ghi nước phòng ${roomKey}`, e); }
  }

  // ─────────────────────────────────────────────
  // 10. Tạo Hóa đơn (UC73)
  // ─────────────────────────────────────────────
  log('\n📌 BƯỚC 10: Tạo Hóa đơn tự động (UC73, UC74, UC75)');
  try {
    const res = await client.post('/api/v1/invoices/generate', {
      motelId: motel1.id,
      billingMonth,
    });
    const result = res.data.data;
    ok(`Tạo ${result?.generatedCount ?? '?'} hóa đơn cho tháng ${billingMonth}`);
  } catch (e) { err('Tạo hóa đơn batch', e); }

  // ─────────────────────────────────────────────
  // SUMMARY
  // ─────────────────────────────────────────────
  log(`
╔══════════════════════════════════════════════════════════╗
║           🎉 SEED DATA HOÀN TẤT!                       ║
╠══════════════════════════════════════════════════════════╣
║  📱 SĐT đăng nhập:   ${SEED_PHONE}                     ║
║  🔑 Mật khẩu:        ${SEED_PASSWORD}                  ║
║  🏢 Tên khu trọ:     ${SEED_TENANT}                    ║
╠══════════════════════════════════════════════════════════╣
║  📦 Đã tạo:                                             ║
║    - 2 Khu trọ                                          ║
║    - 6 Dịch vụ (điện, nước, wifi, vệ sinh...)          ║
║    - 10 Phòng (các tầng, trạng thái khác nhau)         ║
║    - 10 Khách thuê                                      ║
║    - 6 Hợp đồng đang hiệu lực                          ║
║    - Chỉ số điện/nước tháng này                        ║
║    - Hóa đơn tháng này                                 ║
╠══════════════════════════════════════════════════════════╣
║  🧹 Xóa data:  node frontend/scripts/clean.js           ║
╚══════════════════════════════════════════════════════════╝
`);
}

main().catch((e) => {
  console.error('\n🚨 Lỗi không mong đợi:', e.message);
  process.exit(1);
});
