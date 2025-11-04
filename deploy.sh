#!/usr/bin/env bash
set -euo pipefail

# Change to script directory
cd "$(dirname "$0")"

SERVER="trackthelife.hurated.com"
REPO_DIR="trackthe.life"

echo "🚀 Deploying trackthe.life..."

# Check if running on server (docker installed = server)
if command -v docker &> /dev/null; then
  echo "📍 Running on server - deploying locally"
  
  git pull
  docker compose build
  docker compose up -d
  
  echo ""
  echo "📊 Container status:"
  docker compose ps
  
  echo ""
  echo "📝 Recent logs:"
  docker compose logs --tail=20 backend
  
else
  echo "📍 Running on dev machine - deploying to server"
  
  git push
  
  echo "📤 Copying .env to server..."
  scp .env "$SERVER:$REPO_DIR/"
  
  echo "🔨 Building and starting on server..."
  ssh "$SERVER" << 'ENDSSH'
cd trackthe.life

echo "📥 Pulling latest changes..."
git pull

echo "🔨 Building containers..."
docker compose build

echo "🚀 Starting services..."
docker compose up -d

echo ""
echo "📊 Container status:"
docker compose ps

echo ""
echo "📝 Recent logs:"
docker compose logs --tail=20 backend
ENDSSH
  
fi

echo ""
echo "✨ Done! Service is running at https://trackthelife.hurated.com"
