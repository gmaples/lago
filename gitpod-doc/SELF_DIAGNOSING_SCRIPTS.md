# Lago Self-Diagnosing Script System

## Overview

The Lago Gitpod environment includes comprehensive self-diagnosing scripts that provide detailed feedback during prebuild and startup phases. Since the AI assistant is not available during prebuild and may not be immediately accessible during startup issues, these scripts are designed to be completely autonomous troubleshooters.

## Key Features

### 🔍 **Extensive Logging**
- Every step is logged with timestamps
- Detailed progress indicators show current status
- All output is captured to persistent log files
- Performance metrics track timing and efficiency

### 🛠️ **Self-Diagnosis**
- Automatic error detection and analysis
- Specific failure diagnosis with root cause analysis
- Clear explanation of what went wrong and why
- Recovery suggestions with exact commands to run

### 📊 **Progress Tracking**
- Step-by-step status updates
- Success/failure counters for batch operations
- Performance benchmarking against expected times
- Cache effectiveness monitoring

### 🚨 **Failure Recovery**
- Graceful degradation when components fail
- Alternative strategies when primary methods don't work
- Detailed recovery instructions for common failures
- Non-blocking warnings vs. critical failures

## Scripts

### 1. Warm Cache Script (`.gitpod/tasks/warm-cache.sh`)

**Purpose:** Runs during prebuild to cache Docker images and dependencies.

**Key Features:**
- ✅ Environment validation with detailed checks
- ✅ External image pulling with progress tracking
- ✅ Custom image building with individual failure handling
- ✅ Dependency pre-installation with fallback strategies
- ✅ Final cache summary with performance predictions

**Sample Output:**
```bash
=============================================================================
🚀 LAGO DOCKER WARM CACHE SETUP - Wed Jan 15 10:30:45 UTC 2025
=============================================================================

📋 PREBUILD PHASE: AI Assistant NOT available - Self-diagnosing mode
📝 Full log: /workspace/lago/warm_cache.log
⏰ Started at: 2025-01-15 10:30:45

🔧 STEP 1: Environment Validation
=============================================================================
📁 Changing to Lago directory: /workspace/lago
✅ Successfully changed to Lago directory
📋 Verifying critical files exist...
✅ Found: docker-compose.dev.yml
✅ Found: api/Dockerfile.dev
✅ Found: front/Dockerfile.dev
✅ Found: events-processor/Dockerfile.dev
```

**Error Example:**
```bash
❌ CRITICAL ERROR: Missing required file: api/Dockerfile.dev
🔍 DIAGNOSIS: Git checkout may be incomplete or files moved
🛠️  RECOVERY: Run 'git status' and 'git submodule update --init --recursive'
```

### 2. Verbose Startup Script (`.gitpod/tasks/startup-verbose.sh`)

**Purpose:** Runs during workspace startup with comprehensive diagnostics.

**Key Features:**
- ✅ Docker initialization with detailed status monitoring
- ✅ Pre-cache verification to assess warm cache effectiveness
- ✅ Service startup with performance metrics
- ✅ URL generation and accessibility testing
- ✅ Final status summary with useful commands

**Sample Output:**
```bash
🔧 STEP 3: Pre-Cache Verification
=============================================================================
🔍 Checking if warm cache was successful during prebuild...
📊 Docker cache status:
   Total images: 15
   Cached dev images: 3
✅ Warm cache found - custom images are pre-built
   This should make startup very fast!
📋 Available cached images:
   ✅ front_dev:latest (1.2GB)
   ✅ api_dev:latest (945MB)
   ✅ events-processor_dev:latest (156MB)
```

## Error Categories and Recovery

### 🚨 **Critical Errors (Exit 1)**
These stop execution completely:
- Missing Docker or Docker daemon not running
- Missing critical files (docker-compose.yml, Dockerfiles)
- Workspace directory not accessible
- Fundamental environment corruption

**Example Recovery:**
```bash
❌ CRITICAL ERROR: Docker daemon is not running
🔍 DIAGNOSIS: Docker service is not started
🛠️  RECOVERY: This should not happen in Gitpod prebuild
   This indicates a Gitpod environment issue
```

### ⚠️ **Non-Critical Warnings (Continue Execution)**
These log warnings but don't stop the process:
- Individual image pull failures
- Dependency installation failures
- Optional optimization failures
- Performance degradation

**Example Recovery:**
```bash
⚠️  WARNING: No cached dev images found
🔍 DIAGNOSIS: Warm cache may have failed during prebuild
🛠️  RECOVERY: Startup will be slower as images need to be built
   Expected startup time: 3-5 minutes instead of 30 seconds
```

## Log Files

### `/workspace/lago/warm_cache.log`
- Complete prebuild warm cache execution
- All image pull and build output
- Dependency installation logs
- Performance timing data

### `/workspace/lago/startup.log`
- Complete workspace startup execution
- Docker initialization details
- Service startup progress
- Health check results

## Performance Benchmarks

### **Optimal Performance (Warm Cache Working)**
- Docker initialization: 5-15 seconds
- Service startup: 10-20 seconds
- **Total startup time: 15-35 seconds** ⚡

### **Degraded Performance (Partial Cache)**
- Docker initialization: 5-15 seconds
- Service startup: 120-300 seconds (rebuilding images)
- **Total startup time: 2-5 minutes** ⚠️

### **Failed Cache (Cold Start)**
- Docker initialization: 5-15 seconds
- Service startup: 300-600 seconds (building everything)
- **Total startup time: 5-10 minutes** 🐌

## Common Failure Scenarios

### 1. **Network Issues During Prebuild**
```bash
❌ FAILED: Could not pull postgres:14.0-alpine
🔍 DIAGNOSIS: Network issue or image not found
🛠️  RECOVERY: These images will be pulled during startup instead
   This may slow down workspace startup but won't prevent it
```

### 2. **Build Failures**
```bash
❌ SOME CUSTOM IMAGE BUILDS FAILED
🔍 DIAGNOSIS: 1/3 builds failed
❌ Failed builds: front
💡 COMMON BUILD FAILURES:
   - Network issues downloading dependencies
   - Missing environment variables in Dockerfile
   - Source code syntax errors
   - Dockerfile configuration issues
   - Insufficient memory during build
```

### 3. **Docker Initialization Issues**
```bash
❌ CRITICAL ERROR: Docker failed to start within 60 seconds
🛠️  RECOVERY OPTIONS:
   1. Manual Docker start:
      sudo service docker start
      ./gitpod-script/lago_health_check.sh --restart
   
   2. Check Docker logs:
      sudo journalctl -u docker --no-pager --lines=20
   
   3. Restart workspace if Docker is completely broken
```

## Troubleshooting Commands

### **When Startup Fails:**
```bash
# Check service status
./gitpod-script/lago_health_check.sh --check-only

# View container logs
docker compose logs

# Try full restart
./gitpod-script/lago_health_check.sh --restart

# Manual debugging
docker ps -a                    # Check container status
docker compose ps               # Check compose status
docker images                   # Check available images
```

### **When Performance is Poor:**
```bash
# Check cached images
docker images --filter "reference=*dev"

# Check cache effectiveness
cat /workspace/lago/warm_cache.log | grep "SUCCESS\|FAILED"

# View startup performance
cat /workspace/lago/startup.log | grep "PERFORMANCE METRICS" -A 10
```

## Best Practices

### **For Users:**
1. **Read the console output** - Scripts provide detailed status information
2. **Check log files** - Complete execution details are always saved
3. **Follow recovery instructions** - Specific commands are provided for each failure
4. **Report persistent issues** - Include log files when asking for help

### **For Developers:**
1. **Maintain verbose output** - Every significant operation should be logged
2. **Provide specific diagnostics** - Generic "something failed" is not helpful
3. **Include recovery commands** - Users need exact commands to fix issues
4. **Test failure scenarios** - Ensure scripts handle common failure modes gracefully

## Future Enhancements

- **Automatic retry logic** for transient network failures
- **Health check integration** during prebuild phase
- **Intelligent cache validation** to detect corrupted cache states
- **Performance analytics** to track improvement over time
- **Smart recovery** that automatically attempts common fixes 