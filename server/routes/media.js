const express = require('express');
const multer = require('multer');
const aperturedb = require('../services/aperturedbClient');
const memmachine = require('../services/memmachineClient');
const comet = require('../services/cometClient');

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage() });

router.post('/media', upload.single('file'), async (req, res) => {
  const startTime = Date.now();
  
  try {
    const { user_id, timestamp, location } = req.body;
    
    if (!req.file || !user_id || !timestamp) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const metadata = { user_id, timestamp, location };
    
    const apertureResult = await aperturedb.addImage(req.file.buffer, metadata);
    
    const memoryText = `User ${user_id} captured media at ${timestamp}${location ? ` at location ${location}` : ''}`;
    await memmachine.addMemory(user_id, memoryText);
    
    await comet.logTrace('media_upload', {
      duration: Date.now() - startTime,
      media_id: apertureResult.id,
      user_id
    });

    res.json({
      status: 'ok',
      media_id: apertureResult.id,
      labels: apertureResult.labels || []
    });
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
