#!/bin/bash
# =============================================================================
# PREBUILD OPTIMIZATION VERIFICATION SCRIPT
# =============================================================================
# 
# This script verifies that all prebuild optimizations were applied successfully
# and provides a performance report.
#
# =============================================================================

set -euo pipefail

echo "🔍 PREBUILD OPTIMIZATION VERIFICATION"
echo "====================================="
echo ""

# Check if prebuild completion marker exists
echo "1. ✅ PREBUILD STATUS CHECK"
if [[ -f /workspace/.gitpod_prebuild_complete ]]; then
    echo "   ✅ Prebuild completed successfully"
    echo "   📅 Completed: $(cat /workspace/.gitpod_prebuild_timestamp 2>/dev/null || echo 'timestamp unavailable')"
else
    echo "   ❌ Prebuild marker not found"
fi
echo ""

# Check Docker images
echo "2. 🐳 DOCKER IMAGES VERIFICATION"
cached_images=$(docker images --filter "reference=*dev" --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | wc -l)
total_images=$(docker images --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | wc -l)

echo "   📊 Total Docker images: $total_images"
echo "   📦 Cached dev images: $cached_images"

if [[ $cached_images -ge 3 ]]; then
    echo "   ✅ Docker images successfully cached"
    echo "   📋 Available cached images:"
    docker images --filter "reference=*dev" --format "      ✅ {{.Repository}}:{{.Tag}} ({{.Size}})" 2>/dev/null
else
    echo "   ❌ Insufficient Docker cache (expected 3+ images)"
fi
echo ""

# Check Docker volumes
echo "3. 📁 DOCKER VOLUMES VERIFICATION"
volume_count=$(docker volume ls -q 2>/dev/null | wc -l)
echo "   📊 Docker volumes: $volume_count"

expected_volumes=("lago_postgres_data_dev" "lago_redis_data_dev" "lago_front_node_modules_dev")
for vol in "${expected_volumes[@]}"; do
    if docker volume ls 2>/dev/null | grep -q "$vol"; then
        echo "   ✅ $vol"
    else
        echo "   ❌ $vol (missing)"
    fi
done
echo ""

# Check configuration files
echo "4. ⚙️ CONFIGURATION FILES VERIFICATION"
config_files=(
    ".env"
    ".env.development"
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

# Check environment optimizations
echo "5. 🚀 ENVIRONMENT OPTIMIZATIONS"
if grep -q "LAGO_OPTIMIZATIONS=enabled" ~/.bashrc 2>/dev/null; then
    echo "   ✅ Performance optimizations enabled"
else
    echo "   ❌ Performance optimizations not found"
fi

if [[ -f ~/.docker/config.json ]]; then
    if grep -q '"buildkit": true' ~/.docker/config.json 2>/dev/null; then
        echo "   ✅ Docker BuildKit optimization enabled"
    else
        echo "   ⚠️  Docker config exists but BuildKit not properly configured"
    fi
else
    echo "   ❌ Docker config optimizations missing"
fi
echo ""

# Calculate optimization score
echo "6. 📊 OPTIMIZATION PERFORMANCE SCORE"
optimization_score=0

[[ -f /workspace/.gitpod_prebuild_complete ]] && ((optimization_score++))
[[ $cached_images -ge 3 ]] && ((optimization_score++))
[[ -f "/workspace/lago/.env.development" ]] && ((optimization_score++))
[[ -f "/workspace/lago/api/.rsa_private.pem" ]] && ((optimization_score++))
grep -q "LAGO_OPTIMIZATIONS=enabled" ~/.bashrc 2>/dev/null && ((optimization_score++))

echo "   🎯 Score: $optimization_score/5"

if [[ $optimization_score -eq 5 ]]; then
    echo "   🏆 PERFECT - All optimizations applied!"
    echo "   ⚡ Expected startup: 30-60 seconds"
elif [[ $optimization_score -ge 3 ]]; then
    echo "   ✅ GOOD - Most optimizations applied"
    echo "   ⚡ Expected startup: 1-2 minutes"
else
    echo "   ⚠️  POOR - Many optimizations missing"
    echo "   🐌 Expected startup: 3-5 minutes"
fi

echo ""
echo "🎉 VERIFICATION COMPLETE!"
echo "Use this to verify your prebuild optimizations are working correctly."
echo "" 