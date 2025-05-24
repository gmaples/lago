#!/bin/bash
# =============================================================================
# Git Submodule Fix Script for Lago
# =============================================================================
#
# Purpose:
#   This script handles git submodule initialization issues gracefully,
#   particularly for cases where specific commits are not available.
#
# =============================================================================

set -e

echo "=== Fixing Git Submodules for Lago ==="

# Function to check if a directory has git content
has_git_content() {
    local dir="$1"
    [ -d "$dir/.git" ] || [ -f "$dir/.git" ]
}

# Function to check if a directory has source files
has_source_files() {
    local dir="$1"
    [ -n "$(find "$dir" -name "*.rb" -o -name "*.js" -o -name "*.ts" -o -name "*.vue" | head -1)" ]
}

# Initialize submodules with error handling
echo "Attempting to initialize git submodules..."

if git submodule update --init --recursive; then
    echo "✅ Git submodules initialized successfully!"
    exit 0
fi

echo "⚠️  Standard submodule initialization failed. Trying recovery methods..."

# Method 1: Try to sync and update
echo "🔄 Trying submodule sync and update..."
if git submodule sync --recursive && git submodule update --init --recursive; then
    echo "✅ Submodules recovered with sync method!"
    exit 0
fi

# Method 2: Reset and try again
echo "🔄 Trying reset and reinitialize..."
git submodule foreach --recursive git reset --hard
if git submodule update --init --recursive; then
    echo "✅ Submodules recovered with reset method!"
    exit 0
fi

# Method 3: Try to clone the main branches directly
echo "🔄 Trying to clone main branches directly..."

# Check API submodule
if ! has_git_content "api" || ! has_source_files "api"; then
    echo "📥 Cloning lago-api main branch..."
    rm -rf api
    if git clone https://github.com/getlago/lago-api.git api; then
        echo "✅ API submodule cloned successfully"
    else
        echo "❌ Failed to clone API repository"
    fi
fi

# Check Front submodule
if ! has_git_content "front" || ! has_source_files "front"; then
    echo "📥 Cloning lago-front main branch..."
    rm -rf front
    if git clone https://github.com/getlago/lago-front.git front; then
        echo "✅ Front submodule cloned successfully"
    else
        echo "❌ Failed to clone Front repository"
    fi
fi

# Final verification
echo "🔍 Verifying submodule status..."

api_status="❌ Missing"
front_status="❌ Missing"

if has_git_content "api" && has_source_files "api"; then
    api_status="✅ OK"
fi

if has_git_content "front" && has_source_files "front"; then
    front_status="✅ OK"
fi

echo "📊 Submodule Status:"
echo "  API:   $api_status"
echo "  Front: $front_status"

if [[ "$api_status" == "✅ OK" && "$front_status" == "✅ OK" ]]; then
    echo "🎉 All submodules are ready!"
    exit 0
else
    echo "⚠️  Some submodules may have issues, but continuing anyway..."
    echo "   You can manually fix them later with:"
    echo "   git submodule update --init --recursive"
    exit 0  # Don't fail the build for submodule issues
fi 