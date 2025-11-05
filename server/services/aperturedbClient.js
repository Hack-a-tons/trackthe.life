const axios = require('axios');
const fs = require('fs').promises;
const path = require('path');

class ApertureDBClient {
  constructor() {
    // Use Azure Computer Vision instead of ApertureDB
    this.azureEndpoint = process.env.AZURE_OPENAI_ENDPOINT?.replace('/openai', '');
    this.azureKey = process.env.AZURE_OPENAI_API_KEY;
    this.storageDir = path.join(__dirname, '../../uploads');
    this.initStorage();
  }

  async initStorage() {
    try {
      await fs.mkdir(this.storageDir, { recursive: true });
    } catch (error) {
      console.error('[Storage] Init error:', error.message);
    }
  }

  async analyzeImage(buffer) {
    if (!this.azureEndpoint || !this.azureKey) {
      console.log('[Vision] Azure not configured, using mock data');
      return { description: 'person, indoor, furniture', tags: ['person', 'indoor', 'furniture'] };
    }

    try {
      const url = `${this.azureEndpoint}/vision/v3.2/analyze?visualFeatures=Description,Tags,Objects`;
      
      const response = await axios.post(url, buffer, {
        headers: {
          'Ocp-Apim-Subscription-Key': this.azureKey,
          'Content-Type': 'application/octet-stream'
        },
        timeout: 15000
      });

      const description = response.data.description?.captions?.[0]?.text || 'No description';
      const tags = response.data.tags?.map(t => t.name).slice(0, 5) || [];
      const objects = response.data.objects?.map(o => o.object) || [];

      console.log('[Vision] Analysis successful:', { description, tags: tags.length, objects: objects.length });
      
      return {
        description,
        tags: [...new Set([...tags, ...objects])],
        confidence: response.data.description?.captions?.[0]?.confidence
      };
    } catch (error) {
      console.error('[Vision] Error:', error.response?.data || error.message);
      return { description: 'Analysis failed', tags: ['unknown'] };
    }
  }

  async addImage(buffer, metadata) {
    const mediaId = `adb_${Date.now()}`;
    const filename = `${mediaId}.jpg`;
    const filepath = path.join(this.storageDir, filename);
    
    try {
      // Store locally
      await fs.writeFile(filepath, buffer);
      console.log('[Storage] Image stored:', filepath);
      
      // Analyze with Azure Computer Vision
      const analysis = await this.analyzeImage(buffer);
      
      return { 
        id: mediaId,
        labels: analysis.tags,
        description: analysis.description,
        confidence: analysis.confidence,
        stored_locally: true,
        filepath
      };
    } catch (error) {
      console.error('[Storage] Error:', error.message);
      return { 
        id: mediaId,
        labels: ['error'],
        description: 'Storage failed'
      };
    }
  }

  async query(queryObj) {
    console.log('[Query] Not implemented for local storage');
    return null;
  }
}

module.exports = new ApertureDBClient();
