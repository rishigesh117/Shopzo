import { v4 as uuidv4 } from 'uuid';

export const generateShopCode = (): string => {
  const characters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Avoid ambiguous chars (I, O, 0, 1)
  let code = 'SZ-';
  for (let i = 0; i < 5; i++) {
    const randomIndex = Math.floor(Math.random() * characters.length);
    code += characters[randomIndex];
  }
  return code;
};

export const generateUuid = (): string => {
  return uuidv4();
};
