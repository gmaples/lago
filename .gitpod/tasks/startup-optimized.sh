#!/bin/bash
# =============================================================================
# GITPOD OPTIMIZED STARTUP SCRIPT
# =============================================================================
# 
# This script runs when the workspace starts at runtime. Since Docker images
# and dependencies are pre-cached during prebuild, startup should be
# lightning fast (under 30 seconds).
#
# =============================================================================

set -euo pipefail

echo "=== Lago Development Environment Startup (Optimized) ==="

# Source environment variables
export LAGO_PATH="/workspace/lago"
source ~/.bashrc

# Record start time for performance measurement
start_time=$(date +%s)

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

echo ""
echo "🚀 Docker ready! Starting pre-cached Lago environment..."
echo "   Images should already be built and cached from prebuild"
echo ""

# Since images are pre-cached, this should be lightning fast
echo "⚡ Using pre-cached images for fast startup..."

# Use idempotent start (only starts what's needed)
./gitpod-script/lago_health_check.sh --start-only

# Calculate startup time
end_time=$(date +%s)
startup_duration=$((end_time - start_time))

echo ""
echo "🎉 Lago development environment started successfully!"
echo "⏱️  Total startup time: ${startup_duration} seconds"
echo ""
echo "🌐 URLs:"
echo "   Frontend: https://8080-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
echo "   API: https://3000-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
echo ""
echo "🛠️  Useful commands:"
echo "   ./gitpod-script/lago_health_check.sh --check-only  # Verify status"
echo "   docker compose logs -f                           # View logs"
echo "   ./gitpod-script/lago_health_check.sh --restart    # Full restart if needed"
echo "" 