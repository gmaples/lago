#!/bin/bash
# =============================================================================
# CHECK CONTAINER STATUS
# =============================================================================

set -euo pipefail

cd /workspace/lago
export LAGO_PATH="/workspace/lago"

echo "=== Container Status ==="
docker compose -f docker-compose.dev.yml ps

echo -e "\n=== Health Check ==="
./gitpod-script/lago_health_check.sh --check-only 