#!/bin/bash

# Lago Development Environment Startup Script
# This script ensures all required environment variables are set
# and starts the development environment properly

echo "=== Lago Development Environment Startup ==="

# Load all Gitpod environment variables
echo "Loading Gitpod environment variables..."
eval $(gp env -e)

# Set required environment variables
export LAGO_PATH="/workspace/lago"

# Ensure we're in the correct directory
cd /workspace/lago

# Check for required Gitpod environment variables
if [ -z "$GITPOD_WORKSPACE_ID" ] || [ -z "$GITPOD_WORKSPACE_CLUSTER_HOST" ]; then
    echo "Warning: Gitpod environment variables not found. This might cause issues with URLs."
    echo "GITPOD_WORKSPACE_ID: ${GITPOD_WORKSPACE_ID:-'NOT SET'}"
    echo "GITPOD_WORKSPACE_CLUSTER_HOST: ${GITPOD_WORKSPACE_CLUSTER_HOST:-'NOT SET'}"
fi

# Display current environment variables
echo "Environment variables:"
echo "  LAGO_PATH: $LAGO_PATH"
echo "  SECRET_KEY_BASE: ${SECRET_KEY_BASE:0:20}... (user-level)"
echo "  LAGO_ENCRYPTION_PRIMARY_KEY: ${LAGO_ENCRYPTION_PRIMARY_KEY} (user-level)"
echo "  GITPOD_WORKSPACE_ID: $GITPOD_WORKSPACE_ID"
echo "  GITPOD_WORKSPACE_CLUSTER_HOST: $GITPOD_WORKSPACE_CLUSTER_HOST"
echo

# Start the development environment
echo "Starting Lago development environment..."
docker-compose -f docker-compose.dev.yml "$@" 