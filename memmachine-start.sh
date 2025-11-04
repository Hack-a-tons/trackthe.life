#!/bin/sh
set -e

# Generate cfg.yml from environment variables
cat > /app/cfg.yml <<EOF
episodic_memory:
  model:
    provider: azure
    model: gpt-4
    api_key: ${AZURE_OPENAI_API_KEY}
    api_base: ${AZURE_OPENAI_ENDPOINT}
    api_version: ${AZURE_OPENAI_API_VERSION}
    deployment_name: ${AZURE_OPENAI_DEPLOYMENT}

profile_memory:
  model:
    provider: azure
    model: gpt-4
    api_key: ${AZURE_OPENAI_API_KEY}
    api_base: ${AZURE_OPENAI_ENDPOINT}
    api_version: ${AZURE_OPENAI_API_VERSION}
    deployment_name: ${AZURE_OPENAI_DEPLOYMENT}

database:
  postgres:
    host: ${POSTGRES_HOST}
    port: ${POSTGRES_PORT}
    database: ${POSTGRES_DB}
    user: ${POSTGRES_USER}
    password: ${POSTGRES_PASSWORD}
  neo4j:
    uri: ${NEO4J_URI}
    user: ${NEO4J_USER}
    password: ${NEO4J_PASSWORD}

server:
  host: 0.0.0.0
  port: 8080
EOF

# Start MemMachine
exec memmachine-server
