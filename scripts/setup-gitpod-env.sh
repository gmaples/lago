#!/bin/bash

# Setup dynamic Gitpod environment variables
if [ -n "$GITPOD_WORKSPACE_ID" ] && [ -n "$GITPOD_WORKSPACE_CLUSTER_HOST" ]; then
    echo "Setting up Gitpod environment variables..."
    
    # Export dynamic URLs for Gitpod environment
    export API_URL="https://3000-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
    export APP_DOMAIN="https://8080-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
    export LAGO_WEBHOOK_ATTEMPTS=0
    
    echo "API_URL set to: $API_URL"
    echo "APP_DOMAIN set to: $APP_DOMAIN"
    
    # Write to temp env file for docker-compose
    cat > .env.gitpod <<EOF
API_URL=${API_URL}
APP_DOMAIN=${APP_DOMAIN}
LAGO_WEBHOOK_ATTEMPTS=0
GITPOD_WORKSPACE_ID=${GITPOD_WORKSPACE_ID}
GITPOD_WORKSPACE_CLUSTER_HOST=${GITPOD_WORKSPACE_CLUSTER_HOST}
EOF
    
    echo "Gitpod environment variables set successfully!"
else
    echo "Not in Gitpod environment, using default values"
fi 