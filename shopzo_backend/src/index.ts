import app from './app';
import dotenv from 'dotenv';
import { runMigrations } from './db/migrations';

dotenv.config();

const PORT = process.env.PORT || 3000;

const startServer = async () => {
  try {
    console.log('[SHOPZO Backend] Running database migrations...');
    await runMigrations();
  } catch (err) {
    console.warn('[SHOPZO Backend] Database migration warning (running in hybrid/standalone mode):', (err as Error).message);
  }

  app.listen(PORT, () => {
    console.log(`[SHOPZO Backend] Server is running on port ${PORT}`);
  });
};

startServer();
