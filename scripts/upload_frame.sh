#!/usr/bin/env bash
set -euo pipefail

# Upload a frame to the backend
# Usage: ./upload_frame.sh <image_file> [user_id] [location]

IMAGE_FILE="${1:-}"
USER_ID="${2:-demo-user}"
LOCATION="${3:-}"

if [ -z "$IMAGE_FILE" ]; then
  echo "Usage: $0 <image_file> [user_id] [location]"
  exit 1
fi

if [ ! -f "$IMAGE_FILE" ]; then
  echo "Error: File $IMAGE_FILE not found"
  exit 1
fi

TIMESTAMP=$(date -Iseconds)

CURL_ARGS=(
  -X POST "http://localhost:4000/api/media"
  -F "file=@$IMAGE_FILE"
  -F "user_id=$USER_ID"
  -F "timestamp=$TIMESTAMP"
)

if [ -n "$LOCATION" ]; then
  CURL_ARGS+=(-F "location=$LOCATION")
fi

curl "${CURL_ARGS[@]}"
echo
