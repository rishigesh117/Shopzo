import request from 'supertest';
import app from '../src/app';
import { memoryDb, setUseMemoryDb } from '../src/db';

beforeAll(() => {
  setUseMemoryDb(true);
});

beforeEach(() => {
  memoryDb.clear();
});

describe('Offline ↔ Online Synchronization API & Idempotency', () => {
  let token: string;
  let shopId: string;

  beforeEach(async () => {
    const regRes = await request(app).post('/api/auth/register').send({
      name: 'Owner Rishi',
      mobileNumber: '9999999999',
      password: 'ownerpassword'
    });
    token = regRes.body.token;

    const shopRes = await request(app)
      .post('/api/shops')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Sync Supermarket' });
    shopId = shopRes.body.shop.id;
  });

  it('should process push sync batch operations cleanly', async () => {
    const operations = [
      {
        id: 'q-101',
        entityType: 'CATEGORY',
        entityId: 'cat-uuid-1',
        operationType: 'CREATE',
        shopId,
        createdAt: Date.now(),
        payload: { name: 'Beverages', deleted: false }
      },
      {
        id: 'q-102',
        entityType: 'PRODUCT',
        entityId: 'prod-uuid-1',
        operationType: 'CREATE',
        shopId,
        createdAt: Date.now(),
        payload: {
          name: 'Fruit Juice 1L',
          categoryId: 'cat-uuid-1',
          buyingPricePaise: 8000,
          sellingPricePaise: 12000,
          quantity: 50,
          unit: 'PCS'
        }
      }
    ];

    const res = await request(app)
      .post('/api/sync/push')
      .set('Authorization', `Bearer ${token}`)
      .set('X-Shop-Id', shopId)
      .send({ shopId, operations });

    expect(res.status).toBe(200);
    expect(res.body.syncedIds).toEqual(['q-101', 'q-102']);
    expect(memoryDb.products.get('prod-uuid-1').name).toBe('Fruit Juice 1L');
  });

  it('should prevent duplicate financial transactions when identical bill UUID is pushed twice', async () => {
    const billOperation = {
      id: 'q-201',
      entityType: 'BILL',
      entityId: 'bill-uuid-999',
      operationType: 'CREATE',
      shopId,
      createdAt: Date.now(),
      payload: {
        billNumber: '#1001',
        subtotalPaise: 5000,
        grandTotalPaise: 5000,
        paidAmountPaise: 5000,
        pendingAmountPaise: 0,
        paymentStatus: 'PAID'
      }
    };

    // First Push
    const res1 = await request(app)
      .post('/api/sync/push')
      .set('Authorization', `Bearer ${token}`)
      .set('X-Shop-Id', shopId)
      .send({ shopId, operations: [billOperation] });
    expect(res1.body.syncedIds).toContain('q-201');

    // Duplicate Retry Push with identical bill UUID
    const res2 = await request(app)
      .post('/api/sync/push')
      .set('Authorization', `Bearer ${token}`)
      .set('X-Shop-Id', shopId)
      .send({ shopId, operations: [{ ...billOperation, id: 'q-201-retry' }] });

    expect(res2.status).toBe(200);
    expect(res2.body.syncedIds).toContain('q-201-retry');

    // Verify exactly 1 bill exists in database store
    const billsForShop = Array.from(memoryDb.bills.values()).filter(b => b.shopId === shopId);
    expect(billsForShop.length).toBe(1);
    expect(billsForShop[0].id).toBe('bill-uuid-999');
  });

  it('should pull delta changes updated after since timestamp', async () => {
    const now = Date.now();

    // Insert data into store
    memoryDb.categories.set('cat-1', { id: 'cat-1', shopId, name: 'Dairy', updatedAt: now });

    const pullRes = await request(app)
      .get(`/api/sync/pull?since=${now - 1000}`)
      .set('Authorization', `Bearer ${token}`)
      .set('X-Shop-Id', shopId);

    expect(pullRes.status).toBe(200);
    expect(pullRes.body.delta.categories.length).toBe(1);
    expect(pullRes.body.delta.categories[0].name).toBe('Dairy');
  });
});
