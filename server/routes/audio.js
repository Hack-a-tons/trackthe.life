const express = require('express');
const multer = require('multer');
const telnyx = require('../services/telnyxClient');
const aperturedb = require('../services/aperturedbClient');
const memmachine = require('../services/memmachineClient');
const comet = require('../services/cometClient');
const geoip = require('../services/geoipClient');

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage() });

router.post('/audio', upload.single('file'), async (req, res) => {
  const startTime = Date.now();
  
  try {
    const { user_id, timestamp, media_id } = req.body;
    
    if (!req.file || !user_id || !timestamp) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Get client IP
    const clientIp = req.headers['x-forwarded-for']?.split(',')[0] || 
                     req.headers['x-real-ip'] || 
                     req.connection.remoteAddress || 
                     req.socket.remoteAddress;

    // Lookup IP geolocation
    const ipLocation = await geoip.lookup(clientIp);

    const transcription = await telnyx.transcribe(req.file.buffer, req.file.originalname);
    
    let memoryText = `User ${user_id} said: "${transcription.text}" at ${timestamp}`;
    if (ipLocation) {
      memoryText += ` from ${ipLocation.city}, ${ipLocation.regionName}, ${ipLocation.country}`;
    }
    
    await memmachine.addMemory(user_id, memoryText);
    
    await comet.logTrace('audio_transcription', {
      duration: Date.now() - startTime,
      user_id,
      text_length: transcription.text.length,
      has_ip_location: !!ipLocation
    });

    res.json({
      status: 'ok',
      transcription: transcription.text,
      timestamps: transcription.timestamps,
      ipLocation: ipLocation ? {
        city: ipLocation.city,
        region: ipLocation.regionName,
        country: ipLocation.country
      } : null
    });
  } catch (error) {
    console.error('Audio upload error:', error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
