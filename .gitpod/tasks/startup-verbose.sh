#!/bin/bash
# =============================================================================
# GITPOD VERBOSE STARTUP SCRIPT
# =============================================================================
# 
# This script runs when the workspace starts at runtime with extensive logging
# and self-diagnosis capabilities. Since AI assistant may not be immediately
# available during startup issues, this script provides detailed diagnostics.
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

# =============================================================================
echo "🔧 STEP 1: Environment Setup"
echo "============================================================================="

# Source environment variables
echo "📁 Setting up environment variables..."
export LAGO_PATH="/workspace/lago"

if [[ -f ~/.bashrc ]]; then
    echo "✅ Sourcing ~/.bashrc"
    source ~/.bashrc
else
    echo "⚠️  Warning: ~/.bashrc not found"
fi

echo "📋 Key environment variables:"
echo "   LAGO_PATH: $LAGO_PATH"
echo "   GITPOD_WORKSPACE_ID: ${GITPOD_WORKSPACE_ID:-'not set'}"
echo "   GITPOD_WORKSPACE_CLUSTER_HOST: ${GITPOD_WORKSPACE_CLUSTER_HOST:-'not set'}"
echo ""

# =============================================================================
echo "🔧 STEP 2: Docker Initialization"
echo "============================================================================="

# Record start time for performance measurement
start_time=$(date +%s)

# Initialize Docker (this only works at runtime, not during prebuild)
echo "🐳 Initializing Docker with .gitpod.docker-init.sh..."
if [[ -f .gitpod.docker-init.sh ]]; then
    echo "   ⏰ Docker init started: $(date '+%H:%M:%S')"
    if bash .gitpod.docker-init.sh; then
        echo "   ✅ Docker initialization completed"
    else
        echo "   ❌ Docker initialization failed"
        echo "   🔍 DIAGNOSIS: Docker init script failed"
        echo "   🛠️  RECOVERY: Try manual Docker start"
        echo "      sudo service docker start"
    fi
else
    echo "   ❌ ERROR: .gitpod.docker-init.sh not found"
    echo "   🔍 DIAGNOSIS: Missing Docker initialization script"
    echo "   🛠️  RECOVERY: Try starting Docker manually"
    echo "      sudo service docker start"
fi

# Wait for Docker to be ready with detailed progress
echo "⏳ Waiting for Docker daemon to be ready..."
timeout=60
current_wait=0
while ! docker info >/dev/null 2>&1 && [ $current_wait -lt $timeout ]; do
    current_wait=$((current_wait + 2))
    echo "   ⏰ Waiting for Docker... (${current_wait}/${timeout} seconds)"
    if [[ $((current_wait % 10)) -eq 0 ]]; then
        echo "   🔍 Checking Docker status: $(systemctl is-active docker || echo 'unknown')"
    fi
    sleep 2
done

if ! docker info >/dev/null 2>&1; then
    echo "❌ CRITICAL ERROR: Docker failed to start within ${timeout} seconds"
    echo "🔍 DIAGNOSIS: Docker daemon is not responding"
    echo "📊 System status:"
    echo "   Docker service: $(systemctl is-active docker || echo 'unknown')"
    echo "   Docker socket: $(ls -la /var/run/docker.sock 2>/dev/null || echo 'not found')"
    echo ""
    echo "🛠️  RECOVERY OPTIONS:"
    echo "   1. Manual Docker start:"
    echo "      sudo service docker start"
    echo "      ./gitpod-script/lago_health_check.sh --restart"
    echo ""
    echo "   2. Check Docker logs:"
    echo "      sudo journalctl -u docker --no-pager --lines=20"
    echo ""
    echo "   3. Restart workspace if Docker is completely broken"
    exit 1
fi

docker_ready_time=$(date +%s)
docker_init_duration=$((docker_ready_time - start_time))
echo "✅ Docker is ready! (took ${docker_init_duration} seconds)"
echo ""

# =============================================================================
echo "🔧 STEP 3: Pre-Cache Verification"
echo "============================================================================="

echo "🔍 Checking if warm cache was successful during prebuild..."

# Check if cached images exist
cached_images=$(docker images --filter "reference=*dev" --format "{{.Repository}}:{{.Tag}}" | wc -l)
total_images=$(docker images --format "{{.Repository}}:{{.Tag}}" | wc -l)

echo "📊 Docker cache status:"
echo "   Total images: $total_images"
echo "   Cached dev images: $cached_images"

if [[ $cached_images -gt 0 ]]; then
    echo "✅ Warm cache found - custom images are pre-built"
    echo "   This should make startup very fast!"
    
    echo "📋 Available cached images:"
    docker images --filter "reference=*dev" --format "   ✅ {{.Repository}}:{{.Tag}} ({{.Size}})"
else
    echo "⚠️  WARNING: No cached dev images found"
    echo "🔍 DIAGNOSIS: Warm cache may have failed during prebuild"
    echo "🛠️  RECOVERY: Startup will be slower as images need to be built"
    echo "   Expected startup time: 3-5 minutes instead of 30 seconds"
fi

# Check if volumes exist
volume_count=$(docker volume ls -q | wc -l)
echo "📁 Docker volumes: $volume_count volumes found"

echo ""

# =============================================================================
echo "🔧 STEP 4: Starting Lago Services"
echo "============================================================================="

echo "🚀 Starting Lago development environment using health check script..."
echo "   Using idempotent start for maximum reliability"
echo "   ⏰ Service startup started: $(date '+%H:%M:%S')"
echo ""

# Use our health check script for reliable startup
if ./gitpod-script/lago_health_check.sh --start-only; then
    service_start_time=$(date +%s)
    service_duration=$((service_start_time - docker_ready_time))
    total_duration=$((service_start_time - start_time))
    
    echo ""
    echo "🎉 LAGO DEVELOPMENT ENVIRONMENT STARTED SUCCESSFULLY!"
    echo ""
    echo "⏱️  PERFORMANCE METRICS:"
    echo "   Docker initialization: ${docker_init_duration} seconds"
    echo "   Service startup: ${service_duration} seconds"
    echo "   Total startup time: ${total_duration} seconds"
    
    if [[ $total_duration -lt 60 ]]; then
        echo "   🚀 EXCELLENT: Under 1 minute (warm cache working!)"
    elif [[ $total_duration -lt 180 ]]; then
        echo "   ✅ GOOD: Under 3 minutes"
    else
        echo "   ⚠️  SLOW: Over 3 minutes (warm cache may not be working)"
    fi
    
    echo ""
    echo "🌐 LAGO URLS:"
    echo "   Frontend: https://8080-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
    echo "   API: https://3000-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
    echo ""
    echo "🛠️  USEFUL COMMANDS:"
    echo "   ./gitpod-script/lago_health_check.sh --check-only  # Verify all services"
    echo "   docker compose logs -f                           # View live logs"
    echo "   ./gitpod-script/lago_health_check.sh --restart    # Full restart"
    echo "   cat $LOG_FILE                                    # View startup log"
    echo ""
    
else
    echo ""
    echo "❌ STARTUP FAILED: Lago services could not start"
    echo ""
    echo "🔍 DIAGNOSIS: Health check script detected issues"
    echo "📝 Check the health check output above for specific failures"
    echo ""
    echo "🛠️  RECOVERY OPTIONS:"
    echo ""
    echo "   1. Check service status:"
    echo "      ./gitpod-script/lago_health_check.sh --check-only"
    echo ""
    echo "   2. View container logs:"
    echo "      docker compose logs"
    echo ""
    echo "   3. Try full restart:"
    echo "      ./gitpod-script/lago_health_check.sh --restart"
    echo ""
    echo "   4. Manual debugging:"
    echo "      docker ps -a                    # Check container status"
    echo "      docker compose ps               # Check compose status"
    echo "      docker images                   # Check available images"
    echo ""
    echo "   5. Check specific service logs:"
    echo "      docker compose logs api         # API service logs"
    echo "      docker compose logs front       # Frontend logs"
    echo "      docker compose logs db          # Database logs"
    echo ""
    echo "📝 Full startup log: $LOG_FILE"
    echo ""
    exit 1
fi 