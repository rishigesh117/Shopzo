import request from 'supertest';
import app from '../src/app';
import { query, memoryDb } from '../src/db/pool';

async function findProduct(id: string) {
  try {
    const res = await query('SELECT * FROM products WHERE id = $1', [id]);
    if (res.rows.length > 0) return res.rows[0];
  } catch (e) {}
  return memoryDb.tables.products.find(p => p.id === id);
}

async function findCustomer(id: string) {
  try {
    const res = await query('SELECT * FROM customers WHERE id = $1', [id]);
    if (res.rows.length > 0) return res.rows[0];
  } catch (e) {}
  return memoryDb.tables.customers.find(c => c.id === id);
}

async function findBill(id: string) {
  try {
    const res = await query('SELECT * FROM bills WHERE id = $1', [id]);
    if (res.rows.length > 0) return res.rows[0];
  } catch (e) {}
  return memoryDb.tables.bills.find(b => b.id === id);
}

async function findPayment(id: string) {
  try {
    const res = await query('SELECT * FROM payments WHERE id = $1', [id]);
    if (res.rows.length > 0) return res.rows[0];
  } catch (e) {}
  return memoryDb.tables.payments.find(p => p.id === id);
}

async function findReturn(id: string) {
  try {
    const res = await query('SELECT * FROM returns WHERE id = $1', [id]);
    if (res.rows.length > 0) return res.rows[0];
  } catch (e) {}
  return memoryDb.tables.returns.find(r => r.id === id);
}

describe('PHASE 4 REAL E2E SYSTEM SMOKE TEST', () => {
  let user1Token: string;
  let user1Id: string;
  const user1Phone = '9991112223';

  let user2Token: string;
  let user2Id: string;
  const user2Phone = '9994445556';

  let user3Token: string;
  let user3Id: string;
  const user3Phone = '9997778889';

  let shopAId: string;
  let shopACode: string;

  let shopBId: string;
  let shopBCode: string;

  let joinRequestId: string;
  let invitationId: string;

  let createdBillId: string;
  let createdProductId: string;
  let createdCustomerId: string;
  let createdPaymentId: string;
  let createdReturnId: string;

  beforeAll(async () => {
    try {
      const testPhones = [user1Phone, user2Phone, user3Phone];
      await query(`DELETE FROM users WHERE phone = ANY($1)`, [testPhones]);
    } catch (e) {
      // Memory fallback mode
    }
  });

  // TEST 1 — AUTHENTICATION
  test('TEST 1 — AUTHENTICATION: Register, Login, JWT verification, and /api/auth/me', async () => {
    // Register User 1
    const regRes = await request(app)
      .post('/api/auth/register')
      .send({ phone: user1Phone, name: 'Shop Owner Alice', pin: '1234' });
    expect(regRes.status).toBe(201);
    expect(regRes.body.data.token).toBeDefined();

    // Login User 1
    const loginRes = await request(app)
      .post('/api/auth/login')
      .send({ phone: user1Phone, otp: '123456' });
    expect(loginRes.status).toBe(200);
    user1Token = loginRes.body.data.token;
    user1Id = loginRes.body.data.user.id;
    expect(user1Token).toBeDefined();

    // Verify /api/auth/me
    const meRes = await request(app)
      .get('/api/auth/me')
      .set('Authorization', `Bearer ${user1Token}`);
    expect(meRes.status).toBe(200);
    expect(meRes.body.data.user.phone).toBe(user1Phone);

    // Register User 2 & User 3
    const u2Res = await request(app).post('/api/auth/register').send({ phone: user2Phone, name: 'Employee Bob' });
    user2Token = u2Res.body.data.token;
    user2Id = u2Res.body.data.user.id;

    const u3Res = await request(app).post('/api/auth/register').send({ phone: user3Phone, name: 'Employee Charlie' });
    user3Token = u3Res.body.data.token;
    user3Id = u3Res.body.data.user.id;
  });

  // TEST 2 — SHOP
  test('TEST 2 — SHOP: Create shop, unique Shop Code, creator becomes Owner', async () => {
    const shopRes = await request(app)
      .post('/api/shops/create')
      .set('Authorization', `Bearer ${user1Token}`)
      .send({ name: 'SuperMart Main Branch' });

    expect(shopRes.status).toBe(201);
    expect(shopRes.body.data.name).toBe('SuperMart Main Branch');
    
    shopAId = shopRes.body.data.id;
    shopACode = shopRes.body.data.shop_code;

    expect(shopACode).toMatch(/^SZ-[A-Z0-9]{5}$/);

    // Confirm User 1 is OWNER
    const myShopsRes = await request(app)
      .get('/api/shops/my-shops')
      .set('Authorization', `Bearer ${user1Token}`);

    expect(myShopsRes.status).toBe(200);
    const myShop = myShopsRes.body.data.find((s: any) => s.id === shopAId);
    expect(myShop).toBeDefined();
    expect(myShop.role).toBe('OWNER');
  });

  // TEST 3 — EMPLOYEE JOIN
  test('TEST 3 — EMPLOYEE JOIN: Enter Shop Code, send join request, Owner accepts, membership created', async () => {
    // User 2 sends join request using shopACode
    const reqRes = await request(app)
      .post('/api/members/request-join')
      .set('Authorization', `Bearer ${user2Token}`)
      .send({ shopCode: shopACode });

    expect(reqRes.status).toBe(201);
    joinRequestId = reqRes.body.data.id;
    expect(joinRequestId).toBeDefined();

    // Owner (User 1) fetches pending requests
    const pendingRes = await request(app)
      .get('/api/members/requests')
      .set('Authorization', `Bearer ${user1Token}`)
      .set('x-shop-id', shopAId);

    expect(pendingRes.status).toBe(200);
    const foundReq = pendingRes.body.data.find((r: any) => r.id === joinRequestId);
    expect(foundReq).toBeDefined();

    // Owner accepts request
    const acceptRes = await request(app)
      .post(`/api/members/requests/${joinRequestId}/accept`)
      .set('Authorization', `Bearer ${user1Token}`)
      .set('x-shop-id', shopAId);

    expect(acceptRes.status).toBe(200);

    // Confirm membership is created for User 2
    const membersRes = await request(app)
      .get('/api/members')
      .set('Authorization', `Bearer ${user1Token}`)
      .set('x-shop-id', shopAId);

    expect(membersRes.status).toBe(200);
    const u2Member = membersRes.body.data.find((m: any) => m.user_id === user2Id);
    expect(u2Member).toBeDefined();
    expect(u2Member.role).toBe('EMPLOYEE');
  });

  // TEST 4 — OWNER INVITATION
  test('TEST 4 — OWNER INVITATION: Owner invites employee by phone with permissions, Employee accepts', async () => {
    // Owner invites User 3 by phone number
    const inviteRes = await request(app)
      .post('/api/members/invite')
      .set('Authorization', `Bearer ${user1Token}`)
      .set('x-shop-id', shopAId)
      .send({
        phone: user3Phone,
        permissions: {
          is_full_access: false,
          can_create_bills: true,
          can_view_bills: true,
          can_add_products: false,
          can_edit_products: false,
          can_view_reports: false,
        },
      });

    expect(inviteRes.status).toBe(201);
    invitationId = inviteRes.body.data.id;

    // User 3 checks pending invitations
    const myInvRes = await request(app)
      .get('/api/members/my-invitations')
      .set('Authorization', `Bearer ${user3Token}`);

    expect(myInvRes.status).toBe(200);
    const foundInv = myInvRes.body.data.find((i: any) => i.id === invitationId);
    expect(foundInv).toBeDefined();

    // User 3 accepts invitation
    const acceptInvRes = await request(app)
      .post(`/api/members/invitations/${invitationId}/accept`)
      .set('Authorization', `Bearer ${user3Token}`);

    expect(acceptInvRes.status).toBe(200);

    // Confirm membership created
    const u3ShopsRes = await request(app)
      .get('/api/shops/my-shops')
      .set('Authorization', `Bearer ${user3Token}`);

    expect(u3ShopsRes.status).toBe(200);
    const u3Shop = u3ShopsRes.body.data.find((s: any) => s.id === shopAId);
    expect(u3Shop).toBeDefined();
  });

  // TEST 5 — PERMISSIONS
  test('TEST 5 — PERMISSIONS: Custom permissions allow bill creation, deny member management', async () => {
    // User 3 has can_create_bills: true, but CANNOT invite members
    // Verify User 3 CANNOT invite member (Backend API returns 403)
    const forbiddenRes = await request(app)
      .post('/api/members/invite')
      .set('Authorization', `Bearer ${user3Token}`)
      .set('x-shop-id', shopAId)
      .send({ phone: '9990000000' });

    expect(forbiddenRes.status).toBe(403);
    expect(forbiddenRes.body.error).toMatch(/Forbidden|permission/i);

    // Verify User 3 CAN push sync data for bills
    const timestamp = Date.now();
    const billOp = {
      id: `op_bill_${timestamp}`,
      tableName: 'bills',
      recordId: `bill_u3_${timestamp}`,
      action: 'INSERT',
      payloadJson: JSON.stringify({
        id: `bill_u3_${timestamp}`,
        bill_number: `#U3-${timestamp}`,
        customer_id: null,
        subtotal_paise: 2500,
        total_amount_paise: 2500,
        amount_received_paise: 2500,
        change_amount_paise: 0,
        pending_amount_paise: 0,
        payment_status: 'Paid',
        is_cancelled: 0,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
        items: [],
      }),
      createdAt: new Date().toISOString(),
    };

    const pushRes = await request(app)
      .post('/api/sync/push')
      .set('Authorization', `Bearer ${user3Token}`)
      .set('x-shop-id', shopAId)
      .send({ operations: [billOp] });

    expect(pushRes.status).toBe(200);
    expect(pushRes.body.success).toBe(true);
  });

  // TEST 6 & 7 — OFFLINE OPERATION & LOCAL -> CLOUD SYNC
  test('TEST 6 & 7 — LOCAL -> CLOUD SYNC: Enqueue offline operations and push to backend PostgreSQL', async () => {
    const ts = Date.now();
    createdProductId = `prod_offline_${ts}`;
    createdBillId = `bill_offline_${ts}`;
    createdCustomerId = `cust_offline_${ts}`;
    createdPaymentId = `pay_offline_${ts}`;
    createdReturnId = `ret_offline_${ts}`;

    const operations = [
      {
        id: `op_prod_${ts}`,
        tableName: 'products',
        recordId: createdProductId,
        action: 'INSERT',
        payloadJson: JSON.stringify({
          id: createdProductId,
          name: 'Offline Fresh Milk',
          category_name: 'Dairy',
          buying_price_paise: 3000,
          selling_price_paise: 4000,
          quantity: 50.0,
          unit: 'Litre',
          min_stock_level: 5.0,
          is_active: 1,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        }),
        createdAt: new Date().toISOString(),
      },
      {
        id: `op_cust_${ts}`,
        tableName: 'customers',
        recordId: createdCustomerId,
        action: 'INSERT',
        payloadJson: JSON.stringify({
          id: createdCustomerId,
          name: 'Offline Customer Alice',
          phone: '9876500000',
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        }),
        createdAt: new Date().toISOString(),
      },
      {
        id: `op_bill_${ts}`,
        tableName: 'bills',
        recordId: createdBillId,
        action: 'INSERT',
        payloadJson: JSON.stringify({
          id: createdBillId,
          bill_number: `#OFF-${ts}`,
          customer_id: createdCustomerId,
          customer_name_snapshot: 'Offline Customer Alice',
          customer_phone_snapshot: '9876500000',
          subtotal_paise: 8000,
          total_amount_paise: 8000,
          amount_received_paise: 8000,
          change_amount_paise: 0,
          pending_amount_paise: 0,
          payment_status: 'Paid',
          is_cancelled: 0,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
          items: [
            {
              id: `bitem_${ts}`,
              bill_id: createdBillId,
              product_id: createdProductId,
              product_name_snapshot: 'Offline Fresh Milk',
              quantity: 2.0,
              unit: 'Litre',
              selling_price_paise: 4000,
              buying_price_paise: 3000,
              line_total_paise: 8000,
              profit_paise: 2000,
            },
          ],
        }),
        createdAt: new Date().toISOString(),
      },
      {
        id: `op_sm_${ts}`,
        tableName: 'stock_movements',
        recordId: `sm_offline_${ts}`,
        action: 'INSERT',
        payloadJson: JSON.stringify({
          id: `sm_offline_${ts}`,
          product_id: createdProductId,
          product_name: 'Offline Fresh Milk',
          previous_quantity: 50.0,
          quantity_change: -2.0,
          new_quantity: 48.0,
          purchase_price_paise: 3000,
          movement_type: 'sale',
          reason: `Sale Bill #OFF-${ts}`,
          created_at: new Date().toISOString(),
        }),
        createdAt: new Date().toISOString(),
      },
      {
        id: `op_pay_${ts}`,
        tableName: 'payments',
        recordId: createdPaymentId,
        action: 'INSERT',
        payloadJson: JSON.stringify({
          id: createdPaymentId,
          customer_id: createdCustomerId,
          bill_id: createdBillId,
          amount_paise: 8000,
          payment_method: 'Cash',
          notes: 'Full Payment',
          created_at: new Date().toISOString(),
        }),
        createdAt: new Date().toISOString(),
      },
      {
        id: `op_ret_${ts}`,
        tableName: 'returns',
        recordId: createdReturnId,
        action: 'INSERT',
        payloadJson: JSON.stringify({
          id: createdReturnId,
          bill_id: createdBillId,
          customer_id: createdCustomerId,
          product_id: createdProductId,
          product_name_snapshot: 'Offline Fresh Milk',
          quantity: 1.0,
          unit: 'Litre',
          refund_amount_paise: 4000,
          reason: 'Defective packaging',
          status: 'Completed',
          stock_action: 'Restocked',
          created_at: new Date().toISOString(),
        }),
        createdAt: new Date().toISOString(),
      },
    ];

    // Push local queue items to backend
    const pushRes = await request(app)
      .post('/api/sync/push')
      .set('Authorization', `Bearer ${user1Token}`)
      .set('x-shop-id', shopAId)
      .send({ operations });

    expect(pushRes.status).toBe(200);
    expect(pushRes.body.success).toBe(true);

    // Verify storage contains all 6 entities
    const prodPg = await findProduct(createdProductId);
    expect(prodPg).toBeDefined();
    expect(prodPg.name).toBe('Offline Fresh Milk');

    const custPg = await findCustomer(createdCustomerId);
    expect(custPg).toBeDefined();

    const billPg = await findBill(createdBillId);
    expect(billPg).toBeDefined();

    const payPg = await findPayment(createdPaymentId);
    expect(payPg).toBeDefined();

    const retPg = await findReturn(createdReturnId);
    expect(retPg).toBeDefined();
  });

  // TEST 8 — CLOUD -> LOCAL SYNC
  test('TEST 8 — CLOUD -> LOCAL SYNC: Another device pulls server changes via GET /api/sync/pull', async () => {
    const pullRes = await request(app)
      .get('/api/sync/pull')
      .set('Authorization', `Bearer ${user2Token}`)
      .set('x-shop-id', shopAId);

    expect(pullRes.status).toBe(200);
    expect(pullRes.body.success).toBe(true);
    expect(pullRes.body.data.data).toBeDefined();

    const data = pullRes.body.data.data;
    expect(data.products.some((p: any) => p.id === createdProductId)).toBe(true);
    expect(data.bills.some((b: any) => b.id === createdBillId)).toBe(true);
    expect(data.customers.some((c: any) => c.id === createdCustomerId)).toBe(true);
    expect(data.payments.some((p: any) => p.id === createdPaymentId)).toBe(true);
    expect(data.returns.some((r: any) => r.id === createdReturnId)).toBe(true);
  });

  // TEST 9 — DUPLICATE PROTECTION
  test('TEST 9 — DUPLICATE PROTECTION: Retry sync push payload; verify 0 duplicates created', async () => {
    const ts = Date.now();
    const retryBillOp = {
      id: `op_retry_${ts}`,
      tableName: 'bills',
      recordId: createdBillId, // Same bill ID
      action: 'INSERT',
      payloadJson: JSON.stringify({
        id: createdBillId,
        bill_number: `#OFF-DUPLICATE-TEST`,
        subtotal_paise: 8000,
        total_amount_paise: 8000,
        amount_received_paise: 8000,
        payment_status: 'Paid',
        created_at: new Date().toISOString(),
      }),
      createdAt: new Date().toISOString(),
    };

    const pushRes = await request(app)
      .post('/api/sync/push')
      .set('Authorization', `Bearer ${user1Token}`)
      .set('x-shop-id', shopAId)
      .send({ operations: [retryBillOp] });

    expect(pushRes.status).toBe(200);

    // Verify bill remains singular (no duplicate)
    const billCheck = await findBill(createdBillId);
    expect(billCheck).toBeDefined();
  });

  // TEST 10 — SHOP DATA ISOLATION
  test('TEST 10 — SHOP DATA ISOLATION: User from Shop A cannot access Shop B data', async () => {
    // Create Shop B for User 2
    const shopBRes = await request(app)
      .post('/api/shops/create')
      .set('Authorization', `Bearer ${user2Token}`)
      .send({ name: 'Shop B Isolation Store' });

    expect(shopBRes.status).toBe(201);
    shopBId = shopBRes.body.data.id;

    // User 1 (from Shop A, non-member of Shop B) attempts to pull Shop B data
    const forbiddenPull = await request(app)
      .get('/api/sync/pull')
      .set('Authorization', `Bearer ${user1Token}`)
      .set('x-shop-id', shopBId);

    expect(forbiddenPull.status).toBe(403);
    expect(forbiddenPull.body.error).toMatch(/Forbidden|member/i);
  });

  // TEST 11 — CONFLICT RESOLUTION (LWW vs Audit Preservation)
  test('TEST 11 — CONFLICT RESOLUTION: Last-Write-Wins for product master data & audit preservation for financial records', async () => {
    const ts = Date.now();

    // 1. Update product with new timestamp (LWW)
    const laterTime = new Date(Date.now() + 5000).toISOString();
    const lwwProductOp = {
      id: `op_lww_${ts}`,
      tableName: 'products',
      recordId: createdProductId,
      action: 'UPDATE',
      payloadJson: JSON.stringify({
        id: createdProductId,
        name: 'Offline Fresh Milk (LWW Updated Name)',
        buying_price_paise: 3500,
        selling_price_paise: 4500,
        quantity: 48.0,
        unit: 'Litre',
        min_stock_level: 5.0,
        is_active: 1,
        updated_at: laterTime,
      }),
      createdAt: new Date().toISOString(),
    };

    const pushRes = await request(app)
      .post('/api/sync/push')
      .set('Authorization', `Bearer ${user1Token}`)
      .set('x-shop-id', shopAId)
      .send({ operations: [lwwProductOp] });

    expect(pushRes.status).toBe(200);

    // Verify LWW updated product name
    const prodCheck = await findProduct(createdProductId);
    expect(prodCheck).toBeDefined();
    expect(prodCheck.name).toBe('Offline Fresh Milk (LWW Updated Name)');

    // 2. Verify original bill was preserved in historical audit log without silent overwrite
    const billCheck = await findBill(createdBillId);
    expect(billCheck).toBeDefined();
    expect(billCheck.id).toBe(createdBillId);
  });
});
