# Lago Development Environment Startup Guide

> **For Gitpod Prebuild Issues**: See [README_GITPOD_PREBUILD.md](README_GITPOD_PREBUILD.md) for detailed prebuild troubleshooting and configuration information.

## Quick Start (Post-Reboot/New Shell)

If you're starting fresh after a reboot or in a new shell, use this command to ensure all environment variables are properly set:

```bash
# Make sure you're in the right directory
cd /workspace/lago

# Start the development environment with proper env vars
./start_lago_dev.sh up -d
```

## Environment Variables

The application requires these environment variables to work properly:

- `LAGO_PATH`: Path to the lago workspace (set automatically by the startup script)
- `GITPOD_WORKSPACE_ID`: Gitpod workspace identifier (provided by Gitpod)
- `GITPOD_WORKSPACE_CLUSTER_HOST`: Gitpod cluster host (provided by Gitpod)

## Persistent Environment Setup

The `LAGO_PATH` variable is added to `~/.bashrc` automatically, but you can also source it manually:

```bash
source ~/.bashrc
```

## Common Commands

```bash
# Start all services
./start_lago_dev.sh up -d

# Stop all services  
./start_lago_dev.sh down

# View logs
./start_lago_dev.sh logs -f

# Restart specific service
./start_lago_dev.sh restart api

# Check status
./start_lago_dev.sh ps
```

## Troubleshooting

### "LAGO_PATH not set" errors
If you see warnings about LAGO_PATH not being set, run:
```bash
export LAGO_PATH=/workspace/lago
```

### CORS/GraphQL errors
Make sure both API and frontend containers have the correct Gitpod URLs:
```bash
# Check API container environment
docker exec lago_api_dev env | grep -E "(LAGO_FRONT_URL|LAGO_API_URL)"

# Should show:
# LAGO_API_URL=https://3000-{workspace-id}.{cluster-host}
# LAGO_FRONT_URL=https://8080-{workspace-id}.{cluster-host}
```

### Container startup issues
If containers fail to start, check for environment variable issues:
```bash
./start_lago_dev.sh down
./start_lago_dev.sh up -d
```

## Access URLs

Once started, the application is available at:
- **Frontend**: `https://8080-{workspace-id}.{cluster-host}`
- **API**: `https://3000-{workspace-id}.{cluster-host}`

The exact URLs will be displayed when you run the startup script. 