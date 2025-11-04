const express = require('express');
const multer = require('multer');
const telnyx = require('../services/telnyxClient');
const aperturedb = require('../services/aperturedbClient');
const memmachine = require('../services/memmachineClient');
const comet = require('../services/cometClient');

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage() });

router.post('/audio', upload.single('file'), async (req, res) => {
  const startTime = Date.now();
  
  try {
    const { user_id, timestamp, media_id } = req.body;
    
    if (!req.file || !user_id || !timestamp) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const transcription = await telnyx.transcribe(req.file.buffer, req.file.originalname);
    
    const memoryText = `User ${user_id} said: "${transcription.text}" at ${timestamp}`;
    await memmachine.addMemory(user_id, memoryText);
    
    await comet.logTrace('audio_transcription', {
      duration: Date.now() - startTime,
      user_id,
      text_length: transcription.text.length
    });

    res.json({
      status: 'ok',
      transcription: transcription.text,
      timestamps: transcription.timestamps
    });
  } catch (error) {
    console.error('Audio upload error:', error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
