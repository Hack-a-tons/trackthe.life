const axios = require('axios');
const FormData = require('form-data');

class TelnyxClient {
  constructor() {
    // Try Azure OpenAI first, fallback to OpenAI
    this.useAzure = !!process.env.AZURE_OPENAI_ENDPOINT;
    
    if (this.useAzure) {
      this.apiKey = process.env.AZURE_OPENAI_API_KEY;
      this.baseUrl = `${process.env.AZURE_OPENAI_ENDPOINT}/openai/deployments/whisper/audio/transcriptions?api-version=2024-02-01`;
    } else {
      this.apiKey = process.env.OPENAI_API_KEY;
      this.baseUrl = 'https://api.openai.com/v1/audio/transcriptions';
    }
  }

  async transcribe(audioBuffer, filename) {
    try {
      const formData = new FormData();
      formData.append('file', audioBuffer, filename);
      
      const headers = this.useAzure 
        ? { 'api-key': this.apiKey, ...formData.getHeaders() }
        : { 'Authorization': `Bearer ${this.apiKey}`, ...formData.getHeaders() };

      const response = await axios.post(this.baseUrl, formData, { headers });

      console.log('[Whisper] Transcription successful:', {
        provider: this.useAzure ? 'Azure' : 'OpenAI',
        text_length: response.data.text?.length,
        duration: response.data.duration,
        language: response.data.language
      });

      return {
        text: response.data.text,
        timestamps: response.data.words || response.data.segments || []
      };
    } catch (error) {
      console.error('[Whisper] Error:', error.response?.data || error.message);
      return {
        text: 'Mock transcription: This is a test audio file.',
        timestamps: []
      };
    }
  }
}

module.exports = new TelnyxClient();
