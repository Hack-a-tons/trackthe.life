const axios = require('axios');
const fs = require('fs').promises;
const path = require('path');
const { exec } = require('child_process');
const { promisify } = require('util');

const execAsync = promisify(exec);

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

  async extractVideoFrame(videoPath) {
    const framePath = videoPath.replace(/\.(mp4|mov|avi)$/i, '_frame.jpg');
    try {
      await execAsync(`ffmpeg -i "${videoPath}" -vframes 1 -f image2 "${framePath}" -y`);
      const frameBuffer = await fs.readFile(framePath);
      await fs.unlink(framePath); // Clean up
      return frameBuffer;
    } catch (error) {
      console.error('[Video] Frame extraction failed:', error.message);
      return null;
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

  async analyzeVideo(videoPath) {
    console.log('[Vision] Extracting frame from video...');
    const frameBuffer = await this.extractVideoFrame(videoPath);
    if (frameBuffer) {
      return this.analyzeImage(frameBuffer);
    }
    return { description: 'Video analysis failed', tags: ['video'] };
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

  async addVideo(buffer, metadata) {
    const mediaId = `vid_${Date.now()}`;
    const filename = `${mediaId}.mp4`;
    const filepath = path.join(this.storageDir, filename);
    
    try {
      // Store locally
      await fs.writeFile(filepath, buffer);
      console.log('[Storage] Video stored:', filepath);
      
      // Extract frame and analyze
      const analysis = await this.analyzeVideo(filepath);
      
      return { 
        id: mediaId,
        labels: analysis.tags,
        description: analysis.description,
        confidence: analysis.confidence,
        stored_locally: true,
        filepath,
        type: 'video'
      };
    } catch (error) {
      console.error('[Storage] Error:', error.message);
      return { 
        id: mediaId,
        labels: ['error'],
        description: 'Storage failed',
        type: 'video'
      };
    }
  }

  async query(queryObj) {
    console.log('[Query] Not implemented for local storage');
    return null;
  }
}

module.exports = new ApertureDBClient();
