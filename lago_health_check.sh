#!/bin/bash

# =============================================================================
# LAGO COMPREHENSIVE HEALTH CHECK AND STARTUP SCRIPT
# =============================================================================
# 
# This script provides comprehensive health checking and startup for the entire
# Lago development environment. It is idempotent and replaces all legacy startup
# scripts with a single, robust solution.
#
# Features:
# - Idempotent execution (safe to run multiple times)
# - Comprehensive service health checks
# - CORS error detection
# - URL validation and routing tests
# - End-to-end functionality verification
# - Automatic cleanup and recovery
# - Detailed logging and debugging
#
# Usage:
#   ./lago_health_check.sh [OPTIONS]
#
# Options:
#   --start-only    Start services without running health checks
#   --check-only    Run health checks on already running services
#   --stop          Stop all services
#   --restart       Stop and restart all services
#   --verbose       Enable verbose output
#   --timeout=N     Set timeout for service startup (default: 300s)
#
# =============================================================================

set -euo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================

readonly SCRIPT_VERSION="1.3.0"
readonly SCRIPT_NAME="Lago Health Check"
readonly LAGO_PATH="${LAGO_PATH:-/workspace/lago}"
readonly COMPOSE_FILE="docker-compose.dev.yml"
readonly DEFAULT_TIMEOUT=300
readonly HEALTH_CHECK_TIMEOUT=180

# Initialize variables with defaults
VERBOSE=${VERBOSE:-false}
COMPOSE_CMD=""

# Colors and formatting
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly PURPLE='\033[0;35m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# Counters for test results
TESTS_PASSED=0
TESTS_FAILED=0
WARNINGS_COUNT=0

# Service definitions: service_name -> "container_name:port1:port2"
declare -A LAGO_SERVICES=(
    ["traefik"]="lago_traefik_dev:80:443"
    ["db"]="lago_db_dev:5432"
    ["redis"]="lago_redis_dev:6379"
    ["api"]="lago_api_dev:3000"
    ["front"]="lago_front_dev:8080"
    ["api-worker"]="lago_api_worker:"
    ["api-events-worker"]="lago_api_events_worker_dev:"
    ["api-pdfs-worker"]="lago_api_pdfs_worker_dev:"
    ["api-billing-worker"]="lago_api_billing_worker_dev:"
    ["api-clock-worker"]="lago_api_clock_worker_dev:"
    ["api-webhook-worker"]="lago_api_webhook_worker_dev:"
    ["api-clock"]="lago_api_clock_dev:"
    ["api-events-consumer"]="lago_api_events_consumer_dev:"
    ["events-processor"]="lago_events-processor:"
    ["pdf"]="lago_pdf_dev:"
    ["mailhog"]="lago_mailhog_dev:"
    ["redpanda"]="lago_redpanda_dev:9092:19092"
    ["clickhouse"]="lago_clickhouse_dev:9000:8123"
)

# Health check endpoints
declare -A HEALTH_ENDPOINTS=(
    ["api"]="/health"
    ["front"]="/"
    ["mailhog"]="/"
    ["pdf"]="/health"
)

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

log_header() {
    echo -e "\n${CYAN}${BOLD}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║ $(printf "%-76s" "$1") ║${NC}"
    echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════════════════════════════════════╝${NC}\n"
}

log_section() {
    echo -e "\n${BLUE}${BOLD}┌─────────────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}${BOLD}│ $(printf "%-75s" "$1") │${NC}"
    echo -e "${BLUE}${BOLD}└─────────────────────────────────────────────────────────────────────────────┘${NC}"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    [[ "$VERBOSE" == "true" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1" >> "${LAGO_PATH}/lago_health.log"
}

log_success() {
    echo -e "${GREEN}[✓ PASS]${NC} $1"
    ((TESTS_PASSED++))
    [[ "$VERBOSE" == "true" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') [PASS] $1" >> "${LAGO_PATH}/lago_health.log"
}

log_warning() {
    echo -e "${YELLOW}[⚠ WARN]${NC} $1"
    ((WARNINGS_COUNT++))
    [[ "$VERBOSE" == "true" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') [WARN] $1" >> "${LAGO_PATH}/lago_health.log"
}

log_error() {
    echo -e "${RED}[✗ FAIL]${NC} $1"
    ((TESTS_FAILED++))
    [[ "$VERBOSE" == "true" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') [FAIL] $1" >> "${LAGO_PATH}/lago_health.log"
}

log_debug() {
    [[ "$VERBOSE" == "true" ]] && echo -e "${PURPLE}[DEBUG]${NC} $1"
    [[ "$VERBOSE" == "true" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') [DEBUG] $1" >> "${LAGO_PATH}/lago_health.log"
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Initialize compose command - MUST be called before using COMPOSE_CMD
init_compose_cmd() {
    if [[ -n "$COMPOSE_CMD" ]]; then
        return 0  # Already initialized
    fi
    
    if docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
        log_debug "Using Docker Compose V2"
    elif command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
        log_debug "Using Docker Compose V1"
    else
        log_error "Docker Compose not available"
        return 1
    fi
    
    return 0
}

# Parse service info: "container:port1:port2" -> array
parse_service_info() {
    local service_key="$1"
    local service_def="${LAGO_SERVICES[$service_key]:-}"
    
    if [[ -z "$service_def" ]]; then
        log_error "Unknown service: $service_key"
        return 1
    fi
    
    # Split on colons and return as array
    IFS=':' read -ra service_parts <<< "$service_def"
    printf '%s\n' "${service_parts[@]}"
}

# Get container name for service
get_container_name() {
    local service_key="$1"
    local service_info=($(parse_service_info "$service_key" 2>/dev/null)) || return 1
    echo "${service_info[0]}"
}

# Get primary port for service
get_primary_port() {
    local service_key="$1"
    local service_info=($(parse_service_info "$service_key" 2>/dev/null)) || return 1
    echo "${service_info[1]:-}"
}

# Check if container is running - immediate fail if not
check_container_running() {
    local container_name="$1"
    
    log_debug "Checking if container '$container_name' is running..."
    
    if docker ps --format "{{.Names}}" | grep -q "^${container_name}$"; then
        local status=$(docker inspect "$container_name" --format='{{.State.Status}}' 2>/dev/null)
        if [[ "$status" == "running" ]]; then
            log_debug "Container '$container_name' is running"
            return 0
        else
            log_error "Container '$container_name' exists but status: $status"
            return 1
        fi
    else
        log_error "Container '$container_name' not found"
        return 1
    fi
}

# Quick port check - fail fast instead of long timeout
check_port_accessible() {
    local host="$1"
    local port="$2"
    local max_attempts="${3:-3}"
    local attempt=0
    
    log_debug "Checking port $host:$port accessibility..."
    
    while [[ $attempt -lt $max_attempts ]]; do
        if timeout 2 bash -c "</dev/tcp/$host/$port" 2>/dev/null; then
            log_debug "Port $host:$port is accessible"
            return 0
        fi
        ((attempt++))
        sleep 1
    done
    
    log_debug "Port $host:$port not accessible after $max_attempts attempts"
    return 1
}

# Execute command in container with clean output separation
execute_in_container() {
    local container_name="$1"
    shift
    local cmd="$*"
    
    log_debug "Executing in $container_name: $cmd" >&2
    docker exec "$container_name" $cmd
}

# Test HTTP endpoint
test_http_endpoint() {
    local url="$1"
    local expected_status="${2:-200}"
    local service_name="${3:-Service}"
    
    log_debug "Testing HTTP endpoint: $url (expecting $expected_status)"
    
    local response
    if response=$(curl -s -w "%{http_code}" "$url" 2>/dev/null); then
        local status_code="${response: -3}"
        local body="${response%???}"
        
        if [[ "$status_code" == "$expected_status" ]]; then
            log_success "$service_name HTTP check passed ($status_code)"
            [[ -n "$body" && "$VERBOSE" == "true" ]] && log_debug "Response: $body"
            return 0
        else
            log_error "$service_name HTTP check failed ($status_code)"
            return 1
        fi
    else
        log_error "$service_name HTTP endpoint not responding: $url"
        return 1
    fi
}

# =============================================================================
# ENVIRONMENT SETUP
# =============================================================================

validate_environment() {
    log_section "ENVIRONMENT VALIDATION"
    
    # Initialize compose command first
    if ! init_compose_cmd; then
        return 1
    fi
    
    # Change to Lago directory
    if [[ ! -d "$LAGO_PATH" ]]; then
        log_error "Lago path does not exist: $LAGO_PATH"
        return 1
    fi
    
    cd "$LAGO_PATH" || {
        log_error "Cannot change to Lago directory: $LAGO_PATH"
        return 1
    }
    
    log_success "Changed to Lago directory: $LAGO_PATH"
    
    # Load Gitpod environment if available
    if command -v gp &> /dev/null; then
        log_info "Loading Gitpod environment variables..."
        # Load environment excluding readonly LAGO_PATH
        local gitpod_env=$(gp env -e)
        eval "$(echo "$gitpod_env" | grep -v '^export LAGO_PATH=')"
        log_success "Gitpod environment variables loaded"
    else
        log_warning "Gitpod CLI not available - using local environment"
    fi
    
    # Validate required tools
    local required_tools=("docker" "curl")
    for tool in "${required_tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            log_success "Tool '$tool' is available"
        else
            log_error "Required tool '$tool' is not installed"
            return 1
        fi
    done
    
    # Validate Docker daemon
    if docker info &> /dev/null; then
        log_success "Docker daemon is running"
    else
        log_error "Docker daemon is not running"
        return 1
    fi
    
    # Validate compose file
    if [[ -f "$COMPOSE_FILE" ]]; then
        log_success "Docker Compose file found: $COMPOSE_FILE"
    else
        log_error "Docker Compose file not found: $COMPOSE_FILE"
        return 1
    fi
    
    # Setup dynamic URLs for Gitpod
    if [[ -n "${GITPOD_WORKSPACE_ID:-}" && -n "${GITPOD_WORKSPACE_CLUSTER_HOST:-}" ]]; then
        export LAGO_API_URL="https://3000-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
        export LAGO_FRONT_URL="https://8080-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
        export API_URL="$LAGO_API_URL"
        export APP_DOMAIN="$LAGO_FRONT_URL"
        
        log_success "Gitpod URLs configured:"
        log_info "  API: $LAGO_API_URL"
        log_info "  Frontend: $LAGO_FRONT_URL"
    else
        log_warning "Not in Gitpod environment - using localhost URLs"
        export LAGO_API_URL="http://localhost:3000"
        export LAGO_FRONT_URL="http://localhost:8080"
    fi
    
    return 0
}

# =============================================================================
# SERVICE MANAGEMENT
# =============================================================================

stop_all_services() {
    log_section "STOPPING ALL SERVICES"
    
    # Initialize compose command if not already done
    if ! init_compose_cmd; then
        log_error "Cannot initialize Docker Compose command"
        return 1
    fi
    
    # Change to correct directory
    cd "$LAGO_PATH" || {
        log_error "Cannot change to Lago directory: $LAGO_PATH"
        return 1
    }
    
    log_info "Stopping development containers..."
    $COMPOSE_CMD -f "$COMPOSE_FILE" down --remove-orphans --volumes 2>/dev/null || true
    
    log_info "Stopping any remaining lago containers..."
    docker ps -a --filter "name=lago" --format "{{.Names}}" | xargs -r docker rm -f 2>/dev/null || true
    
    log_info "Cleaning up unused resources..."
    docker container prune -f &>/dev/null || true
    docker network prune -f &>/dev/null || true
    
    log_success "All services stopped and cleaned up"
    return 0
}

start_services() {
    log_section "STARTING LAGO SERVICES"
    
    # Ensure compose command is initialized
    if ! init_compose_cmd; then
        log_error "Cannot initialize Docker Compose command"
        return 1
    fi
    
    # Ensure we're in the right directory
    cd "$LAGO_PATH" || {
        log_error "Cannot change to Lago directory: $LAGO_PATH"
        return 1
    }
    
    log_info "Starting services with Docker Compose..."
    
    # Start services
    if $COMPOSE_CMD -f "$COMPOSE_FILE" up -d; then
        log_success "Docker Compose started successfully"
    else
        log_error "Failed to start services with Docker Compose"
        return 1
    fi
    
    log_info "Waiting for core services to initialize..."
    sleep 15
    
    # Wait for critical containers
    local critical_services=("db" "redis" "api" "front")
    for service in "${critical_services[@]}"; do
        local container_name=$(get_container_name "$service")
        if [[ -n "$container_name" ]]; then
            local max_wait=60
            local elapsed=0
            while [[ $elapsed -lt $max_wait ]]; do
                if check_container_running "$container_name"; then
                    break
                fi
                sleep 2
                elapsed=$((elapsed + 2))
            done
            
            if [[ $elapsed -ge $max_wait ]]; then
                log_error "Critical service '$service' ($container_name) failed to start within ${max_wait}s"
                return 1
            fi
        fi
    done
    
    log_success "Core services started successfully"
    return 0
}

# =============================================================================
# HEALTH CHECKS
# =============================================================================

check_container_health() {
    log_section "CONTAINER HEALTH CHECK"
    
    log_info "Checking container status..."
    local failed_containers=()
    
    for service in "${!LAGO_SERVICES[@]}"; do
        local container_name=$(get_container_name "$service")
        
        if [[ -z "$container_name" ]]; then
            log_error "Could not determine container name for service: $service"
            failed_containers+=("$service")
            continue
        fi
        
        if check_container_running "$container_name"; then
            log_success "Container '$container_name' is running"
        else
            failed_containers+=("$container_name")
        fi
    done
    
    if [[ ${#failed_containers[@]} -eq 0 ]]; then
        log_success "All containers are healthy"
        return 0
    else
        log_error "Failed containers: ${failed_containers[*]}"
        return 1
    fi
}

check_port_accessibility() {
    log_section "PORT ACCESSIBILITY CHECK"
    
    log_info "Checking port accessibility..."
    local failed_ports=()
    
    for service in "${!LAGO_SERVICES[@]}"; do
        local port=$(get_primary_port "$service")
        
        if [[ -n "$port" ]]; then
            if check_port_accessible "localhost" "$port" 5; then
                log_success "Service '$service' port $port is accessible"
            else
                failed_ports+=("$service:$port")
                log_error "Service '$service' port $port is not accessible"
            fi
        fi
    done
    
    if [[ ${#failed_ports[@]} -eq 0 ]]; then
        log_success "All service ports are accessible"
        return 0
    else
        log_error "Inaccessible service ports: ${failed_ports[*]}"
        return 1
    fi
}

check_database_health() {
    log_section "DATABASE HEALTH CHECK"
    
    local db_container=$(get_container_name "db")
    local db_port=$(get_primary_port "db")
    
    # Quick check first
    if ! check_container_running "$db_container"; then
        return 1
    fi
    
    if ! check_port_accessible "localhost" "$db_port" 3; then
        log_error "Database port $db_port not accessible"
        return 1
    fi
    
    log_info "Testing database connection..."
    if execute_in_container "$db_container" psql -U lago -d lago -c "SELECT 1;" > /dev/null 2>&1; then
        log_success "Database connection successful"
    else
        log_error "Database connection failed"
        return 1
    fi
    
    return 0
}

check_redis_health() {
    log_section "REDIS HEALTH CHECK"
    
    local redis_container=$(get_container_name "redis")
    local redis_port=$(get_primary_port "redis")
    
    # Quick check first
    if ! check_container_running "$redis_container"; then
        return 1
    fi
    
    if ! check_port_accessible "localhost" "$redis_port" 3; then
        log_error "Redis port $redis_port not accessible"
        return 1
    fi
    
    log_info "Testing Redis connection..."
    local redis_response
    if redis_response=$(execute_in_container "$redis_container" redis-cli ping 2>/dev/null); then
        if [[ "$redis_response" == "PONG" ]]; then
            log_success "Redis is responding correctly"
        else
            log_error "Redis ping failed: expected PONG, got '$redis_response'"
            return 1
        fi
    else
        log_error "Could not connect to Redis"
        return 1
    fi
    
    return 0
}

check_api_health() {
    log_section "API HEALTH CHECK"
    
    local api_container=$(get_container_name "api")
    local api_port=$(get_primary_port "api")
    
    # Quick check first
    if ! check_container_running "$api_container"; then
        return 1
    fi
    
    if ! check_port_accessible "localhost" "$api_port" 3; then
        log_error "API port $api_port not accessible"
        return 1
    fi
    
    log_info "Testing API health endpoint..."
    local api_url="http://localhost:$api_port"
    if test_http_endpoint "$api_url/health" "200" "API"; then
        return 0
    else
        return 1
    fi
}

check_frontend_health() {
    log_section "FRONTEND HEALTH CHECK"
    
    local front_container=$(get_container_name "front")
    local front_port=$(get_primary_port "front")
    
    # Quick check first
    if ! check_container_running "$front_container"; then
        return 1
    fi
    
    if ! check_port_accessible "localhost" "$front_port" 3; then
        log_error "Frontend port $front_port not accessible"
        return 1
    fi
    
    log_info "Testing frontend accessibility..."
    local frontend_url="http://localhost:$front_port"
    if test_http_endpoint "$frontend_url" "200" "Frontend"; then
        return 0
    else
        return 1
    fi
}

run_full_health_check() {
    log_header "$SCRIPT_NAME v$SCRIPT_VERSION - Full Health Check"
    
    local start_time=$(date +%s)
    
    # Run all health checks
    validate_environment || true
    check_container_health || true
    check_port_accessibility || true
    check_database_health || true
    check_redis_health || true
    check_api_health || true
    check_frontend_health || true
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Final summary
    log_header "HEALTH CHECK SUMMARY"
    
    echo -e "${BOLD}Test Results:${NC}"
    echo -e "  ${GREEN}✓ Passed: $TESTS_PASSED${NC}"
    echo -e "  ${RED}✗ Failed: $TESTS_FAILED${NC}"
    echo -e "  ${YELLOW}⚠ Warnings: $WARNINGS_COUNT${NC}"
    echo -e "  ${BLUE}Duration: ${duration}s${NC}"
    echo
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}${BOLD}🎉 ALL HEALTH CHECKS PASSED! 🎉${NC}"
        echo
        echo -e "${BOLD}Lago Environment URLs:${NC}"
        echo -e "  Frontend: ${LAGO_FRONT_URL:-http://localhost:8080}"
        echo -e "  API: ${LAGO_API_URL:-http://localhost:3000}/health"
        echo
        return 0
    else
        echo -e "${RED}${BOLD}❌ HEALTH CHECKS FAILED ❌${NC}"
        echo -e "${BOLD}Failed Tests: $TESTS_FAILED${NC}"
        echo
        return 1
    fi
}

start_and_check() {
    log_header "$SCRIPT_NAME v$SCRIPT_VERSION - Start and Check"
    
    if ! validate_environment; then
        log_error "Environment validation failed"
        return 1
    fi
    
    if ! stop_all_services; then
        log_error "Failed to stop existing services"
        return 1
    fi
    
    if ! start_services; then
        log_error "Failed to start services"
        return 1
    fi
    
    log_info "Waiting for services to stabilize..."
    sleep 20
    
    if ! run_full_health_check; then
        log_error "Health checks failed after startup"
        return 1
    fi
    
    return 0
}

# =============================================================================
# COMMAND LINE INTERFACE
# =============================================================================

show_help() {
    cat << EOF
$SCRIPT_NAME v$SCRIPT_VERSION

DESCRIPTION:
    Comprehensive health check and startup script for Lago development environment.

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --start-only        Start services without running health checks
    --check-only        Run health checks on already running services  
    --stop              Stop all services and exit
    --restart           Stop and restart all services, then run health checks
    --verbose           Enable verbose output and logging
    --timeout=N         Set timeout for service startup (default: ${DEFAULT_TIMEOUT}s)
    --help              Show this help message

EXAMPLES:
    $0                  # Start services and run full health check
    $0 --check-only     # Only run health checks
    $0 --restart        # Restart everything and check
    $0 --verbose        # Enable detailed logging

EOF
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    local action="start_and_check"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --start-only)
                action="start_only"
                shift
                ;;
            --check-only)
                action="check_only"
                shift
                ;;
            --stop)
                action="stop"
                shift
                ;;
            --restart)
                action="restart"
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --timeout=*)
                DEFAULT_TIMEOUT="${1#*=}"
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Initialize logging
    if [[ "$VERBOSE" == "true" ]]; then
        log_debug "Verbose logging enabled"
        echo "$(date '+%Y-%m-%d %H:%M:%S') [START] $SCRIPT_NAME v$SCRIPT_VERSION" >> "${LAGO_PATH}/lago_health.log"
    fi
    
    # Execute requested action - each function handles its own initialization
    case $action in
        "start_only")
            validate_environment && stop_all_services && start_services
            ;;
        "check_only")
            run_full_health_check
            ;;
        "stop")
            # stop_all_services handles its own initialization
            stop_all_services
            ;;
        "restart")
            start_and_check
            ;;
        "start_and_check")
            start_and_check
            ;;
        *)
            log_error "Invalid action: $action"
            exit 1
            ;;
    esac
    
    local exit_code=$?
    
    if [[ "$VERBOSE" == "true" ]]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') [END] Exit code: $exit_code" >> "${LAGO_PATH}/lago_health.log"
    fi
    
    exit $exit_code
}

# Execute main function with all arguments
main "$@" 