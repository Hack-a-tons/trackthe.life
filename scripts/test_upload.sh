#!/usr/bin/env bash
set -euo pipefail

# Test upload with a sample image
# Creates a minimal test image if none exists

SAMPLE_IMAGE="captures/sample.jpg"

# Create captures directory if it doesn't exist
mkdir -p captures

# Create a minimal test image using ImageMagick or skip if not available
if command -v convert &> /dev/null; then
  convert -size 100x100 xc:blue "$SAMPLE_IMAGE" 2>/dev/null || echo "Using curl test instead"
fi

# Test with curl directly
echo "Testing media upload endpoint..."
curl -X POST "http://localhost:4000/api/media" \
  -F "file=@README.md" \
  -F "user_id=test-user" \
  -F "timestamp=$(date -Iseconds)" \
  -F "location=37.7749,-122.4194"

echo -e "\n\nTest complete!"
