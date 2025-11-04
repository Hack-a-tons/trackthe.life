#!/usr/bin/env bash
set -euo pipefail

# Change to script directory
cd "$(dirname "$0")"

SERVER="trackthelife.hurated.com"
REPO_DIR="trackthe.life"
COMMIT_MESSAGE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -m)
      COMMIT_MESSAGE="$2"
      shift 2
      ;;
    *)
      echo "Usage: $0 [-m \"commit message\"]"
      exit 1
      ;;
  esac
done

echo "🚀 Deploying trackthe.life..."

# Auto-commit if message provided
if [ -n "$COMMIT_MESSAGE" ]; then
  if ! git diff-index --quiet HEAD --; then
    echo "📝 Committing changes: $COMMIT_MESSAGE"
    git add -A
    git commit -m "$COMMIT_MESSAGE"
  else
    echo "ℹ️  No changes to commit"
  fi
fi

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
