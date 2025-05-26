# Deprecated Files

This directory contains files that are no longer used in the Lago codebase but are preserved for historical reference.

## Files in this directory:

### `bootstrap.sh.deprecated`
- **Deprecated**: 2025-05-26
- **Reason**: This script was used for basic system package installation but is no longer needed
- **Replacement**: Package installation is now handled by the Gitpod Dockerfile and prebuild process
- **Original purpose**: Install git, curl, Node.js and npm

### `.env.gitpod`
- **Deprecated**: 2025-05-25
- **Reason**: This file contained hardcoded Gitpod workspace URLs that were outdated and no longer functional
- **Replacement**: Environment variables are now dynamically set using Gitpod's built-in environment variables (`GITPOD_WORKSPACE_ID` and `GITPOD_WORKSPACE_CLUSTER_HOST`) directly in `docker-compose.dev.yml`
- **Original content**: Hardcoded URLs for workspace `gmaples-lago-8tij4u80njt` which is no longer valid

### `setup-gitpod-env.sh`
- **Deprecated**: 2025-05-25  
- **Reason**: This script generated the `.env.gitpod` file but was never actually called by any other scripts or configuration
- **Replacement**: Dynamic environment variables are handled directly in docker-compose configuration

### `setup_and_restart.sh.deprecated`
- **Deprecated**: 2025-05-25
- **Reason**: Legacy startup script with unreliable error handling and incomplete functionality
- **Replacement**: Comprehensive `lago_health_check.sh` script with idempotent execution and full health validation

### `start_lago_dev.sh.deprecated`
- **Deprecated**: 2025-05-25
- **Reason**: Simple startup script without health checks or error recovery
- **Replacement**: Robust startup system with health validation and automatic recovery

### `test_production.sh.deprecated`
- **Deprecated**: 2025-05-25
- **Reason**: Production testing script that was not maintained and potentially unsafe
- **Replacement**: Comprehensive health check system with production-safe validation

### `.gitpod.yml.deprecated`
- **Deprecated**: 2025-05-25
- **Reason**: Original Gitpod configuration before modular refactoring
- **Replacement**: Modular `.gitpod.yml` with separate task scripts in `.gitpod/tasks/`

### `README_STARTUP.md.deprecated`
- **Deprecated**: 2025-05-26
- **Reason**: Startup documentation that referenced deprecated `start_lago_dev.sh` script
- **Replacement**: Updated README.md with health check system documentation

### `README_GITPOD_PREBUILD.md.deprecated`
- **Deprecated**: 2025-05-26
- **Reason**: Prebuild documentation that referenced deprecated startup scripts
- **Replacement**: Updated documentation in `.gitpod/README.md` and `gitpod-doc/` directory

## Current Implementation

The current Lago development environment uses dynamic Gitpod URLs by leveraging environment variables directly in `docker-compose.dev.yml`:

```yaml
environment:
  - API_URL=https://3000-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}
  - APP_DOMAIN=https://8080-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}
```

This approach ensures URLs are always current and eliminates the need for static configuration files.

## Migration Notes

All functionality from these deprecated scripts has been replaced by:
- **Comprehensive Health Check System**: `gitpod-script/lago_health_check.sh`
- **Modular Gitpod Tasks**: Scripts in `.gitpod/tasks/` directory
- **Dynamic Environment Configuration**: Direct environment variable usage
- **Robust Error Handling**: Idempotent operations with automatic recovery 