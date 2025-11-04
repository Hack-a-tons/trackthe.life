#!/usr/bin/env bash
set -euo pipefail

# Deploy trackthe.life to server

SERVER="trackthelife.hurated.com"
REPO_DIR="trackthe.life"

echo "🚀 Deploying trackthe.life to $SERVER..."

# SSH and deploy
ssh "$SERVER" << 'ENDSSH'
cd trackthe.life || exit 1

echo "📥 Pulling latest changes..."
git pull

echo "🔨 Building and starting containers..."
docker compose up -d --build

echo "✅ Deployment complete!"
echo ""
echo "📊 Container status:"
docker compose ps

echo ""
echo "📝 Recent logs:"
docker compose logs --tail=20 backend

echo ""
echo "🌐 Test: curl https://trackthelife.hurated.com/api/health"
ENDSSH

echo ""
echo "✨ Done! Service is running at https://trackthelife.hurated.com"
