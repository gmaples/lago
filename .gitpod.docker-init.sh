#!/bin/bash
# =============================================================================
# Docker Initialization Script for Gitpod Workspace
# =============================================================================
#
# Purpose:
#   This script initializes Docker within a Gitpod workspace environment.
#   It ensures Docker is properly started, configured, and accessible to the
#   gitpod user without requiring sudo privileges.
#
# Requirements:
#   - Gitpod workspace with Docker installed
#   - Sudo privileges for the gitpod user
#   - Docker service package installed
#
# Process Flow:
#   1. Start Docker service
#   2. Wait for Docker socket to be available
#   3. Configure user permissions
#   4. Set socket permissions
#   5. Verify installation
#
# Exit Codes:
#   0 - Success
#   1 - Docker socket not found after timeout
#   2 - Docker service failed to start
#   3 - Permission configuration failed
#
# Author: Lago Team
# Last Updated: 2024
# =============================================================================

set -e  # Exit immediately if a command exits with a non-zero status

# -----------------------------------------------------------------------------
# Start Docker Service
# -----------------------------------------------------------------------------
echo "Starting Docker service..."
sudo service docker start

# -----------------------------------------------------------------------------
# Wait for Docker Socket
# -----------------------------------------------------------------------------
# The Docker socket (/var/run/docker.sock) is created when the Docker daemon
# starts. We need to wait for it to be available before proceeding.
# Timeout after 30 seconds to prevent infinite waiting.
echo "Waiting for Docker socket..."
timeout=30
while [ ! -S /var/run/docker.sock ] && [ $timeout -gt 0 ]; do
    sleep 1
    timeout=$((timeout-1))
done

# Check if socket was found
if [ ! -S /var/run/docker.sock ]; then
    echo "Error: Docker socket not found after waiting"
    echo "Please check if Docker service is properly installed and configured"
    exit 1
fi

# -----------------------------------------------------------------------------
# Configure User Permissions
# -----------------------------------------------------------------------------
# Add gitpod user to docker group to allow non-sudo Docker access
# This is required for Docker commands to work without sudo
echo "Adding gitpod user to docker group..."
sudo usermod -aG docker gitpod

# -----------------------------------------------------------------------------
# Set Socket Permissions
# -----------------------------------------------------------------------------
# Set permissions on Docker socket to allow non-root access
# 666 permissions allow read/write access for all users
echo "Setting Docker socket permissions..."
  sudo chmod 666 /var/run/docker.sock

# -----------------------------------------------------------------------------
# Verify Installation
# -----------------------------------------------------------------------------
# Run basic checks to ensure Docker is working properly
echo "Verifying Docker installation..."
docker --version

# Test Docker functionality with a basic command
echo "Testing Docker functionality..."
docker info

echo "Docker initialization complete!"
echo "Docker is now ready to use in your Gitpod workspace"
