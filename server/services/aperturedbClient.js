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

  async extractVideoAudio(videoPath) {
    const audioPath = videoPath.replace(/\.(mp4|mov|avi)$/i, '.wav');
    try {
      await execAsync(`ffmpeg -i "${videoPath}" -vn -acodec pcm_s16le -ar 16000 -ac 1 "${audioPath}" -y`);
      const audioBuffer = await fs.readFile(audioPath);
      await fs.unlink(audioPath); // Clean up
      return audioBuffer;
    } catch (error) {
      console.error('[Video] Audio extraction failed:', error.message);
      return null;
    }
  }

  async analyzeImage(buffer) {
    if (!this.azureEndpoint || !this.azureKey) {
      console.log('[Vision] Azure not configured, using mock data');
      return { description: 'person, indoor, furniture', tags: ['person', 'indoor', 'furniture'] };
    }

    try {
      const url = `${this.azureEndpoint}/vision/v3.2/analyze?visualFeatures=Description,Tags,Objects,Faces,Categories,Color,ImageType`;
      
      const response = await axios.post(url, buffer, {
        headers: {
          'Ocp-Apim-Subscription-Key': this.azureKey,
          'Content-Type': 'application/octet-stream'
        },
        timeout: 15000
      });

      const caption = response.data.description?.captions?.[0]?.text || 'No description';
      const tags = response.data.tags?.map(t => t.name).slice(0, 10) || [];
      const objects = response.data.objects?.map(o => `${o.object} (${Math.round(o.confidence * 100)}%)`).slice(0, 5) || [];
      const faces = response.data.faces?.length || 0;
      const categories = response.data.categories?.map(c => c.name).slice(0, 3) || [];
      const colors = response.data.color?.dominantColors?.slice(0, 3) || [];

      // Build detailed description
      let detailedDesc = caption;
      if (faces > 0) detailedDesc += `. ${faces} person${faces > 1 ? 's' : ''} detected`;
      if (objects.length > 0) detailedDesc += `. Objects: ${objects.join(', ')}`;
      if (colors.length > 0) detailedDesc += `. Colors: ${colors.join(', ')}`;

      console.log('[Vision] Analysis successful:', { description: detailedDesc, tags: tags.length, faces, objects: objects.length });
      
      return {
        description: detailedDesc,
        tags: [...new Set([...tags, ...response.data.objects?.map(o => o.object) || []])],
        confidence: response.data.description?.captions?.[0]?.confidence,
        faces,
        objects: response.data.objects || [],
        categories
      };
    } catch (error) {
      console.error('[Vision] Error:', error.response?.data || error.message);
      return { description: 'Analysis failed', tags: ['unknown'] };
    }
  }

  async analyzeVideo(videoPath) {
    console.log('[Vision] Extracting frame from video...');
    const frameBuffer = await this.extractVideoFrame(videoPath);
    
    console.log('[Audio] Extracting audio from video...');
    const audioBuffer = await this.extractVideoAudio(videoPath);
    
    let result = { description: 'Video analysis failed', tags: ['video'] };
    
    if (frameBuffer) {
      result = await this.analyzeImage(frameBuffer);
    }
    
    // Return both visual analysis and audio buffer for transcription
    return {
      ...result,
      audioBuffer,
      hasAudio: !!audioBuffer
    };
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
        audioBuffer: analysis.audioBuffer,
        hasAudio: analysis.hasAudio,
        faces: analysis.faces,
        objects: analysis.objects,
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
