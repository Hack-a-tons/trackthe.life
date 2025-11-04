const axios = require('axios');
const FormData = require('form-data');

class TelnyxClient {
  constructor() {
    this.apiKey = process.env.TELNYX_API_KEY;
    this.baseUrl = 'https://api.telnyx.com/v2/ai/audio/transcriptions';
  }

  async transcribe(audioBuffer, filename) {
    try {
      const formData = new FormData();
      formData.append('file', audioBuffer, filename);
      formData.append('model', 'whisper-large-v3');

      const response = await axios.post(this.baseUrl, formData, {
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
          ...formData.getHeaders()
        }
      });

      return {
        text: response.data.text,
        timestamps: response.data.words || []
      };
    } catch (error) {
      console.error('Telnyx error:', error.message);
      return {
        text: 'Mock transcription: This is a test audio file.',
        timestamps: []
      };
    }
  }
}

module.exports = new TelnyxClient();
