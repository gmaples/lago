#!/bin/bash
# =============================================================================
# GITPOD PREBUILD INITIALIZATION SCRIPT
# =============================================================================
# 
# This script runs during workspace image creation (prebuild phase).
# This script prepares the environment, files, and pre-caches Docker images
# for lightning-fast workspace startup.
#
# =============================================================================

set -euo pipefail

echo "=== Lago Gitpod Prebuild Setup ==="

# Initialize git submodules with robust error handling
echo "Initializing git submodules..."
bash fix_git_submodules.sh

# Create environment files if they don't exist
echo "Setting up environment files..."
if [ ! -f .env ]; then
  echo "Creating .env file..."
  echo "LAGO_RSA_PRIVATE_KEY=\"$(openssl genrsa 2048 | base64 | tr -d '\n')\"" > .env
  echo "LAGO_DISABLE_SEGMENT=true" >> .env
  echo "LAGO_DISABLE_WALLET_REFRESH=true" >> .env
  echo "LAGO_REDIS_CACHE_PASSWORD=" >> .env
  echo "LAGO_AWS_S3_ENDPOINT=" >> .env
fi

# Create development environment file if it doesn't exist
if [ ! -f .env.development.default ]; then
  echo "Creating .env.development.default file..."
  # Use default development configuration
  cp .env.development.default.example .env.development.default 2>/dev/null || {
    echo "Creating basic development configuration..."
    echo "# Default development environment" > .env.development.default
  }
fi

# Set up persistent environment in bashrc
echo "Setting up persistent environment variables..."
if ! grep -q "LAGO_PATH" ~/.bashrc; then
  echo 'export LAGO_PATH="/workspace/lago"' >> ~/.bashrc
fi

# Run warm cache operations to pre-build Docker images
echo "Running Docker warm cache operations..."
bash .gitpod/tasks/warm-cache.sh

echo "Prebuild setup complete!" 