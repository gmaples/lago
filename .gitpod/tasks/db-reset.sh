#!/bin/bash
# =============================================================================
# RESET LAGO DATABASE
# =============================================================================

set -euo pipefail

cd /workspace/lago
export LAGO_PATH="/workspace/lago"

echo "Resetting Lago database..."
docker compose -f docker-compose.dev.yml run --rm api bundle exec rails db:reset
echo "Database reset complete!" 