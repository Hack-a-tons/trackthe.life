#!/usr/bin/env bash
set -euo pipefail

# Upload audio file for transcription
# Usage: ./upload_audio.sh <audio_file> [user_id] [media_id]

AUDIO_FILE="${1:-}"
USER_ID="${2:-demo-user}"
MEDIA_ID="${3:-}"

if [ -z "$AUDIO_FILE" ]; then
  echo "Usage: $0 <audio_file> [user_id] [media_id]"
  exit 1
fi

if [ ! -f "$AUDIO_FILE" ]; then
  echo "Error: File $AUDIO_FILE not found"
  exit 1
fi

TIMESTAMP=$(date -Iseconds)

CURL_ARGS=(
  -X POST "http://localhost:4000/api/audio"
  -F "file=@$AUDIO_FILE"
  -F "user_id=$USER_ID"
  -F "timestamp=$TIMESTAMP"
)

if [ -n "$MEDIA_ID" ]; then
  CURL_ARGS+=(-F "media_id=$MEDIA_ID")
fi

curl "${CURL_ARGS[@]}"
echo
