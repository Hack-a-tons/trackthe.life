require('dotenv').config();
const express = require('express');
const mediaRoutes = require('./routes/media');

const app = express();
const PORT = process.env.PORT || 4000;

app.use(express.json());

// Routes
app.use('/api', mediaRoutes);

// Health check
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    services: ['ApertureDB', 'MemMachine', 'Telnyx', 'Comet'] 
  });
});

app.listen(PORT, () => {
  console.log(`trackthe.life server running on port ${PORT}`);
});
