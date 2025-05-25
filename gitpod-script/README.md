# Gitpod Scripts Directory

This directory contains custom scripts that support the Lago Gitpod development environment but are not part of the core infrastructure.

## Contents

### Health Check System
- **`lago_health_check.sh`** - Comprehensive health check and startup script for the Lago development environment

## Purpose

The `lago_health_check.sh` script provides:
- **Idempotent execution** - Safe to run multiple times
- **Comprehensive service health checks** - Database, Redis, API, Frontend
- **CORS error detection** - Validates cross-origin requests
- **URL validation and routing tests** - Ensures proper Gitpod URL configuration
- **End-to-end functionality verification** - Complete system validation
- **Automatic cleanup and recovery** - Handles service restart scenarios
- **Fast-fail detection** - Quickly identifies missing services
- **Detailed logging and debugging** - Comprehensive error reporting

## Usage

```bash
# Full startup and health check
./gitpod-script/lago_health_check.sh

# Start services only
./gitpod-script/lago_health_check.sh --start-only

# Check existing services
./gitpod-script/lago_health_check.sh --check-only

# Stop all services
./gitpod-script/lago_health_check.sh --stop

# Restart everything
./gitpod-script/lago_health_check.sh --restart

# Enable verbose logging
./gitpod-script/lago_health_check.sh --verbose
```

## Integration

This script is integrated into the Gitpod task system:
- Called by `.gitpod/tasks/startup.sh` for initial environment setup
- Called by `.gitpod/tasks/status.sh` for health monitoring
- Called by `.gitpod/tasks/restart.sh` for service management

## Organization

These scripts are separated from the core infrastructure to:
- **Keep mainline scripts clean** - Core git and Docker setup remain in root
- **Enable independent testing** - Custom scripts can be tested separately
- **Facilitate maintenance** - Changes to custom logic don't affect core setup
- **Support modularity** - Additional custom scripts can be added here 