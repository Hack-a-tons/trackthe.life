#!/usr/bin/env bash
set -euo pipefail

# Colors
GRAY='\033[0;90m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Auto-detect environment
if command -v docker &> /dev/null; then
  # Running on server - use external port
  DEFAULT_BACKEND_URL="http://localhost:6000"
else
  # Running on dev machine - use production URL
  DEFAULT_BACKEND_URL="https://trackthelife.hurated.com"
fi

# Default settings
PAUSE_SECONDS=0
VERBOSE=false
EMULATE_ESP32=true
ESP32_URL=""
BACKEND_URL="${BACKEND_URL:-$DEFAULT_BACKEND_URL}"

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
  --emulate-esp32         Use simulated ESP32 images (default)
  --esp32-url URL         Use real ESP32 camera at URL (e.g., http://192.168.1.100)

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
  BACKEND_URL             Backend URL (auto-detected based on environment)
                          Server: http://localhost:4000
                          Dev:    https://trackthelife.hurated.com

EOF
      exit 0
      ;;
    -p*)
      # Handle -p, -p5, -pv, -vp, etc.
      flag="$1"
      # Extract pause value if present
      if [[ $flag =~ -p([0-9]+) ]]; then
        PAUSE_SECONDS="${BASH_REMATCH[1]}"
      elif [[ $flag == "-p" ]]; then
        PAUSE_SECONDS=-1
      fi
      # Check for verbose flag
      if [[ $flag == *v* ]]; then
        VERBOSE=true
      fi
      ;;
    -v*)
      # Handle -v, -vp, -vp5, etc.
      VERBOSE=true
      flag="$1"
      # Check for pause flag
      if [[ $flag =~ -v.*p([0-9]+) ]]; then
        PAUSE_SECONDS="${BASH_REMATCH[1]}"
      elif [[ $flag == *p* ]]; then
        PAUSE_SECONDS=-1
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
    --verbose)
      VERBOSE=true
      ;;
    --emulate-esp32)
      EMULATE_ESP32=true
      ;;
    --esp32-url)
      EMULATE_ESP32=false
      ESP32_URL="$2"
      shift
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
    echo -e "${GRAY}$1${NC}" >&2
  fi
}

pause_step() {
  if [ "$PAUSE_SECONDS" -eq -1 ]; then
    echo -e "\n${YELLOW}Press any key to continue...${NC}"
    read -n 1 -s
  elif [ "$PAUSE_SECONDS" -gt 0 ]; then
    echo -e "\n${YELLOW}Pausing for ${PAUSE_SECONDS} seconds (press any key to skip)...${NC}"
    read -n 1 -s -t "$PAUSE_SECONDS" || true
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
step_show_samples() {
  print_step "Available Samples"
  print_info "Opening sample files for preview..."
  echo ""
  
  # Find all sample files
  SAMPLE_FILES=(sample/*.jpg sample/*.jpeg sample/*.png sample/*.mov sample/*.mp4)
  OPENED_COUNT=0
  
  for file in "${SAMPLE_FILES[@]}"; do
    if [ -f "$file" ]; then
      echo "  📁 $(basename "$file")"
      if command -v open &> /dev/null; then
        open "$file" 2>/dev/null &
        OPENED_COUNT=$((OPENED_COUNT + 1))
      fi
    fi
  done
  
  if [ $OPENED_COUNT -gt 0 ]; then
    echo ""
    print_success "Opened $OPENED_COUNT sample files in Preview"
  else
    print_info "No sample files found in sample/ directory"
  fi
  
  pause_step
}

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
  
  if [ "$EMULATE_ESP32" = true ]; then
    print_info "Simulating ESP32 camera capture and upload..."
    
    mkdir -p captures
    
    # Always use samples from repo sample/ folder
    SAMPLE_FILES=(sample/*.jpg sample/*.jpeg sample/*.png sample/*.mov sample/*.mp4)
    AVAILABLE_SAMPLES=()
    
    for file in "${SAMPLE_FILES[@]}"; do
      if [ -f "$file" ]; then
        AVAILABLE_SAMPLES+=("$file")
      fi
    done
    
    if [ ${#AVAILABLE_SAMPLES[@]} -gt 0 ]; then
      # Pick a random sample
      RANDOM_INDEX=$((RANDOM % ${#AVAILABLE_SAMPLES[@]}))
      SAMPLE_FILE="${AVAILABLE_SAMPLES[$RANDOM_INDEX]}"
      IMAGE_FILE="$SAMPLE_FILE"
      print_verbose "Selected: $(basename "$SAMPLE_FILE")"
    else
      print_error "No samples found in sample/ directory!"
      exit 1
    fi
  else
    print_info "Fetching image from real ESP32 at $ESP32_URL..."
    mkdir -p captures
    if curl -s -o captures/esp32_capture.jpg "$ESP32_URL/capture" 2>/dev/null; then
      IMAGE_FILE="captures/esp32_capture.jpg"
      print_success "Image captured from ESP32"
    else
      print_error "Failed to capture from ESP32, falling back to test image"
      IMAGE_FILE="captures/test.jpg"
    fi
  fi
  
  # Display image info and open in viewer
  if [ -f "$IMAGE_FILE" ]; then
    echo ""
    echo "📷 Image: $(pwd)/$IMAGE_FILE"
    
    # Show image info
    if command -v file &> /dev/null; then
      file "$IMAGE_FILE"
    fi
    ls -lh "$IMAGE_FILE"
    
    # Try to open image in default viewer
    if command -v open &> /dev/null; then
      open "$IMAGE_FILE" 2>/dev/null &
      echo "   Opened in Preview"
    elif command -v xdg-open &> /dev/null; then
      xdg-open "$IMAGE_FILE" 2>/dev/null &
      echo "   Opened in default viewer"
    fi
    echo ""
  fi
  
  print_info "Uploading image to backend..."
  print_verbose "File: $IMAGE_FILE"
  print_verbose "User: demo-user"
  print_verbose "Timestamp: $(date -Iseconds)"
  
  response=$(curl -s -X POST "${BACKEND_URL}/api/media" \
    -F "file=@$IMAGE_FILE" \
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
    description=$(echo "$response" | grep -o '"description":"[^"]*"' | cut -d'"' -f4)
    if [ -n "$description" ]; then
      echo "  Description: $description"
    fi
    labels=$(echo "$response" | grep -o '"labels":\[[^]]*\]')
    echo "  Tags: $labels"
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

step_service_results() {
  print_step "Step 5: Service Results"
  print_info "Querying actual service data..."
  echo ""
  
  # Query MemMachine for stored memories
  echo -e "${YELLOW}📝 MemMachine Memories (last 10):${NC}"
  if command -v ssh &> /dev/null && [[ "$BACKEND_URL" == *"hurated.com"* ]]; then
    MEMORIES=$(ssh trackthelife.hurated.com 'curl -s -X POST http://localhost:7000/v1/memories/search \
      -H "Content-Type: application/json" \
      -d "{\"session\":{\"group_id\":\"trackthelife\",\"user_id\":[\"demo-user\"]},\"query\":\"recent\",\"limit\":10}"' 2>/dev/null)
    
    if [ -n "$MEMORIES" ]; then
      echo "$MEMORIES" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    memories = data.get('content', {}).get('episodic_memory', [[],[]])[1]
    if memories:
        for i, m in enumerate(memories[:10], 1):
            print(f'  {i}. {m[\"content\"]}')
            print(f'     Time: {m[\"timestamp\"]}')
            print()
    else:
        print('  No memories found')
except Exception as e:
    print(f'  Error: {e}')
" 2>/dev/null || echo "  ℹ️  Unable to parse MemMachine response"
    else
      echo "  ℹ️  Unable to fetch memories"
    fi
  else
    echo "  ℹ️  Local backend - query http://localhost:7000/v1/memories/search"
  fi
  echo ""
  
  # Show backend service logs
  echo -e "${YELLOW}📊 Backend Service Logs (last 10 lines):${NC}"
  if command -v ssh &> /dev/null && [[ "$BACKEND_URL" == *"hurated.com"* ]]; then
    ssh trackthelife.hurated.com 'docker logs trackthelife-backend --tail 10 2>&1 | grep -E "\[Whisper\]|\[Comet\]|\[Vision\]|\[Storage\]"' 2>/dev/null || \
      echo "  ℹ️  Unable to fetch remote logs"
  else
    echo "  ℹ️  Local backend - check: docker logs trackthelife-backend"
  fi
  echo ""
  
  print_success "Service results displayed"
  pause_step
}

step_summary() {
  print_step "Step 6: System Summary"
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
        step_show_samples
        step_health
        step_upload_image
        step_upload_audio
        step_query_memories
        step_service_results
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
