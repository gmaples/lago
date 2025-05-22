#!/bin/bash
set -e

# Start Docker service inside Gitpod container
sudo service docker start

# (Re-)add gitpod user to docker group — ensures access without sudo
sudo usermod -aG docker gitpod

# Fix permissions on the Docker socket so docker works without sudo
if [ -S /var/run/docker.sock ]; then
  sudo chmod 666 /var/run/docker.sock
fi

# Confirm Docker access (should not require sudo now)
docker --version
