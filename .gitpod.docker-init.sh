#!/bin/bash
set -e

# Start Docker service inside Gitpod container
sudo service docker start

# Confirm Docker access (should not require sudo now)
docker --version
