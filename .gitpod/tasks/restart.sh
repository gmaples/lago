#!/bin/bash
# =============================================================================
# RESTART LAGO SERVICES
# =============================================================================

set -euo pipefail

cd /workspace/lago
export LAGO_PATH="/workspace/lago"

echo "Restarting Lago services..."
./gitpod-script/lago_health_check.sh --restart
echo "Services restarted!" 