const express = require('express');
const multer = require('multer');
const aperturedb = require('../services/aperturedbClient');
const memmachine = require('../services/memmachineClient');
const comet = require('../services/cometClient');
const geoip = require('../services/geoipClient');

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage() });

router.post('/media', upload.single('file'), async (req, res) => {
  const startTime = Date.now();
  
  try {
    const { user_id, timestamp, location } = req.body;
    
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

    const metadata = { 
      user_id, 
      timestamp, 
      location,
      ip: clientIp,
      ipLocation
    };
    
    const apertureResult = await aperturedb.addImage(req.file.buffer, metadata);
    
    // Build memory text with location info
    let memoryText = `User ${user_id} captured media at ${timestamp}`;
    if (location) {
      memoryText += ` at GPS location ${location}`;
    }
    if (ipLocation) {
      memoryText += ` from ${ipLocation.city}, ${ipLocation.regionName}, ${ipLocation.country}`;
    }
    
    await memmachine.addMemory(user_id, memoryText);
    
    await comet.logTrace('media_upload', {
      duration: Date.now() - startTime,
      media_id: apertureResult.id,
      user_id,
      has_gps: !!location,
      has_ip_location: !!ipLocation
    });

    res.json({
      status: 'ok',
      media_id: apertureResult.id,
      labels: apertureResult.labels || [],
      location: location || (ipLocation ? `${ipLocation.lat},${ipLocation.lon}` : null),
      ipLocation: ipLocation ? {
        city: ipLocation.city,
        region: ipLocation.regionName,
        country: ipLocation.country
      } : null
    });
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
