#!/bin/bash
# =============================================================================
# Docker Initialization Script for Gitpod Workspace (Runtime)
# =============================================================================
#
# Purpose:
#   This script initializes Docker within a Gitpod workspace environment
#   at runtime (not during prebuild). It ensures Docker is properly started,
#   configured, and accessible to the gitpod user without requiring sudo privileges.
#
# Requirements:
#   - Gitpod workspace with Docker installed
#   - Sudo privileges for the gitpod user
#   - Docker service package installed
#
# Process Flow:
#   1. Check if Docker is already running
#   2. Start Docker service if needed
#   3. Wait for Docker socket to be available
#   4. Configure user permissions
#   5. Set socket permissions
#   6. Verify installation
#
# Exit Codes:
#   0 - Success
#   1 - Docker socket not found after timeout
#   2 - Docker service failed to start
#   3 - Permission configuration failed
#
# =============================================================================

set -e  # Exit immediately if a command exits with a non-zero status

echo "=== Docker Initialization for Gitpod Runtime ==="

# -----------------------------------------------------------------------------
# Check if Docker is already running
# -----------------------------------------------------------------------------
echo "Checking if Docker is already running..."
if docker info >/dev/null 2>&1; then
    echo "✅ Docker is already running and accessible!"
    docker --version
    exit 0
fi

# -----------------------------------------------------------------------------
# Start Docker Service
# -----------------------------------------------------------------------------
echo "Starting Docker service..."
if ! sudo service docker start; then
    echo "⚠️  Failed to start Docker service, trying alternative methods..."
    
    # Try starting with systemctl if available
    if command -v systemctl >/dev/null 2>&1; then
        echo "Trying systemctl..."
        sudo systemctl start docker || echo "systemctl failed as well"
    fi
    
    # Try starting dockerd directly
    echo "Trying to start dockerd directly..."
    sudo dockerd --host=unix:///var/run/docker.sock --host=tcp://0.0.0.0:2376 >/dev/null 2>&1 &
    sleep 3
fi

# -----------------------------------------------------------------------------
# Wait for Docker Socket with more robust checking
# -----------------------------------------------------------------------------
echo "Waiting for Docker socket to be available..."
timeout=60  # Increased timeout for slower environments
attempts=0
max_attempts=30

while [ $attempts -lt $max_attempts ]; do
    if [ -S /var/run/docker.sock ]; then
        echo "✅ Docker socket found!"
        break
    fi
    
    echo "⏳ Waiting for Docker socket... (attempt $((attempts + 1))/$max_attempts)"
    sleep 2
    attempts=$((attempts + 1))
done

# Check if socket was found
if [ ! -S /var/run/docker.sock ]; then
    echo "❌ ERROR: Docker socket not found after waiting $((max_attempts * 2)) seconds"
    echo "Please check if Docker service is properly installed and configured"
    echo "You can try manually:"
    echo "  sudo service docker start"
    echo "  sudo chmod 666 /var/run/docker.sock"
    exit 1
fi

# -----------------------------------------------------------------------------
# Configure User Permissions with error handling
# -----------------------------------------------------------------------------
echo "Configuring Docker permissions for gitpod user..."

# Add gitpod user to docker group (may already be done in Dockerfile)
if ! groups gitpod | grep -q docker; then
    echo "Adding gitpod user to docker group..."
    sudo usermod -aG docker gitpod
else
    echo "✅ gitpod user is already in docker group"
fi

# -----------------------------------------------------------------------------
# Set Socket Permissions with better error handling
# -----------------------------------------------------------------------------
echo "Setting Docker socket permissions..."
if sudo chmod 666 /var/run/docker.sock; then
    echo "✅ Docker socket permissions set successfully"
else
    echo "⚠️  Warning: Failed to set socket permissions, trying alternative approach..."
    sudo chown root:docker /var/run/docker.sock
    sudo chmod 664 /var/run/docker.sock
fi

# -----------------------------------------------------------------------------
# Verify Installation with timeout
# -----------------------------------------------------------------------------
echo "Verifying Docker installation..."
docker --version

echo "Testing Docker functionality..."
timeout=30
attempts=0
max_test_attempts=15

while [ $attempts -lt $max_test_attempts ]; do
    if docker info >/dev/null 2>&1; then
        echo "✅ Docker is working correctly!"
        break
    fi
    
    echo "⏳ Waiting for Docker to be fully ready... (attempt $((attempts + 1))/$max_test_attempts)"
    sleep 2
    attempts=$((attempts + 1))
done

if ! docker info >/dev/null 2>&1; then
    echo "❌ ERROR: Docker is not responding after setup"
    echo "Docker service status:"
    sudo service docker status || echo "Cannot get Docker service status"
    echo "Socket permissions:"
    ls -la /var/run/docker.sock
    echo "User groups:"
    groups gitpod
    exit 2
fi

# Show Docker info for debugging
echo "📋 Docker system information:"
docker info | head -20

echo "🎉 Docker initialization complete!"
echo "✅ Docker is now ready to use in your Gitpod workspace"
