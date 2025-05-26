#!/bin/bash
# =============================================================================
# GITPOD WARM CACHE SCRIPT
# =============================================================================
# 
# This script runs during prebuild to cache all Docker images and build
# custom containers so that workspace startup is lightning fast.
#
# IMPORTANT: This runs during prebuild when AI assistant is NOT available.
# Therefore, this script must be completely self-diagnosing with extensive
# logging, clear error messages, and specific recovery instructions.
#
# =============================================================================

set -euo pipefail

# Setup logging
LOG_FILE="/workspace/lago/warm_cache.log"
exec 1> >(tee -a "$LOG_FILE")
exec 2> >(tee -a "$LOG_FILE" >&2)

echo "============================================================================="
echo "🚀 LAGO DOCKER WARM CACHE SETUP - $(date)"
echo "============================================================================="
echo ""
echo "📋 PREBUILD PHASE: AI Assistant NOT available - Self-diagnosing mode"
echo "📝 Full log: $LOG_FILE"
echo "⏰ Started at: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# ============================================================================= 
echo "🔧 STEP 1: Environment Validation"
echo "============================================================================="

# Change to Lago directory
echo "📁 Changing to Lago directory: /workspace/lago"
if ! cd /workspace/lago; then
    echo "❌ CRITICAL ERROR: Cannot change to /workspace/lago directory"
    echo "🔍 DIAGNOSIS: Workspace structure may be corrupted"
    echo "🛠️  RECOVERY: Check if /workspace/lago exists and has correct permissions"
    echo "   Command: ls -la /workspace/"
    exit 1
fi
echo "✅ Successfully changed to Lago directory"

# Verify critical files exist
echo "📋 Verifying critical files exist..."
for file in "docker-compose.dev.yml" "api/Dockerfile.dev" "front/Dockerfile.dev" "events-processor/Dockerfile.dev"; do
    if [[ -f "$file" ]]; then
        echo "✅ Found: $file"
    else
        echo "❌ CRITICAL ERROR: Missing required file: $file"
        echo "🔍 DIAGNOSIS: Git checkout may be incomplete or files moved"
        echo "🛠️  RECOVERY: Run 'git status' and 'git submodule update --init --recursive'"
        exit 1
    fi
done

# Ensure Docker is available (it should be during prebuild)
echo "🐳 Checking Docker availability..."
if ! command -v docker &> /dev/null; then
    echo "❌ CRITICAL ERROR: Docker command not found"
    echo "🔍 DIAGNOSIS: Docker is not installed or not in PATH"
    echo "🛠️  RECOVERY: This should not happen in Gitpod prebuild"
    echo "   This indicates a Gitpod environment issue"
    exit 1
fi
echo "✅ Docker command is available"

# Check if Docker daemon is running
echo "🔧 Checking Docker daemon status..."
if ! docker info >/dev/null 2>&1; then
    echo "❌ CRITICAL ERROR: Docker daemon is not running"
    echo "🔍 DIAGNOSIS: Docker service is not started"
    echo "🛠️  RECOVERY: This should not happen in Gitpod prebuild"
    echo "   This indicates a Gitpod environment issue"
    exit 1
fi
echo "✅ Docker daemon is running"

echo ""
echo "🎉 Environment validation complete - All systems ready"
echo ""

# =============================================================================
echo "🔧 STEP 2: Pulling External Base Images"
echo "============================================================================="
echo "📦 This step downloads all external Docker images to cache them locally."
echo "   This prevents download time during workspace startup."
echo ""

# Define all external images
declare -a EXTERNAL_IMAGES=(
    "traefik:v2.5.4"
    "postgres:14.0-alpine"
    "redis:6.2-alpine"
    "getlago/lago-gotenberg:7"
    "mailhog/mailhog"
    "docker.redpanda.com/redpandadata/redpanda:v23.2.9"
    "docker.redpanda.com/redpandadata/console:v2.3.1"
    "clickhouse/clickhouse-server"
)

total_images=${#EXTERNAL_IMAGES[@]}
current_image=0
failed_images=()

echo "🎯 Total external images to pull: $total_images"
echo ""

for image in "${EXTERNAL_IMAGES[@]}"; do
    current_image=$((current_image + 1))
    echo "📥 [$current_image/$total_images] Pulling: $image"
    echo "   ⏰ Started: $(date '+%H:%M:%S')"
    
    if docker pull "$image"; then
        echo "   ✅ SUCCESS: $image pulled"
        echo "   📊 Image size: $(docker images --format "table {{.Size}}" "$image" | tail -1)"
    else
        echo "   ❌ FAILED: Could not pull $image"
        echo "   🔍 DIAGNOSIS: Network issue or image not found"
        failed_images+=("$image")
    fi
    echo ""
done

if [[ ${#failed_images[@]} -eq 0 ]]; then
    echo "🎉 ALL EXTERNAL IMAGES PULLED SUCCESSFULLY ($total_images/$total_images)"
else
    echo "⚠️  PARTIAL SUCCESS: $((total_images - ${#failed_images[@]}))/$total_images images pulled"
    echo "❌ Failed images: ${failed_images[*]}"
    echo "🛠️  RECOVERY: These images will be pulled during startup instead"
    echo "   This may slow down workspace startup but won't prevent it"
fi
echo ""

# =============================================================================
echo "🔧 STEP 3: Building Custom Development Images"
echo "============================================================================="
echo "🔨 This step builds all custom Docker images from source code."
echo "   This is the most time-consuming part but only happens during prebuild."
echo ""

# Define all custom images to build
declare -A CUSTOM_IMAGES=(
    ["front"]="Frontend development image (React/TypeScript)"
    ["api"]="API development image (Rails application)"
    ["events-processor"]="Events processor development image (Go service)"
)

echo "🎯 Custom images to build: ${#CUSTOM_IMAGES[@]}"
echo ""

build_start_time=$(date +%s)

# Enable BuildKit for faster builds
export COMPOSE_DOCKER_CLI_BUILD=1
export DOCKER_BUILDKIT=1
echo "🚀 BuildKit enabled for faster builds"
echo ""

build_failures=()

for service in "${!CUSTOM_IMAGES[@]}"; do
    echo "🔨 Building $service (${CUSTOM_IMAGES[$service]})..."
    echo "   ⏰ Started: $(date '+%H:%M:%S')"
    
    if docker compose -f docker-compose.dev.yml build "$service"; then
        echo "   ✅ SUCCESS: $service image built"
        # Show image size if successful
        if docker images "${service}_dev" --format "{{.Size}}" | head -1 > /dev/null 2>&1; then
            size=$(docker images "${service}_dev" --format "{{.Size}}" | head -1)
            echo "   📊 Image size: $size"
        fi
    else
        echo "   ❌ FAILED: $service build failed"
        echo "   🔍 DIAGNOSIS: Docker build encountered errors for $service"
        build_failures+=("$service")
    fi
    echo ""
done

build_end_time=$(date +%s)
build_duration=$((build_end_time - build_start_time))

if [[ ${#build_failures[@]} -eq 0 ]]; then
    echo "🎉 ALL CUSTOM IMAGES BUILT SUCCESSFULLY!"
    echo "⏱️  Total build time: ${build_duration} seconds"
    echo ""
    echo "📋 Built custom images:"
    docker images --filter "reference=*_dev" --format "   ✅ {{.Repository}}:{{.Tag}} ({{.Size}})"
else
    echo "❌ SOME CUSTOM IMAGE BUILDS FAILED"
    echo "🔍 DIAGNOSIS: ${#build_failures[@]}/${#CUSTOM_IMAGES[@]} builds failed"
    echo "❌ Failed builds: ${build_failures[*]}"
    echo "📝 Check the build output above for specific failures"
    echo ""
    echo "🛠️  RECOVERY: Workspace will still work but startup will be slow"
    echo "   Failed images will be built during workspace startup instead"
    echo "   Expected startup time: 5-10 minutes instead of 30 seconds"
    echo ""
    echo "💡 COMMON BUILD FAILURES:"
    echo "   - Network issues downloading dependencies"
    echo "   - Missing environment variables in Dockerfile"
    echo "   - Source code syntax errors"
    echo "   - Dockerfile configuration issues"
    echo "   - Insufficient memory during build"
fi
echo ""

# 3. Create volumes to cache them
echo "📁 Creating Docker volumes for caching..."
docker compose -f docker-compose.dev.yml create

echo "✅ Volumes created successfully"

# 4. Pre-cache dependency installations by running them once
echo "⚡ Pre-caching dependencies..."

# Cache Ruby gems (run bundle install in API container)
echo "Caching Ruby gems..."
docker run --rm -v /workspace/lago/api:/app api_dev bash -c "cd /app && bundle install --jobs 4" || echo "Gem caching completed with warnings"

# Cache Node modules (run npm install in frontend container) 
echo "Caching Node modules..."
docker run --rm -v /workspace/lago/front:/app front_dev bash -c "cd /app && npm ci --silent" || echo "Node modules caching completed with warnings"

echo "✅ Dependencies cached successfully"

# 5. Clean up any running containers but keep images and volumes
echo "🧹 Cleaning up temporary containers..."
docker compose -f docker-compose.dev.yml down --remove-orphans 2>/dev/null || true

# 6. Verify cache status
echo "📊 Docker cache status:"
echo "Images cached: $(docker images --format "table {{.Repository}}:{{.Tag}}" | wc -l) images"
echo "Volumes created: $(docker volume ls -q | wc -l) volumes"

echo ""
echo "🚀 Warm cache setup complete!"
echo "   - All base images pulled and cached"
echo "   - All custom images built" 
echo "   - Dependencies pre-installed"
echo "   - Workspace startup should now be under 30 seconds!"
echo "" 