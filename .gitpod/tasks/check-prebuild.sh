#!/bin/bash
# =============================================================================
# PREBUILD VERIFICATION SCRIPT
# =============================================================================
# 
# This script checks if prebuild optimizations were actually applied
# and provides evidence of what was cached/optimized.
#
# =============================================================================

set -euo pipefail

echo "============================================================================="
echo "🔍 PREBUILD OPTIMIZATION VERIFICATION"
echo "============================================================================="
echo ""

# Check if prebuild completion marker exists
echo "1. Checking prebuild completion status..."
if [[ -f /workspace/.gitpod_prebuild_complete ]]; then
    echo "✅ PREBUILD COMPLETED"
    echo "   Timestamp: $(cat /workspace/.gitpod_prebuild_timestamp 2>/dev/null || echo 'unavailable')"
else
    echo "❌ NO PREBUILD DETECTED"
    echo "   This workspace was not built with prebuild optimizations"
fi
echo ""

# Check Docker images
echo "2. Checking Docker image cache..."
cached_images=$(docker images --filter "reference=*dev" --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | wc -l)
total_images=$(docker images --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | wc -l)

echo "   Total Docker images: $total_images"
echo "   Cached dev images: $cached_images"

if [[ $cached_images -ge 3 ]]; then
    echo "✅ DOCKER IMAGES CACHED"
    echo "   Expected fast startup!"
    docker images --filter "reference=*dev" --format "   📦 {{.Repository}}:{{.Tag}} ({{.Size}})"
else
    echo "❌ INSUFFICIENT DOCKER CACHE"
    echo "   Only $cached_images dev images found - startup will be slow"
fi
echo ""

# Check Docker volumes
echo "3. Checking Docker volumes..."
volume_count=$(docker volume ls -q 2>/dev/null | wc -l)
echo "   Docker volumes: $volume_count"

# Check specific volumes
expected_volumes=("lago_postgres_data_dev" "lago_redis_data_dev" "lago_front_node_modules_dev")
for vol in "${expected_volumes[@]}"; do
    if docker volume ls | grep -q "$vol"; then
        echo "   ✅ $vol"
    else
        echo "   ❌ $vol (missing)"
    fi
done
echo ""

# Check pre-generated files
echo "4. Checking pre-generated configuration files..."
config_files=(
    ".env"
    ".env.development"
    ".env.development.default"
    "api/.rsa_private.pem"
    "api/.rsa_public.pem"
)

for file in "${config_files[@]}"; do
    if [[ -f "/workspace/lago/$file" ]]; then
        echo "   ✅ $file"
    else
        echo "   ❌ $file (missing)"
    fi
done
echo ""

# Check directory structure
echo "5. Checking pre-created directories..."
directories=(
    "api/log"
    "api/tmp/pids"
    "front/dist"
    "front/node_modules"
)

for dir in "${directories[@]}"; do
    if [[ -d "/workspace/lago/$dir" ]]; then
        echo "   ✅ $dir"
    else
        echo "   ❌ $dir (missing)"
    fi
done
echo ""

# Check environment optimizations
echo "6. Checking environment optimizations..."
if grep -q "LAGO_OPTIMIZATIONS=enabled" ~/.bashrc 2>/dev/null; then
    echo "   ✅ Performance optimizations in ~/.bashrc"
else
    echo "   ❌ No performance optimizations found"
fi

if [[ -f ~/.docker/config.json ]]; then
    echo "   ✅ Docker config optimizations"
else
    echo "   ❌ No Docker config optimizations"
fi
echo ""

# Check dependency cache effectiveness
echo "7. Checking dependency cache status..."

# Ruby gems
if [[ -d "api/vendor/bundle" ]] || docker run --rm -v /workspace/lago/api:/app api_dev bash -c "gem list | wc -l" 2>/dev/null | grep -q "[0-9]"; then
    echo "   ✅ Ruby gems cached"
else
    echo "   ❌ Ruby gems not cached"
fi

# Node modules
if [[ -d "front/node_modules" ]] && [[ "$(ls -A front/node_modules 2>/dev/null | wc -l)" -gt 10 ]]; then
    echo "   ✅ Node modules cached ($(ls front/node_modules | wc -l) packages)"
else
    echo "   ❌ Node modules not cached"
fi
echo ""

# Estimate startup performance
echo "8. Startup performance estimation..."
optimization_score=0

[[ -f /workspace/.gitpod_prebuild_complete ]] && ((optimization_score++))
[[ $cached_images -ge 3 ]] && ((optimization_score++))
[[ -f "/workspace/lago/.env.development" ]] && ((optimization_score++))
[[ -f "/workspace/lago/api/.rsa_private.pem" ]] && ((optimization_score++))
grep -q "LAGO_OPTIMIZATIONS=enabled" ~/.bashrc 2>/dev/null && ((optimization_score++))

echo "   Optimization score: $optimization_score/5"

if [[ $optimization_score -ge 4 ]]; then
    echo "   🚀 EXCELLENT - Expected startup: 30-60 seconds"
elif [[ $optimization_score -ge 2 ]]; then
    echo "   ⚡ GOOD - Expected startup: 1-2 minutes"
else
    echo "   🐌 POOR - Expected startup: 3-5 minutes"
fi

echo ""
echo "============================================================================="
echo "Run this script after starting a new workspace to verify optimizations!"
echo "=============================================================================" 