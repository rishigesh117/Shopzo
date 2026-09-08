import request from 'supertest';
import app from '../src/app';

describe('Shop Management API', () => {
  let token: string;
  let shopCode: string;

  beforeAll(async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({ phone: '9123456780', name: 'Shop Owner 2' });
    token = res.body.data.token;
  });

  it('should create a new shop with unique shop code', async () => {
    const res = await request(app)
      .post('/api/shops/create')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'SuperMart Chennai' });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.id).toBeDefined();
    expect(res.body.data.shop_code).toBeDefined();
    expect(res.body.data.shop_code.length).toBeGreaterThanOrEqual(6);
    shopCode = res.body.data.shop_code;
  });

  it('should list shops for user', async () => {
    const res = await request(app)
      .get('/api/shops/my-shops')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.length).toBeGreaterThan(0);
  });

  it('should find shop by code', async () => {
    const res = await request(app)
      .get(`/api/shops/by-code/${shopCode}`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.name).toBe('SuperMart Chennai');
  });
});
