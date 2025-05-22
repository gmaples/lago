#!/bin/bash
set -e  # Exit immediately if any command fails. This prevents partial setup states.

# Start the Docker daemon manually.
# Gitpod containers are Linux VMs but Docker is not started automatically.
sudo service docker start

# Add the current user (`gitpod`) to the Docker group.
# This step allows running Docker commands without needing `sudo`.
# In newer Gitpod versions, this might be preconfigured, but we include it for safety.
sudo usermod -aG docker gitpod

# Print Docker version to verify that Docker is installed and working correctly.
docker --version
