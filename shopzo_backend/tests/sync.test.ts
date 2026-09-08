import request from 'supertest';
import app from '../src/app';

describe('Two-Way Sync Engine API', () => {
  let token: string;
  let shopId: string;

  beforeAll(async () => {
    const regRes = await request(app)
      .post('/api/auth/register')
      .send({ phone: '9555544444', name: 'Sync User' });
    token = regRes.body.data.token;

    const shopRes = await request(app)
      .post('/api/shops/create')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Sync Test Shop' });
    shopId = shopRes.body.data.id;
  });

  it('should push queued local operations to server idempotently', async () => {
    const pushRes = await request(app)
      .post('/api/sync/push')
      .set('Authorization', `Bearer ${token}`)
      .set('x-shop-id', shopId)
      .send({
        operations: [
          {
            id: 'op_1',
            tableName: 'products',
            recordId: 'prod_sync_1',
            action: 'INSERT',
            payloadJson: JSON.stringify({
              id: 'prod_sync_1',
              name: 'Sync Item Tea',
              category_id: 'cat_1',
              category_name: 'Beverages',
              brand: 'Taj Mahal',
              buying_price_paise: 5000,
              selling_price_paise: 7000,
              quantity: 20,
              unit: 'Packet',
              min_stock_level: 5,
              is_active: 1
            }),
            createdAt: new Date().toISOString()
          },
          {
            id: 'op_2',
            tableName: 'bills',
            recordId: 'bill_sync_1',
            action: 'INSERT',
            payloadJson: JSON.stringify({
              id: 'bill_sync_1',
              bill_number: 'BILL-1001',
              subtotal_paise: 7000,
              total_amount_paise: 7000,
              amount_received_paise: 10000,
              change_amount_paise: 3000,
              pending_amount_paise: 0,
              payment_status: 'PAID',
              is_cancelled: 0,
              items: [
                {
                  id: 'bi_1',
                  product_id: 'prod_sync_1',
                  product_name_snapshot: 'Sync Item Tea',
                  quantity: 1,
                  unit: 'Packet',
                  selling_price_paise: 7000,
                  buying_price_paise: 5000,
                  line_total_paise: 7000,
                  profit_paise: 2000
                }
              ]
            }),
            createdAt: new Date().toISOString()
          }
        ]
      });

    expect(pushRes.status).toBe(200);
    expect(pushRes.body.success).toBe(true);
    expect(pushRes.body.data.processedCount).toBe(2);
    expect(pushRes.body.data.failedCount).toBe(0);
  });

  it('should pull synchronized remote changes from server', async () => {
    const pullRes = await request(app)
      .get('/api/sync/pull')
      .set('Authorization', `Bearer ${token}`)
      .set('x-shop-id', shopId);

    expect(pullRes.status).toBe(200);
    expect(pullRes.body.success).toBe(true);
    expect(pullRes.body.data.data.products.length).toBeGreaterThan(0);
    expect(pullRes.body.data.data.bills.length).toBeGreaterThan(0);
  });
});
