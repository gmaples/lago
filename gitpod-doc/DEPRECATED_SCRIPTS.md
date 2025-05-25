# Deprecated Scripts Notice

The following scripts have been deprecated and replaced by the comprehensive `lago_health_check.sh` script:

## Deprecated Files

### Renamed (for safety)
- `start_lago_dev.sh.deprecated` - Basic development startup
- `setup_and_restart.sh.deprecated` - Setup and restart functionality  
- `test_production.sh.deprecated` - Limited production testing

### Removed (security risk)
- `bulk_env_import.sh` - **REMOVED** - Contained hardcoded credentials

## Migration Guide

### Old Command → New Command

```bash
# OLD: Basic startup
./start_lago_dev.sh
# NEW: Comprehensive startup with health checks
./lago_health_check.sh

# OLD: Setup and restart
./setup_and_restart.sh  
# NEW: Full restart with validation
./lago_health_check.sh --restart

# OLD: Production testing
./test_production.sh
# NEW: Comprehensive health check
./lago_health_check.sh --check-only

# OLD: Environment import (SECURITY RISK)
./bulk_env_import.sh
# NEW: Use Gitpod environment variables
eval $(gp env -e)
```

## Why These Scripts Were Replaced

### Security Issues
- `bulk_env_import.sh` contained hardcoded credentials in plain text
- No validation of environment variable security
- Risk of credential exposure in git history

### Functionality Gaps
- Limited error handling and recovery
- No comprehensive health checking
- No CORS validation
- No end-to-end testing
- No service dependency validation

### Maintenance Issues
- Multiple overlapping scripts with similar functionality
- Inconsistent error handling
- No unified logging or reporting
- Manual intervention required for failures

## Benefits of New System

### Comprehensive Testing
- Tests all 18+ Lago services
- Validates ports, connectivity, and functionality
- Checks CORS configuration
- End-to-end functionality verification

### Security Improvements
- No hardcoded credentials
- Environment variable validation
- Secure defaults and fallbacks
- Audit trail logging

### Operational Excellence
- Idempotent execution
- Automatic cleanup and recovery
- Detailed logging and debugging
- Configurable timeouts and options

## Safe Removal

The deprecated files can be safely removed after confirming the new script works in your environment:

```bash
# Test the new script first
./lago_health_check.sh --check-only

# If successful, remove deprecated files
rm *.deprecated
rm DEPRECATED_SCRIPTS.md
```

## Support

If you encounter issues with the migration:

1. Use the new script with verbose mode: `./lago_health_check.sh --verbose`
2. Check the health check documentation: `README_HEALTH_CHECK.md`
3. Compare old and new functionality to ensure all use cases are covered 