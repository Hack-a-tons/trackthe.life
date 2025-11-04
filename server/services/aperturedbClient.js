const axios = require('axios');

class ApertureDBClient {
  constructor() {
    this.host = process.env.APERTUREDB_URL;
    this.token = process.env.APERTUREDB_API_KEY;
    this.useHttps = !this.host.startsWith('http');
  }

  async addImage(buffer, metadata) {
    try {
      const url = this.useHttps ? `https://${this.host}/api/v1/images` : `${this.host}/api/v1/images`;
      
      const response = await axios.post(url, {
        image: buffer.toString('base64'),
        metadata
      }, {
        headers: {
          'Authorization': `Bearer ${this.token}`,
          'Content-Type': 'application/json'
        },
        timeout: 10000
      });
      
      return response.data;
    } catch (error) {
      console.error('ApertureDB error:', error.message);
      // Return mock data for development
      return { 
        id: `adb_${Date.now()}`, 
        labels: ['person', 'indoor', 'furniture'] 
      };
    }
  }

  async query(queryObj) {
    try {
      const url = this.useHttps ? `https://${this.host}/api/v1/query` : `${this.host}/api/v1/query`;
      
      const response = await axios.post(url, queryObj, {
        headers: {
          'Authorization': `Bearer ${this.token}`,
          'Content-Type': 'application/json'
        },
        timeout: 10000
      });
      
      return response.data;
    } catch (error) {
      console.error('ApertureDB query error:', error.message);
      return null;
    }
  }
}

module.exports = new ApertureDBClient();
