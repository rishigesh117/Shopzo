import app from './app';
import dotenv from 'dotenv';

dotenv.config();

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`=================================`);
  console.log(`  SHOPZO Cloud Backend API       `);
  console.log(`  Listening on port ${PORT}      `);
  console.log(`=================================`);
});
