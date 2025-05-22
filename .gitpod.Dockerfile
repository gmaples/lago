# This Dockerfile defines a custom image that Gitpod will use to create the workspace.
# It builds on top of Gitpod's official full-featured base image and adds Docker-related tools.

FROM gitpod/workspace-full  # Use Gitpod’s full-featured base image which includes most common developer tools and languages.

# Update system packages and install Docker-related tools
RUN sudo apt-get update && \  # Refresh the package list from Ubuntu/Debian repositories.
    sudo apt-get install -y \  # Install required packages (-y skips interactive confirmation).
        docker.io \  # The Docker engine binary – allows building and running containers.
        docker-compose && \  # Docker Compose tool – used for multi-container orchestration (used by Lago).
    sudo systemctl enable docker  # Enable Docker daemon so it can be started within the container.
