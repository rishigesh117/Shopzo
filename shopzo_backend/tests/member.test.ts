import request from 'supertest';
import app from '../src/app';

describe('Member & Invitation Management API', () => {
  let ownerToken: string;
  let employeeToken: string;
  let shopId: string;
  let shopCode: string;
  let requestId: string;
  let invitationId: string;
  const employeePhone = '9988776655';

  beforeAll(async () => {
    // Owner setup
    const ownerRes = await request(app)
      .post('/api/auth/register')
      .send({ phone: '9888877777', name: 'Owner User' });
    ownerToken = ownerRes.body.data.token;

    const shopRes = await request(app)
      .post('/api/shops/create')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ name: 'Member Test Shop' });
    shopId = shopRes.body.data.id;
    shopCode = shopRes.body.data.shop_code;

    // Employee setup
    const empRes = await request(app)
      .post('/api/auth/register')
      .send({ phone: employeePhone, name: 'Employee User' });
    employeeToken = empRes.body.data.token;
  });

  it('employee should request to join shop using shop code', async () => {
    const res = await request(app)
      .post('/api/members/request-join')
      .set('Authorization', `Bearer ${employeeToken}`)
      .send({ shopCode });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.status).toBe('PENDING');
    requestId = res.body.data.id;
  });

  it('owner should list pending join requests and accept it', async () => {
    const listRes = await request(app)
      .get('/api/members/requests')
      .set('Authorization', `Bearer ${ownerToken}`)
      .set('x-shop-id', shopId);

    expect(listRes.status).toBe(200);
    expect(listRes.body.data.length).toBeGreaterThan(0);

    const acceptRes = await request(app)
      .post(`/api/members/requests/${requestId}/accept`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .set('x-shop-id', shopId)
      .send({ permissions: { is_full_access: false, can_create_bills: true } });

    expect(acceptRes.status).toBe(200);
    expect(acceptRes.body.success).toBe(true);
  });

  it('owner should invite an employee via phone number', async () => {
    const res = await request(app)
      .post('/api/members/invite')
      .set('Authorization', `Bearer ${ownerToken}`)
      .set('x-shop-id', shopId)
      .send({
        phone: '9777766666',
        permissions: { is_full_access: true }
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    invitationId = res.body.data.id;
  });

  it('owner cannot be demoted or removed (Owner Protection)', async () => {
    const meRes = await request(app)
      .get('/api/auth/me')
      .set('Authorization', `Bearer ${ownerToken}`);
    const ownerId = meRes.body.data.user.id;

    const removeRes = await request(app)
      .delete(`/api/members/${ownerId}`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .set('x-shop-id', shopId);

    expect(removeRes.status).toBe(400);
    expect(removeRes.body.success).toBe(false);
  });
});
