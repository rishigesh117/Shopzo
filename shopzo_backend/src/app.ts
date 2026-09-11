import express from 'express';
import cors from 'cors';
import authRoutes from './routes/authRoutes';
import shopRoutes from './routes/shopRoutes';
import staffRoutes from './routes/staffRoutes';
import productRoutes from './routes/productRoutes';
import syncRoutes from './routes/syncRoutes';

const app = express();

app.use(cors());
app.use(express.json());

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/shops', shopRoutes);
app.use('/api/shops/:shopId/staff', staffRoutes);
app.use('/api/shops/:shopId/products', productRoutes);
app.use('/api/sync', syncRoutes);

// Healthcheck
app.get('/health', (req, res) => {
  res.json({ status: 'OK', message: 'SHOPZO Cloud Backend API operational' });
});

// Global 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

export default app;
