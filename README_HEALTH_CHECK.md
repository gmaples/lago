# Lago Health Check and Startup System

## Overview

The `lago_health_check.sh` script is a comprehensive, idempotent health check and startup solution for the Lago development environment. It replaces all legacy startup scripts with a single, robust tool that provides thorough testing and validation.

## Features

- **Idempotent Execution**: Safe to run multiple times without adverse effects
- **Comprehensive Health Checks**: Tests all services, ports, connectivity, and functionality
- **CORS Error Detection**: Validates Cross-Origin Resource Sharing configuration
- **URL Validation**: Ensures all services are accessible on correct URLs
- **End-to-End Testing**: Verifies complete system functionality
- **Automatic Recovery**: Stops, cleans, and restarts services as needed
- **Detailed Logging**: Provides verbose output and persistent logging
- **Environment Validation**: Checks required tools and environment variables

## Quick Start

```bash
# Run full startup and health check (recommended)
./lago_health_check.sh

# Only run health checks on running services
./lago_health_check.sh --check-only

# Restart everything and run full health check
./lago_health_check.sh --restart

# Enable verbose output for debugging
./lago_health_check.sh --verbose
```

## Command Line Options

| Option | Description |
|--------|-------------|
| `--start-only` | Start services without running health checks |
| `--check-only` | Run health checks on already running services |
| `--stop` | Stop all services and exit |
| `--restart` | Stop and restart all services, then run health checks |
| `--verbose` | Enable verbose output and logging |
| `--timeout=N` | Set timeout for service startup (default: 300s) |
| `--help` | Show help message |

## Health Check Categories

### 1. Environment Validation
- Validates Lago directory and required tools
- Checks Docker daemon and Compose availability
- Verifies required environment variables
- Sets up Gitpod URLs dynamically

### 2. Container Health Check
- Verifies all containers are running
- Checks container status and health
- Reports failed or missing containers

### 3. Port Accessibility Check
- Tests TCP connectivity to required ports
- Validates service accessibility
- Detects port conflicts or binding issues

### 4. Database Health Check
- Tests PostgreSQL connectivity
- Verifies database migrations
- Checks database responsiveness

### 5. Redis Health Check
- Tests Redis connectivity
- Validates Redis responsiveness
- Checks cache availability

### 6. API Health Check
- Tests `/health` endpoint
- Validates API responsiveness
- Checks CORS configuration
- Tests authentication endpoints

### 7. Frontend Health Check
- Tests frontend accessibility
- Validates frontend-to-API connectivity
- Checks static asset serving

### 8. Worker Health Check
- Verifies all worker processes
- Checks background job processors
- Validates event consumers

### 9. End-to-End Functionality Check
- Tests API authentication
- Validates GraphQL endpoint
- Checks inter-service communication

## Services Monitored

The script monitors and validates the following Lago services:

- **traefik** - Reverse proxy and load balancer
- **db** - PostgreSQL database
- **redis** - Redis cache and session store
- **api** - Main Rails API application
- **front** - Vue.js frontend application
- **api-worker** - Background job worker
- **api-events-worker** - Event processing worker
- **api-pdfs-worker** - PDF generation worker
- **api-billing-worker** - Billing processing worker
- **api-clock-worker** - Scheduled job worker
- **api-webhook-worker** - Webhook delivery worker
- **api-clock** - Clock process for scheduled jobs
- **api-events-consumer** - Event stream consumer
- **events-processor** - External event processor
- **pdf** - PDF generation service (Gotenberg)
- **mailhog** - Email testing service
- **redpanda** - Kafka-compatible message broker
- **clickhouse** - Analytics database

## Environment Variables Required

The script validates these required environment variables:

- `SECRET_KEY_BASE` - Rails application secret
- `LAGO_ENCRYPTION_PRIMARY_KEY` - Primary encryption key
- `LAGO_ENCRYPTION_DETERMINISTIC_KEY` - Deterministic encryption key
- `LAGO_ENCRYPTION_KEY_DERIVATION_SALT` - Key derivation salt
- `LAGO_RSA_PRIVATE_KEY` - RSA private key for JWT signing

## Gitpod Integration

When running in Gitpod, the script automatically:

- Loads Gitpod environment variables using `gp env -e`
- Configures dynamic URLs based on workspace ID and cluster host
- Creates `.env.gitpod` file with proper configuration
- Sets up CORS and authentication for Gitpod URLs

## Output and Logging

### Console Output
The script provides color-coded output:
- 🟢 **Green [✓ PASS]** - Successful tests
- 🔴 **Red [✗ FAIL]** - Failed tests  
- 🟡 **Yellow [⚠ WARN]** - Warnings
- 🔵 **Blue [INFO]** - Information
- 🟣 **Purple [DEBUG]** - Debug output (verbose mode)

### Log Files
When `--verbose` is enabled, detailed logs are written to:
- `${LAGO_PATH}/lago_health.log`

### Final Summary
The script provides a comprehensive summary including:
- Test pass/fail counts
- Warning count
- Execution duration
- Service URLs
- Running container status

## Troubleshooting

### Common Issues

**Environment Variables Missing**
```bash
# Load environment variables first
eval $(gp env -e)
./lago_health_check.sh
```

**Services Won't Start**
```bash
# Force restart with cleanup
./lago_health_check.sh --restart --verbose
```

**Port Conflicts**
```bash
# Stop all services and restart
./lago_health_check.sh --stop
sudo lsof -i :3000  # Check what's using port 3000
./lago_health_check.sh --start-only
```

**Docker Issues**
```bash
# Restart Docker daemon
sudo service docker restart
./lago_health_check.sh --restart
```

### Debug Mode

For detailed troubleshooting, use verbose mode:

```bash
./lago_health_check.sh --verbose --restart
```

This will:
- Show detailed debug information
- Log all actions to file
- Display container logs on failures
- Provide step-by-step execution details

## Integration with Development Workflow

### Daily Development
```bash
# Start your development session
./lago_health_check.sh

# Quick health check during development
./lago_health_check.sh --check-only

# Restart if issues arise
./lago_health_check.sh --restart
```

### CI/CD Integration
```bash
# In CI pipeline
./lago_health_check.sh --timeout=600 --verbose
```

### Production Validation
```bash
# Comprehensive production-like testing
./lago_health_check.sh --restart --verbose --timeout=600
```

## Replaced Legacy Scripts

This script replaces and makes redundant:
- `start_lago_dev.sh`
- `setup_and_restart.sh`
- `setup_and_restart_fixed.sh`
- `bulk_env_import.sh` (security risk - removed)
- `test_production.sh` (limited scope)

## Security Improvements

- **No Hardcoded Credentials**: All secrets loaded from Gitpod environment
- **Environment Variable Validation**: Ensures all required secrets are present
- **Secure Defaults**: Safe fallbacks for missing configuration
- **Audit Trail**: Verbose logging for security auditing

## Performance Considerations

- **Parallel Checks**: Independent health checks run efficiently
- **Configurable Timeouts**: Adjustable based on system performance
- **Resource Cleanup**: Automatic cleanup of failed containers and networks
- **Minimal Resource Usage**: Optimized for development environments

## Future Enhancements

Planned improvements include:
- Service dependency ordering
- Custom health check endpoints
- Integration with monitoring systems
- Automated recovery procedures
- Performance metrics collection

## Support

For issues or questions:
1. Run with `--verbose` for detailed output
2. Check the log file at `${LAGO_PATH}/lago_health.log`
3. Review container logs for specific services
4. Validate environment variable configuration 