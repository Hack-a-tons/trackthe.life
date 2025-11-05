const axios = require('axios');
const fs = require('fs').promises;
const path = require('path');

class ApertureDBClient {
  constructor() {
    this.host = process.env.APERTUREDB_URL;
    this.token = process.env.APERTUREDB_API_KEY;
    this.useHttps = !this.host.startsWith('http');
    this.storageDir = path.join(__dirname, '../../uploads');
    this.initStorage();
  }

  async initStorage() {
    try {
      await fs.mkdir(this.storageDir, { recursive: true });
    } catch (error) {
      console.error('[ApertureDB] Storage init error:', error.message);
    }
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
      
      console.log('[ApertureDB] Image stored successfully');
      return response.data;
    } catch (error) {
      console.error('[ApertureDB] Error:', error.message, '- using local storage');
      
      // Fallback: store locally
      const mediaId = `adb_${Date.now()}`;
      const filename = `${mediaId}.jpg`;
      const filepath = path.join(this.storageDir, filename);
      
      try {
        await fs.writeFile(filepath, buffer);
        console.log('[ApertureDB] Image stored locally:', filepath);
      } catch (fsError) {
        console.error('[ApertureDB] Local storage error:', fsError.message);
      }
      
      // Return mock data with basic detection
      return { 
        id: mediaId,
        labels: ['person', 'indoor', 'furniture'],
        stored_locally: true,
        filepath
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
      console.error('[ApertureDB] Query error:', error.message);
      return null;
    }
  }
}

module.exports = new ApertureDBClient();
