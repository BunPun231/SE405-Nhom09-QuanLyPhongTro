#!/usr/bin/env node
/**
 * Clean Script - Xóa toàn bộ seed data để seed lại sạch
 * 
 * Sử dụng:
 *   node frontend/scripts/clean.js
 * 
 * CẢNH BÁO: Script này sẽ xóa toàn bộ data trong database local!
 * Chỉ dùng trên môi trường dev/demo.
 */
import axios from 'axios';

const API_URL = 'http://localhost:8080';
const SEED_PHONE = '0911222333';
const SEED_PASSWORD = 'Demo@123456';

const client = axios.create({
  baseURL: API_URL,
  headers: { 'Content-Type': 'application/json' },
  timeout: 30000,
});

function ok(msg) { console.log(`  ✅ ${msg}`); }
function err(msg, e) { console.error(`  ❌ ${msg}:`, e?.response?.data?.message || e?.message); }
function info(msg) { console.log(`  ℹ️  ${msg}`); }

async function main() {
  console.log('\n🧹 ===== BẮT ĐẦU DỌN DẸP SEED DATA =====\n');
  console.log('⚠️  CẢNH BÁO: Sẽ xóa toàn bộ dữ liệu demo!\n');

  // 1. Đăng nhập
  console.log('📌 Đăng nhập...');
  try {
    const res = await client.post('/api/public/auth/login', {
      identity: SEED_PHONE,
      password: SEED_PASSWORD,
    });
    client.defaults.headers.common['Authorization'] = `Bearer ${res.data.data.accessToken}`;
    ok('Đăng nhập thành công');
  } catch (e) {
    err('Đăng nhập thất bại', e);
    console.log('\n💡 Không thể đăng nhập - có thể data đã được xóa rồi.');
    console.log('💡 Để clean hoàn toàn, hãy chạy lệnh:\n');
    console.log('   docker exec rental-local-postgres psql -U postgres -d rental_dev -c "TRUNCATE TABLE contracts, contract_residents, contract_service_items, contract_appendices, invoices, invoice_details, meter_readings, rooms, services, motels, users, tenants RESTART IDENTITY CASCADE;"\n');
    process.exit(1);
  }

  // 2. Xóa hợp đồng (cancel + auto-delete)
  console.log('\n📌 Xóa hóa đơn...');
  try {
    let page = 0;
    let hasMore = true;
    let deletedCount = 0;
    while (hasMore) {
      const res = await client.get('/api/v1/invoices', { params: { page, size: 50 } });
      const invoices = res.data.data?.content || [];
      if (invoices.length === 0) { hasMore = false; break; }
      for (const inv of invoices) {
        try {
          if (inv.status === 'PENDING' || inv.status === 'VOID') {
            await client.delete(`/api/v1/invoices/${inv.id}`);
            deletedCount++;
          }
        } catch (_) {}
      }
      if (invoices.length < 50) hasMore = false;
      else page++;
    }
    ok(`Đã xóa ${deletedCount} hóa đơn`);
  } catch (e) { err('Xóa hóa đơn', e); }

  // 3. Xóa hợp đồng
  console.log('\n📌 Hủy hợp đồng...');
  try {
    const motelsRes = await client.get('/api/motels');
    const motels = motelsRes.data.data?.content || [];
    let cancelledCount = 0;
    for (const motel of motels) {
      const contractsRes = await client.get(`/api/contracts/motels/${motel.id}`, { params: { size: 100 } });
      const contracts = contractsRes.data.data?.content || [];
      for (const contract of contracts) {
        if (contract.status === 'ACTIVE' || contract.status === 'DRAFT') {
          try {
            await client.post(`/api/contracts/${contract.id}/cancel`, null, { params: { reason: 'Seed cleanup' } });
            cancelledCount++;
          } catch (_) {}
        }
      }
    }
    ok(`Đã hủy ${cancelledCount} hợp đồng`);
  } catch (e) { err('Hủy hợp đồng', e); }

  // 4. Xóa khu trọ (sẽ cascade xóa phòng, dịch vụ)
  console.log('\n📌 Xóa Khu trọ (phòng + dịch vụ sẽ bị xóa theo)...');
  try {
    let deletedCount = 0;
    let page = 0;
    let hasMore = true;
    while (hasMore) {
      const res = await client.get('/api/motels', { params: { page, size: 20 } });
      const motels = res.data.data?.content || [];
      if (motels.length === 0) { hasMore = false; break; }
      for (const motel of motels) {
        try {
          await client.delete(`/api/motels/${motel.id}`);
          deletedCount++;
          ok(`Xóa khu trọ: ${motel.name}`);
        } catch (e2) { err(`Xóa khu trọ ${motel.name}`, e2); }
      }
      if (motels.length < 20) hasMore = false;
      else page++;
    }
    ok(`Tổng: đã xóa ${deletedCount} khu trọ`);
  } catch (e) { err('Xóa khu trọ', e); }

  // 5. Xóa khách thuê
  console.log('\n📌 Xóa Khách thuê...');
  try {
    let page = 0;
    let hasMore = true;
    let deactivatedCount = 0;
    while (hasMore) {
      const res = await client.get('/api/residents', { params: { page, size: 50 } });
      const residents = res.data.data?.content || [];
      if (residents.length === 0) { hasMore = false; break; }
      for (const resident of residents) {
        try {
          await client.post(`/api/residents/${resident.userId}/deactivate`);
          deactivatedCount++;
        } catch (_) {}
      }
      if (residents.length < 50) hasMore = false;
      else page++;
    }
    ok(`Đã hủy kích hoạt ${deactivatedCount} khách thuê`);
  } catch (e) { err('Xóa khách thuê', e); }

  console.log(`
╔══════════════════════════════════════════════════════════╗
║           🧹 DỌN DẸP HOÀN TẤT!                        ║
╠══════════════════════════════════════════════════════════╣
║  Data đã được dọn dẹp. Bây giờ bạn có thể:             ║
║    node frontend/scripts/seed.js  ← Seed lại data       ║
╚══════════════════════════════════════════════════════════╝
`);
}

main().catch((e) => {
  console.error('\n🚨 Lỗi:', e.message);
});
