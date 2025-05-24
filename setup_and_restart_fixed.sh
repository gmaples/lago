#!/bin/bash

echo "=== Lago Container Restart Script (Fixed) ==="
echo

# Set the LAGO_PATH environment variable
export LAGO_PATH=/workspace/lago
echo "Setting LAGO_PATH=$LAGO_PATH"
echo

# Check if Docker daemon is running, start if not
echo "Checking Docker daemon status..."
if ! docker info >/dev/null 2>&1; then
    echo "Docker daemon not running. Attempting to start..."
    sudo service docker start
    
    # Wait for Docker to start
    echo "Waiting for Docker daemon to start..."
    for i in {1..30}; do
        if docker info >/dev/null 2>&1; then
            echo "Docker daemon started successfully!"
            break
        fi
        echo "Waiting... ($i/30)"
        sleep 2
    done
    
    if ! docker info >/dev/null 2>&1; then
        echo "ERROR: Failed to start Docker daemon"
        echo "Try running manually: sudo service docker start"
        exit 1
    fi
else
    echo "Docker daemon is already running."
fi
echo

# Create the .env file
echo "Creating .env file..."
cat > .env << EOF
# Basic .env file for Lago development
LAGO_RSA_PRIVATE_KEY="${LAGO_RSA_PRIVATE_KEY}"
LAGO_DISABLE_SEGMENT=true
LAGO_DISABLE_WALLET_REFRESH=true
LAGO_REDIS_CACHE_PASSWORD=
LAGO_AWS_S3_ENDPOINT=
EOF

# Create the .env.development.default file
echo "Creating .env.development.default file..."
cat > .env.development.default << EOF
# Default development environment variables for Lago
DATABASE_URL=postgresql://lago:changeme@db:5432/lago
POSTGRES_USER=lago
POSTGRES_PASSWORD=changeme
POSTGRES_DB=lago
POSTGRES_HOST=db
POSTGRES_PORT=5432
REDIS_URL=redis://redis:6379
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=
RAILS_ENV=development
RAILS_LOG_TO_STDOUT=true
LAGO_API_URL=https://api.lago.dev
LAGO_FRONT_URL=https://app.lago.dev
SECRET_KEY_BASE=${SECRET_KEY_BASE}
LAGO_RSA_PRIVATE_KEY=${LAGO_RSA_PRIVATE_KEY}
LAGO_ENCRYPTION_PRIMARY_KEY=${LAGO_ENCRYPTION_PRIMARY_KEY}
LAGO_ENCRYPTION_DETERMINISTIC_KEY=${LAGO_ENCRYPTION_DETERMINISTIC_KEY}
LAGO_ENCRYPTION_KEY_DERIVATION_SALT=${LAGO_ENCRYPTION_KEY_DERIVATION_SALT}
LAGO_DISABLE_SEGMENT=true
LAGO_DISABLE_WALLET_REFRESH=true
LAGO_DISABLE_SIGNUP=false
LAGO_DISABLE_PDF_GENERATION=false
LAGO_SIDEKIQ_WEB=true
LAGO_USE_AWS_S3=false
LAGO_AWS_S3_ACCESS_KEY_ID=development-key
LAGO_AWS_S3_SECRET_ACCESS_KEY=development-secret
LAGO_AWS_S3_REGION=us-east-1
LAGO_AWS_S3_BUCKET=lago-development
LAGO_AWS_S3_ENDPOINT=
LAGO_USE_GCS=false
LAGO_GCS_PROJECT=
LAGO_GCS_BUCKET=
LAGO_FROM_EMAIL=
LAGO_SMTP_ADDRESS=
LAGO_SMTP_PORT=587
LAGO_SMTP_USERNAME=
LAGO_SMTP_PASSWORD=
LAGO_PDF_URL=http://pdf:3000
LAGO_REDIS_CACHE_URL=redis://redis:6379
LAGO_REDIS_CACHE_PASSWORD=
LAGO_OAUTH_PROXY_URL=https://proxy.getlago.com
GOOGLE_AUTH_CLIENT_ID=
GOOGLE_AUTH_CLIENT_SECRET=
LAGO_LICENSE=
LAGO_CREATE_ORG=false
LAGO_ORG_USER_PASSWORD=
LAGO_ORG_USER_EMAIL=
LAGO_ORG_NAME=
LAGO_ORG_API_KEY=
EOF

echo "Environment files created successfully!"
echo

# Stop any running containers
echo "Stopping existing containers..."
export LAGO_PATH=/workspace/lago
docker-compose -f docker-compose.dev.yml down --remove-orphans

echo
echo "Starting containers with fresh build..."
docker-compose -f docker-compose.dev.yml up --build -d

echo
echo "Waiting for containers to start..."
sleep 15

echo
echo "Container status:"
docker-compose -f docker-compose.dev.yml ps

echo
echo "Following logs (press Ctrl+C to stop watching):"
docker-compose -f docker-compose.dev.yml logs -f 