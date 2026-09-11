import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'shopzo_super_secret_jwt_key_phase3_2026';
const SALT_ROUNDS = 10;

export interface TokenPayload {
  userId: string;
  mobileNumber: string;
  name: string;
}

export async function hashPassword(password: string): Promise<string> {
  return await bcrypt.hash(password, SALT_ROUNDS);
}

export async function comparePassword(password: string, hash: string): Promise<boolean> {
  return await bcrypt.compare(password, hash);
}

export function generateToken(payload: TokenPayload): string {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: '30d' });
}

export function verifyToken(token: string): TokenPayload {
  return jwt.verify(token, JWT_SECRET) as TokenPayload;
}

export function generateShopCode(): string {
  // Format: SZ-XXXXXX (e.g. SZ-482913)
  const randomDigits = Math.floor(100000 + Math.random() * 900000);
  return `SZ-${randomDigits}`;
}
