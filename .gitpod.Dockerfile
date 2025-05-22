# Use Gitpod’s full-featured base image which includes most common developer tools and languages.
FROM gitpod/workspace-full

# Update package lists and install Docker CLI and Docker Compose.
# These are required to build and run Lago's service containers inside Gitpod.
RUN sudo apt-get update && \
    sudo apt-get install -y \
        docker.io \
        docker-compose && \
    sudo systemctl enable docker
