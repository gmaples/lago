# Gitpod Prebuild Configuration for Lago

## Overview

This document explains the Gitpod prebuild configuration fixes implemented to resolve startup issues in the Lago development environment.

## Problem Analysis

The original Gitpod configuration had several critical issues:

### 1. **Prebuild vs Runtime Confusion**
- **Issue**: The original configuration tried to run Docker containers during the `init` phase (prebuild)
- **Problem**: Docker is NOT available during Gitpod prebuilds - only during runtime
- **Error**: `permission denied while trying to connect to the Docker daemon socket`

### 2. **Git Submodule Issues**
- **Issue**: Specific commits referenced in submodules were not available
- **Error**: `fatal: remote error: upload-pack: not our ref 3120bee1b236343e809e5a1dd0ba6f4784bbc597`
- **Problem**: Hard-coded commit references become invalid over time

### 3. **Environment Variable Persistence**
- **Issue**: Environment variables set during prebuild don't persist to runtime
- **Problem**: Containers failed to start due to missing environment configuration

## Solution Architecture

### Prebuild Phase (`init` task)
**Purpose**: Prepare the workspace image with dependencies and configuration
**Limitations**: No Docker, no running services, no network-dependent operations

**What happens during prebuild:**
1. ✅ Git submodule initialization (with fallback mechanisms)
2. ✅ Environment file creation (`.env`, `.env.development.default`)
3. ✅ Persistent environment variable setup in `~/.bashrc`
4. ✅ Dependency installation and workspace preparation

### Runtime Phase (`command` task)
**Purpose**: Start services and development environment when workspace launches
**Capabilities**: Full Docker access, network operations, service startup

**What happens during runtime:**
1. ✅ Docker daemon initialization and permission setup
2. ✅ Environment variable loading
3. ✅ Container startup with `docker-compose`
4. ✅ Health checks and status reporting

## Key Files Modified

### 1. `.gitpod.yml`
**Changes:**
- Separated prebuild tasks (in `init`) from runtime tasks (in `command`)
- Added robust error handling for git submodules
- Improved Docker initialization process
- Added multiple task options for different workflows
- Fixed port configuration to ensure public access

### 2. `.gitpod.docker-init.sh`
**Improvements:**
- Added check for already-running Docker
- Improved error handling and timeouts
- Better permission configuration
- More detailed logging and debugging information
- Graceful fallback mechanisms

### 3. `fix_git_submodules.sh` (New)
**Purpose:**
- Handle git submodule initialization failures gracefully
- Provide multiple fallback mechanisms
- Clone repositories directly if submodule fails
- Verify successful initialization

## Configuration Details

### Prebuild Tasks
```yaml
- name: Environment Setup (Prebuild)
  init: |
    # Runs during workspace image creation
    - Initialize git submodules with error handling
    - Create environment files
    - Set up persistent environment variables
    - Prepare workspace dependencies
```

### Runtime Tasks  
```yaml
- name: Environment Setup (Prebuild)
  command: |
    # Runs when workspace starts
    - Initialize Docker daemon
    - Load environment variables
    - Start Lago containers
    - Provide status information
```

### Additional Tasks
- **View Logs**: Monitor container logs in real-time
- **Container Status**: Check running containers
- **Restart Services**: Restart all Lago services
- **Run Tests**: Execute the test suite
- **Database Reset**: Reset development database

## Environment Variable Strategy

### Prebuild Environment Setup
1. **RSA Key Generation**: Create secure RSA keys for JWT tokens
2. **Basic Configuration**: Set essential environment variables
3. **Development Defaults**: Create comprehensive development configuration
4. **Persistence**: Add variables to `~/.bashrc` for persistence across sessions

### Runtime Environment Loading
1. **Path Configuration**: Set `LAGO_PATH="/workspace/lago"`
2. **Source Bashrc**: Load persistent environment variables
3. **Gitpod Integration**: Use Gitpod-specific environment variables for URLs

## Git Submodule Handling

### Primary Method
```bash
git submodule update --init --recursive
```

### Fallback Methods
1. **Sync and Update**: `git submodule sync --recursive`
2. **Reset and Retry**: `git submodule foreach --recursive git reset --hard`
3. **Direct Clone**: Clone repositories directly if submodules fail

### Verification
- Check for `.git` directories
- Verify source files are present
- Provide status reporting

## Docker Integration

### Initialization Process
1. **Availability Check**: Test if Docker is already running
2. **Service Start**: Start Docker daemon with error handling
3. **Socket Wait**: Wait for Docker socket with timeout
4. **Permission Setup**: Configure user permissions for `gitpod` user
5. **Verification**: Test Docker functionality before proceeding

### Error Handling
- Multiple start methods (service, systemctl, dockerd)
- Extended timeouts for slower environments
- Detailed error reporting and manual recovery instructions
- Graceful degradation

## Port Configuration

### Public Ports
- **8080**: Frontend Development Server (auto-preview)
- **3000**: API Server (manual access)
- **80**: Frontend Production (manual access)

### Security
- All ports configured as `public` for external access
- Automatic URL generation using Gitpod workspace variables

## Troubleshooting

### Common Issues

#### 1. Docker Permission Denied
**Symptoms**: `permission denied while trying to connect to the Docker daemon`
**Solution**: 
```bash
sudo service docker start
sudo chmod 666 /var/run/docker.sock
```

#### 2. Submodule Initialization Failed
**Symptoms**: `fatal: remote error: upload-pack: not our ref`
**Solution**: Run the fix script manually
```bash
bash fix_git_submodules.sh
```

#### 3. Environment Variables Not Set
**Symptoms**: Containers fail to start with configuration errors
**Solution**: 
```bash
export LAGO_PATH="/workspace/lago"
source ~/.bashrc
bash start_lago_dev.sh up -d
```

#### 4. Containers Not Starting
**Symptoms**: Services remain in starting state
**Solution**: Check logs and restart
```bash
docker compose -f docker-compose.dev.yml logs
docker compose -f docker-compose.dev.yml restart
```

### Manual Recovery

If automated startup fails, you can manually recover:

1. **Check Docker Status**:
   ```bash
   docker info
   sudo service docker start
   ```

2. **Fix Submodules**:
   ```bash
   bash fix_git_submodules.sh
   ```

3. **Start Services**:
   ```bash
   export LAGO_PATH="/workspace/lago"
   bash start_lago_dev.sh up -d
   ```

4. **Monitor Progress**:
   ```bash
   docker compose -f docker-compose.dev.yml logs -f
   ```

## Benefits of This Configuration

### 1. **Faster Workspace Startup**
- Dependencies installed during prebuild
- Environment configured in advance
- Only runtime services start when workspace launches

### 2. **Better Error Handling**
- Graceful fallbacks for common failures
- Detailed error messages and recovery instructions
- Non-blocking errors don't prevent development

### 3. **Improved Reliability**
- Separation of prebuild and runtime concerns
- Multiple fallback mechanisms
- Better timeout and retry logic

### 4. **Enhanced Developer Experience**
- Multiple task options for different workflows
- Clear status reporting and URLs
- Automatic browser previews

### 5. **Simplified Debugging**
- Better logging and error messages
- Status verification at each step
- Manual recovery procedures documented

## Testing the Configuration

To test the prebuild configuration:

1. **Create a new Gitpod workspace**
2. **Watch the prebuild logs** for any errors
3. **Verify workspace startup** happens without errors
4. **Check container status**: `docker compose ps`
5. **Test service access** via provided URLs

The configuration should now work reliably across different Gitpod environments and handle common failure scenarios gracefully. 