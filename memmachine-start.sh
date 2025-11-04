#!/bin/sh
set -e

echo "Generating cfg.yml from environment variables..."

# Extract Neo4j host from URI
NEO4J_HOST=$(echo $NEO4J_URI | sed 's|bolt://||' | cut -d: -f1)
NEO4J_PORT=$(echo $NEO4J_URI | sed 's|bolt://||' | cut -d: -f2)

# Generate cfg.yml with proper substitution
envsubst < /app/cfg.yml.template > /app/cfg.yml

echo "cfg.yml generated successfully"
cat /app/cfg.yml

# Start MemMachine
echo "Starting MemMachine..."
exec memmachine-server
