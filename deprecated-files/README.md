# Deprecated Files

This directory contains files that are no longer used in the Lago codebase but are preserved for historical reference.

## Files in this directory:

### `.env.gitpod`
- **Deprecated**: 2025-05-25
- **Reason**: This file contained hardcoded Gitpod workspace URLs that were outdated and no longer functional
- **Replacement**: Environment variables are now dynamically set using Gitpod's built-in environment variables (`GITPOD_WORKSPACE_ID` and `GITPOD_WORKSPACE_CLUSTER_HOST`) directly in `docker-compose.dev.yml`
- **Original content**: Hardcoded URLs for workspace `gmaples-lago-8tij4u80njt` which is no longer valid

### `setup-gitpod-env.sh`
- **Deprecated**: 2025-05-25  
- **Reason**: This script generated the `.env.gitpod` file but was never actually called by any other scripts or configuration
- **Replacement**: Dynamic environment variables are handled directly in docker-compose configuration

## Current Implementation

The current Lago development environment uses dynamic Gitpod URLs by leveraging environment variables directly in `docker-compose.dev.yml`:

```yaml
environment:
  - API_URL=https://3000-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}
  - APP_DOMAIN=https://8080-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}
```

This approach ensures URLs are always current and eliminates the need for static configuration files. 