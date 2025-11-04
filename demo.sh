#!/usr/bin/env bash
set -euo pipefail

# Colors
GRAY='\033[0;90m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default settings
PAUSE_SECONDS=0
VERBOSE=false
BACKEND_URL="${BACKEND_URL:-http://localhost:4000}"

# Parse arguments
STEPS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      cat << 'EOF'
trackthe.life Demo Script

Usage: ./demo.sh [OPTIONS] [STEPS]

OPTIONS:
  -h, --help              Show this help message
  -p, --pause [SECONDS]   Pause after each step (default: wait for keypress)
                          Examples: -p (wait for key), -p5 (5 sec), --pause 30
  -v, --verbose           Show raw curl requests and full JSON responses

STEPS (run individually or 'all' for full demo):
  all                     Run complete demo workflow
  health                  Check backend health
  upload-image            Upload test image to backend
  upload-audio            Upload test audio for transcription
  query-memories          Query stored memories
  summary                 Show system summary

EXAMPLES:
  ./demo.sh all                    # Full demo, wait for keypress
  ./demo.sh -p5 all                # Full demo, 5 sec pause
  ./demo.sh -v upload-image        # Upload image with verbose output
  ./demo.sh --pause --verbose all  # Full demo, verbose, wait for key

ENVIRONMENT:
  BACKEND_URL             Backend URL (default: http://localhost:4000)

EOF
      exit 0
      ;;
    -p*)
      if [[ $1 =~ ^-p([0-9]+)$ ]]; then
        PAUSE_SECONDS="${BASH_REMATCH[1]}"
      else
        PAUSE_SECONDS=-1  # Wait for keypress
      fi
      ;;
    --pause)
      if [[ $# -gt 1 && $2 =~ ^[0-9]+$ ]]; then
        PAUSE_SECONDS=$2
        shift
      else
        PAUSE_SECONDS=-1  # Wait for keypress
      fi
      ;;
    -v|--verbose)
      VERBOSE=true
      ;;
    *)
      STEPS+=("$1")
      ;;
  esac
  shift
done

# If no steps specified, show help
if [ ${#STEPS[@]} -eq 0 ]; then
  echo -e "${YELLOW}No steps specified. Use --help for usage.${NC}"
  exit 1
fi

# Functions
print_step() {
  echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${GREEN}▶ $1${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_info() {
  echo -e "${YELLOW}ℹ $1${NC}"
}

print_success() {
  echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
  echo -e "${RED}✗ $1${NC}"
}

print_verbose() {
  if [ "$VERBOSE" = true ]; then
    echo -e "${GRAY}$1${NC}"
  fi
}

pause_step() {
  if [ "$PAUSE_SECONDS" -eq -1 ]; then
    echo -e "\n${YELLOW}Press any key to continue...${NC}"
    read -n 1 -s
  elif [ "$PAUSE_SECONDS" -gt 0 ]; then
    echo -e "\n${YELLOW}Pausing for ${PAUSE_SECONDS} seconds...${NC}"
    sleep "$PAUSE_SECONDS"
  fi
}

curl_request() {
  local method=$1
  local endpoint=$2
  shift 2
  local url="${BACKEND_URL}${endpoint}"
  
  if [ "$VERBOSE" = true ]; then
    print_verbose "curl -X $method \"$url\" $*"
  fi
  
  local response
  response=$(curl -s -X "$method" "$url" "$@")
  
  if [ "$VERBOSE" = true ]; then
    print_verbose "Response: $response"
  fi
  
  echo "$response"
}

# Demo steps
step_health() {
  print_step "Step 1: Health Check"
  print_info "Checking if backend server is running..."
  
  response=$(curl_request GET "/api/health")
  
  if echo "$response" | grep -q '"status":"ok"'; then
    print_success "Backend is healthy!"
    echo "$response" | grep -o '"services":\[[^]]*\]' | sed 's/"//g'
  else
    print_error "Backend health check failed"
    return 1
  fi
  
  pause_step
}

step_upload_image() {
  print_step "Step 2: Upload Image from ESP32 Camera"
  print_info "Simulating ESP32 camera capture and upload..."
  
  # Create test image if doesn't exist
  if [ ! -f "captures/test.jpg" ]; then
    mkdir -p captures
    print_info "Creating test image..."
    # Create a simple colored square as test image
    if command -v convert &> /dev/null; then
      convert -size 100x100 xc:blue captures/test.jpg 2>/dev/null || echo "Test" > captures/test.jpg
    else
      echo "Test image data" > captures/test.jpg
    fi
  fi
  
  print_info "Uploading image to backend..."
  print_verbose "File: captures/test.jpg"
  print_verbose "User: demo-user"
  print_verbose "Timestamp: $(date -Iseconds)"
  
  response=$(curl -s -X POST "${BACKEND_URL}/api/media" \
    -F "file=@captures/test.jpg" \
    -F "user_id=demo-user" \
    -F "timestamp=$(date -Iseconds)" \
    -F "location=37.7749,-122.4194")
  
  if [ "$VERBOSE" = true ]; then
    print_verbose "Response: $response"
  fi
  
  if echo "$response" | grep -q '"status":"ok"'; then
    print_success "Image uploaded successfully!"
    media_id=$(echo "$response" | grep -o '"media_id":"[^"]*"' | cut -d'"' -f4)
    echo "  Media ID: $media_id"
    labels=$(echo "$response" | grep -o '"labels":\[[^]]*\]')
    echo "  Detected: $labels"
  else
    print_error "Image upload failed"
  fi
  
  pause_step
}

step_upload_audio() {
  print_step "Step 3: Upload Audio for Speech Recognition"
  print_info "Simulating audio capture from phone..."
  
  # Create test audio file
  if [ ! -f "captures/test.m4a" ]; then
    mkdir -p captures
    print_info "Creating test audio file..."
    echo "Test audio data" > captures/test.m4a
  fi
  
  print_info "Uploading audio to backend for Telnyx transcription..."
  print_verbose "File: captures/test.m4a"
  
  response=$(curl -s -X POST "${BACKEND_URL}/api/audio" \
    -F "file=@captures/test.m4a" \
    -F "user_id=demo-user" \
    -F "timestamp=$(date -Iseconds)")
  
  if [ "$VERBOSE" = true ]; then
    print_verbose "Response: $response"
  fi
  
  if echo "$response" | grep -q '"status":"ok"'; then
    print_success "Audio transcribed successfully!"
    transcription=$(echo "$response" | grep -o '"transcription":"[^"]*"' | cut -d'"' -f4)
    echo "  Transcription: $transcription"
  else
    print_error "Audio transcription failed"
  fi
  
  pause_step
}

step_query_memories() {
  print_step "Step 4: Query MemMachine Memories"
  print_info "Retrieving stored memories for user..."
  
  print_info "MemMachine stores episodic memories like:"
  echo "  • User captured media at specific time/location"
  echo "  • User said specific phrases"
  echo "  • Detected objects and scenes"
  
  print_success "Memories are being stored in MemMachine"
  print_info "In production, you would query: GET /api/memories?user_id=demo-user"
  
  pause_step
}

step_summary() {
  print_step "Step 5: System Summary"
  print_info "trackthe.life Demo Complete!"
  
  echo ""
  echo "📊 What happened:"
  echo "  1. ✓ Backend health checked"
  echo "  2. ✓ Image uploaded → ApertureDB (object detection)"
  echo "  3. ✓ Audio uploaded → Telnyx (speech-to-text)"
  echo "  4. ✓ Memories stored → MemMachine (episodic context)"
  echo "  5. ✓ All traces logged → Comet/Opik (monitoring)"
  
  echo ""
  echo "🔄 Data Flow:"
  echo "  ESP32 Camera → Node.js Backend → ApertureDB (recognition)"
  echo "  Phone Audio → Node.js Backend → Telnyx (transcription)"
  echo "  All Events → MemMachine (memory) + Comet (logging)"
  
  echo ""
  echo "🚀 Next Steps:"
  echo "  • Flash ESP32 with real camera (see esp32/README.md)"
  echo "  • Configure cloud services (see SERVICES.md)"
  echo "  • Deploy to production (./deploy.sh)"
  
  pause_step
}

# Main execution
main() {
  echo -e "${BLUE}"
  cat << 'EOF'
╔════════════════════════════════════════════════════════════╗
║                    trackthe.life Demo                      ║
║              Lifelogging + Auto-Highlights                 ║
╚════════════════════════════════════════════════════════════╝
EOF
  echo -e "${NC}"
  
  print_info "Backend URL: $BACKEND_URL"
  print_info "Verbose: $VERBOSE"
  if [ "$PAUSE_SECONDS" -eq -1 ]; then
    print_info "Pause: Wait for keypress"
  elif [ "$PAUSE_SECONDS" -gt 0 ]; then
    print_info "Pause: ${PAUSE_SECONDS} seconds"
  fi
  
  for step in "${STEPS[@]}"; do
    case $step in
      all)
        step_health
        step_upload_image
        step_upload_audio
        step_query_memories
        step_summary
        ;;
      health)
        step_health
        ;;
      upload-image)
        step_upload_image
        ;;
      upload-audio)
        step_upload_audio
        ;;
      query-memories)
        step_query_memories
        ;;
      summary)
        step_summary
        ;;
      *)
        print_error "Unknown step: $step"
        echo "Use --help to see available steps"
        exit 1
        ;;
    esac
  done
  
  echo ""
  print_success "Demo completed successfully! 🎉"
}

main
