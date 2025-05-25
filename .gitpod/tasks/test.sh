#!/bin/bash
# =============================================================================
# RUN LAGO TESTS
# =============================================================================

set -euo pipefail

cd /workspace/lago
export LAGO_PATH="/workspace/lago"

echo "Running Lago tests..."
docker compose -f docker-compose.dev.yml run --rm api bundle exec rspec 