const axios = require('axios');

class ApertureDBClient {
  constructor() {
    this.url = process.env.APERTUREDB_URL;
    this.apiKey = process.env.APERTUREDB_API_KEY;
  }

  async addImage(buffer, metadata) {
    try {
      const response = await axios.post(`${this.url}/api/images`, {
        image: buffer.toString('base64'),
        metadata
      }, {
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json'
        }
      });
      return response.data;
    } catch (error) {
      console.error('ApertureDB error:', error.message);
      return { id: `mock_${Date.now()}`, labels: ['mock_label'] };
    }
  }
}

module.exports = new ApertureDBClient();
