#!/bin/sh
set -e

echo "Generating cfg.yml from environment variables..."

# Extract Neo4j host and port from URI
NEO4J_HOST=$(echo $NEO4J_URI | sed 's|bolt://||' | cut -d: -f1)
NEO4J_PORT=$(echo $NEO4J_URI | sed 's|bolt://||' | cut -d: -f2)

# Generate cfg.yml with sed substitution
sed -e "s|\${POSTGRES_USER}|$POSTGRES_USER|g" \
    -e "s|\${POSTGRES_PASSWORD}|$POSTGRES_PASSWORD|g" \
    -e "s|\${POSTGRES_HOST}|$POSTGRES_HOST|g" \
    -e "s|\${POSTGRES_PORT}|$POSTGRES_PORT|g" \
    -e "s|\${POSTGRES_DB}|$POSTGRES_DB|g" \
    -e "s|\${NEO4J_HOST}|$NEO4J_HOST|g" \
    -e "s|\${NEO4J_PORT}|$NEO4J_PORT|g" \
    -e "s|\${NEO4J_USER}|$NEO4J_USER|g" \
    -e "s|\${NEO4J_PASSWORD}|$NEO4J_PASSWORD|g" \
    -e "s|\${OPENAI_API_KEY}|$OPENAI_API_KEY|g" \
    /app/cfg.yml.template > /app/cfg.yml

echo "cfg.yml generated successfully"

# Start MemMachine
echo "Starting MemMachine..."
exec memmachine-server
