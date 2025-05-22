# Use Gitpod's official full-featured workspace image
FROM gitpod/workspace-full

# Install Docker and Docker Compose
RUN sudo apt-get update && \
    sudo apt-get install -y docker.io docker-compose && \
    sudo systemctl enable docker && \
    # Ensure the 'docker' group exists
    sudo groupadd -f docker && \
    # Add the 'gitpod' user to the 'docker' group
    sudo usermod -aG docker gitpod
