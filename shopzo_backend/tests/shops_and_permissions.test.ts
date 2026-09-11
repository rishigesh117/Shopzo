import request from 'supertest';
import app from '../src/app';
import { memoryDb, setUseMemoryDb } from '../src/db';

beforeAll(() => {
  setUseMemoryDb(true);
});

beforeEach(() => {
  memoryDb.clear();
});

describe('Shops, Staff & Multi-Tenant Permission Enforcement', () => {
  let ownerToken: string;
  let ownerUserId: string;
  let shopAId: string;
  let shopBId: string;

  beforeEach(async () => {
    // Register owner
    const regRes = await request(app).post('/api/auth/register').send({
      name: 'Owner Rishi',
      mobileNumber: '9999999999',
      password: 'ownerpassword'
    });
    ownerToken = regRes.body.token;
    ownerUserId = regRes.body.user.id;

    // Create Shop A
    const shopARes = await request(app)
      .post('/api/shops')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ name: 'Supermarket Shop A', address: 'Main Street' });
    shopAId = shopARes.body.shop.id;

    // Create Shop B under another user
    const ownerBRes = await request(app).post('/api/auth/register').send({
      name: 'Owner B',
      mobileNumber: '8888888888',
      password: 'ownerbpassword'
    });
    const shopBRes = await request(app)
      .post('/api/shops')
      .set('Authorization', `Bearer ${ownerBRes.body.token}`)
      .send({ name: 'Supermarket Shop B', address: 'Side Street' });
    shopBId = shopBRes.body.shop.id;
  });

  it('should generate shop code in format SZ-XXXXXX upon shop creation', async () => {
    const res = await request(app)
      .post('/api/shops')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ name: 'Test Shop Code' });

    expect(res.status).toBe(201);
    expect(res.body.shop.shopCode).toMatch(/^SZ-\d{6}$/);
  });

  it('should allow owner to add staff with permissions and staff can login', async () => {
    const addStaffRes = await request(app)
      .post(`/api/shops/${shopAId}/staff`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .set('X-Shop-Id', shopAId)
      .send({
        name: 'Staff Cashier',
        mobileNumber: '7777777777',
        password: 'staffpassword',
        permissions: ['BILLING_CREATE', 'BILLING_VIEW']
      });

    expect(addStaffRes.status).toBe(201);
    expect(addStaffRes.body.staff.mobileNumber).toBe('7777777777');

    // Staff Login
    const staffLoginRes = await request(app).post('/api/auth/login').send({
      mobileNumber: '7777777777',
      password: 'staffpassword'
    });

    expect(staffLoginRes.status).toBe(200);
    expect(staffLoginRes.body.shops[0].id).toBe(shopAId);
  });

  it('should enforce HTTP 403 Forbidden when staff accesses forbidden endpoint', async () => {
    // Add staff with ONLY billing permissions
    await request(app)
      .post(`/api/shops/${shopAId}/staff`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .set('X-Shop-Id', shopAId)
      .send({
        name: 'Staff Cashier Only',
        mobileNumber: '7777777777',
        password: 'staffpassword',
        permissions: ['BILLING_CREATE', 'BILLING_VIEW']
      });

    const staffLoginRes = await request(app).post('/api/auth/login').send({
      mobileNumber: '7777777777',
      password: 'staffpassword'
    });
    const staffToken = staffLoginRes.body.token;

    // Staff attempts to add product (requires INVENTORY_ADD) -> should get 403
    const forbiddenRes = await request(app)
      .post(`/api/shops/${shopAId}/products`)
      .set('Authorization', `Bearer ${staffToken}`)
      .set('X-Shop-Id', shopAId)
      .send({
        name: 'Forbidden Item',
        categoryId: 'cat-1'
      });

    expect(forbiddenRes.status).toBe(403);
    expect(forbiddenRes.body.error).toMatch(/Forbidden/i);
  });

  it('should enforce multi-tenant isolation (Shop A user accessing Shop B returns 403 Forbidden)', async () => {
    // Owner A attempts to access Shop B product endpoint
    const res = await request(app)
      .get(`/api/shops/${shopBId}/products`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .set('X-Shop-Id', shopBId);

    expect(res.status).toBe(403);
    expect(res.body.error).toMatch(/do not have access to this shop/i);
  });

  it('should reject X-Shop-Id header spoofing attempts to access unauthorized shops', async () => {
    // Owner A attempts sync push while setting X-Shop-Id to Shop B
    const res = await request(app)
      .post('/api/sync/push')
      .set('Authorization', `Bearer ${ownerToken}`)
      .set('X-Shop-Id', shopBId)
      .send({ shopId: shopBId, operations: [] });

    expect(res.status).toBe(403);
    expect(res.body.error).toMatch(/do not have access to this shop/i);
  });

  it('should protect owner from being deleted or demoted', async () => {
    // Attempting to delete owner's staff permission entry
    const ownerPerm = Array.from(memoryDb.staffPermissions.values()).find(sp => sp.shopId === shopAId && sp.role === 'OWNER');
    expect(ownerPerm).toBeDefined();

    const deleteRes = await request(app)
      .delete(`/api/shops/${shopAId}/staff/${ownerPerm.id}`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .set('X-Shop-Id', shopAId);

    expect(deleteRes.status).toBe(403);
    expect(deleteRes.body.error).toMatch(/cannot remove shop owner/i);
  });
});
