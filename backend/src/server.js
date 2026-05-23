const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Only load routes that have content
app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/user', require('./routes/userRoutes'));
app.use('/api/exercises', require('./routes/exerciseRoutes'));
app.use('/api/categories', require('./routes/categoryRoutes'));
app.use('/api/progress', require('./routes/progressRoutes'));
app.use('/api/health', require('./routes/healthRoutes'));
app.use('/api/products', require('./routes/productRoutes'));
app.use('/api/announcements', require('./routes/announcementRoutes'));
app.use('/api/admin', require('./routes/adminRoutes'));
app.use('/api/dashboard', require('./routes/dashboardRoutes'));
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

module.exports = app;