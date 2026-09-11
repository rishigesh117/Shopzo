import request from 'supertest';
import app from '../src/app';
import { memoryDb, setUseMemoryDb } from '../src/db';

beforeAll(() => {
  setUseMemoryDb(true);
});

beforeEach(() => {
  memoryDb.clear();
});

describe('User Authentication API', () => {
  it('should register a new owner user successfully', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({
        name: 'Rishi G',
        mobileNumber: '9876543210',
        password: 'password123'
      });

    expect(res.status).toBe(201);
    expect(res.body).toHaveProperty('token');
    expect(res.body.user).toHaveProperty('id');
    expect(res.body.user.mobileNumber).toBe('9876543210');
  });

  it('should prevent registering duplicate mobile number', async () => {
    await request(app).post('/api/auth/register').send({
      name: 'User 1',
      mobileNumber: '9876543210',
      password: 'pass'
    });

    const res = await request(app).post('/api/auth/register').send({
      name: 'User 2',
      mobileNumber: '9876543210',
      password: 'pass'
    });

    expect(res.status).toBe(409);
    expect(res.body.error).toMatch(/already exists/i);
  });

  it('should login registered user with mobile and password', async () => {
    await request(app).post('/api/auth/register').send({
      name: 'Rishi G',
      mobileNumber: '9876543210',
      password: 'password123'
    });

    const res = await request(app).post('/api/auth/login').send({
      mobileNumber: '9876543210',
      password: 'password123'
    });

    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('token');
    expect(res.body.user.name).toBe('Rishi G');
  });

  it('should reject login with wrong password', async () => {
    await request(app).post('/api/auth/register').send({
      name: 'Rishi G',
      mobileNumber: '9876543210',
      password: 'password123'
    });

    const res = await request(app).post('/api/auth/login').send({
      mobileNumber: '9876543210',
      password: 'wrongpassword'
    });

    expect(res.status).toBe(401);
    expect(res.body.error).toMatch(/incorrect mobile number or password/i);
  });
});
