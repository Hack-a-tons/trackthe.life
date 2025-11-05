#!/usr/bin/env node
require('dotenv').config();
const { exec } = require('child_process');
const { promisify } = require('util');
const fs = require('fs').promises;
const path = require('path');

const execAsync = promisify(exec);

const UPLOADS_DIR = path.join(__dirname, '../uploads');
const CLIPS_DIR = path.join(__dirname, '../clips');

async function findImageFiles(hours = 24) {
  try {
    const files = await fs.readdir(UPLOADS_DIR);
    const cutoffTime = Date.now() - hours * 60 * 60 * 1000;
    
    const imageFiles = [];
    for (const file of files) {
      if (file.endsWith('.jpg') || file.endsWith('.png')) {
        const filepath = path.join(UPLOADS_DIR, file);
        const stats = await fs.stat(filepath);
        if (stats.mtimeMs > cutoffTime) {
          imageFiles.push({ path: filepath, time: stats.mtimeMs });
        }
      }
    }
    
    // Sort by time
    return imageFiles.sort((a, b) => a.time - b.time).map(f => f.path);
  } catch (error) {
    console.error('Error reading uploads directory:', error.message);
    return [];
  }
}

async function buildClip(imageFiles, outputPath) {
  if (imageFiles.length === 0) {
    console.log('No images to process');
    return null;
  }
  
  console.log(`Building clip from ${imageFiles.length} images...`);
  
  // Create a temporary file list for FFmpeg
  const listFile = path.join(CLIPS_DIR, 'filelist.txt');
  const fileList = imageFiles.map(f => `file '${f}'\nduration 2`).join('\n') + `\nfile '${imageFiles[imageFiles.length - 1]}'`;
  await fs.writeFile(listFile, fileList);
  
  // Use FFmpeg to create video from images
  const ffmpegCmd = `ffmpeg -f concat -safe 0 -i "${listFile}" -vf "scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2" -c:v libx264 -pix_fmt yuv420p -y "${outputPath}"`;
  
  try {
    const { stdout, stderr } = await execAsync(ffmpegCmd);
    console.log('FFmpeg output:', stderr.split('\n').slice(-5).join('\n'));
    await fs.unlink(listFile);
    return outputPath;
  } catch (error) {
    console.error('FFmpeg error:', error.message);
    return null;
  }
}

async function main() {
  console.log('🎬 Building daily clip...\n');
  
  // Ensure clips directory exists
  await fs.mkdir(CLIPS_DIR, { recursive: true });
  
  // Find image files from last 24h
  console.log('🖼️  Finding captured images from last 24 hours...');
  const imageFiles = await findImageFiles(24);
  console.log(`Found ${imageFiles.length} images`);
  
  if (imageFiles.length === 0) {
    console.log('⚠️  No images found to create clip');
    console.log('💡 Tip: Run ./demo.sh all to generate test images');
    return;
  }
  
  // Build clip
  const today = new Date().toISOString().split('T')[0];
  const outputPath = path.join(CLIPS_DIR, `daily_${today}.mp4`);
  
  console.log('\n🎥 Creating video clip...');
  const clipPath = await buildClip(imageFiles, outputPath);
  
  if (clipPath) {
    const stats = await fs.stat(clipPath);
    console.log(`\n✅ Clip created successfully!`);
    console.log(`   Path: ${clipPath}`);
    console.log(`   Size: ${(stats.size / 1024 / 1024).toFixed(2)} MB`);
    console.log(`   Duration: ~${imageFiles.length * 2} seconds`);
    console.log(`   Images: ${imageFiles.length}`);
  } else {
    console.log('\n❌ Failed to create clip');
  }
}

main().catch(console.error);

