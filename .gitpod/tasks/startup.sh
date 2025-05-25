#!/bin/bash
# =============================================================================
# GITPOD RUNTIME STARTUP SCRIPT
# =============================================================================
# 
# This script runs when the workspace starts at runtime. It initializes Docker,
# sets up the environment, and starts the Lago development services.
#
# =============================================================================

set -euo pipefail

echo "=== Lago Development Environment Startup ==="

# Source environment variables
export LAGO_PATH="/workspace/lago"
source ~/.bashrc

# Initialize Docker (this only works at runtime, not during prebuild)
echo "Initializing Docker..."
bash .gitpod.docker-init.sh

# Wait for Docker to be ready
echo "Waiting for Docker to be ready..."
timeout=30
while ! docker info >/dev/null 2>&1 && [ $timeout -gt 0 ]; do
  echo "Waiting for Docker... ($timeout seconds remaining)"
  sleep 2
  timeout=$((timeout-2))
done

if ! docker info >/dev/null 2>&1; then
  echo "ERROR: Docker failed to start. Please run manually:"
  echo "  sudo service docker start"
  echo "  ./gitpod-script/lago_health_check.sh --restart"
  exit 1
fi

echo "Docker is ready! Starting Lago development environment..."

# Use our new health check script for reliable startup
./gitpod-script/lago_health_check.sh --restart

echo ""
echo "🚀 Lago development environment is starting!"
echo "   Frontend: https://8080-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
echo "   API: https://3000-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
echo ""
echo "Use './gitpod-script/lago_health_check.sh --check-only' to verify status"
echo "Use 'docker compose logs -f' to view logs" 