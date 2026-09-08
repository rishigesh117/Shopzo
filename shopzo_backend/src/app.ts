import express from 'express';
import cors from 'cors';
import authRoutes from './routes/authRoutes';
import shopRoutes from './routes/shopRoutes';
import memberRoutes from './routes/memberRoutes';
import syncRoutes from './routes/syncRoutes';

const app = express();

app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Security Headers Middleware
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
  next();
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', service: 'shopzo_backend', timestamp: new Date().toISOString() });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/shops', shopRoutes);
app.use('/api/members', memberRoutes);
app.use('/api/sync', syncRoutes);

// Global 404
app.use((req, res) => {
  res.status(404).json({ success: false, error: 'Endpoint not found' });
});

// Global Sanitized Error Handler
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error('[Backend Error]', err);
  const isProd = process.env.NODE_ENV === 'production';
  const errorMessage = isProd ? 'Internal Server Error' : (err.message || 'Internal Server Error');
  res.status(err.status || 500).json({ success: false, error: errorMessage });
});

export default app;
