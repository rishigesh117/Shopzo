import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'shopzo_super_secret_jwt_key_2026';

export interface TokenPayload {
  userId: string;
  phone: string;
}

export const generateToken = (payload: TokenPayload): string => {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: '30d' });
};

export const verifyToken = (token: string): TokenPayload => {
  return jwt.verify(token, JWT_SECRET) as TokenPayload;
};
