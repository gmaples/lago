#!/bin/bash
# =============================================================================
# VIEW CONTAINER LOGS
# =============================================================================

set -euo pipefail

cd /workspace/lago
export LAGO_PATH="/workspace/lago"
docker compose -f docker-compose.dev.yml logs -f 