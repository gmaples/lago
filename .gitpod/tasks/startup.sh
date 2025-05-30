#!/bin/bash
# =============================================================================
# GITPOD RUNTIME STARTUP SCRIPT
# =============================================================================
# 
# This script runs when the workspace starts at runtime. It initializes Docker,
# sets up the environment, and starts the Lago development services.
#
# IMPORTANT: This runs during workspace startup. If issues occur, user needs
# immediate diagnostic information and recovery commands since AI assistant
# may not be immediately available.
#
# =============================================================================

set -euo pipefail

# Setup logging
LOG_FILE="/workspace/lago/startup.log"
exec 1> >(tee -a "$LOG_FILE")
exec 2> >(tee -a "$LOG_FILE" >&2)

echo "============================================================================="
echo "🚀 LAGO DEVELOPMENT ENVIRONMENT STARTUP - $(date)"
echo "============================================================================="
echo ""
echo "⏰ Started at: $(date '+%Y-%m-%d %H:%M:%S')"
echo "📝 Full log: $LOG_FILE"
echo "🎯 Goal: Start Lago environment using pre-cached images (should be <30 seconds)"
echo ""

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

# Since images are pre-cached, this should be lightning fast
echo "🚀 Using pre-cached images for fast startup..."

# Use idempotent start (only starts what's needed)
./gitpod-script/lago_health_check.sh --start-only

echo ""
echo "🚀 Lago development environment is starting!"
echo "   Frontend: https://8080-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
echo "   API: https://3000-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
echo ""
echo "Use './gitpod-script/lago_health_check.sh --check-only' to verify status"
echo "Use 'docker compose logs -f' to view logs" 