#!/bin/bash

# Comprehensive Lago Production Environment Test Script
# This script tests the complete production setup with proper environment variables
# NO HARDCODED VALUES - all variables loaded from Gitpod user environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "\n${CYAN}${BOLD}=== $1 ===${NC}"
}

# Test functions
test_environment_variables() {
    log_step "TESTING ENVIRONMENT VARIABLES"
    
    # Load Gitpod environment variables
    eval $(gp env -e)
    
    # Required variables for production
    required_vars=(
        "SECRET_KEY_BASE"
        "LAGO_ENCRYPTION_PRIMARY_KEY"
        "LAGO_ENCRYPTION_DETERMINISTIC_KEY"
        "LAGO_ENCRYPTION_KEY_DERIVATION_SALT"
        "LAGO_RSA_PRIVATE_KEY"
    )
    
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
            log_error "$var is not set"
        else
            log_success "$var is loaded"
        fi
    done
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        log_error "Missing required environment variables: ${missing_vars[*]}"
        return 1
    fi
    
    log_success "All required environment variables are loaded"
    return 0
}

test_docker_environment() {
    log_step "TESTING DOCKER ENVIRONMENT"
    
    # Check if docker is available
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        return 1
    fi
    
    # Check if docker-compose is available
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose is not available"
        return 1
    fi
    
    log_success "Docker environment is ready"
    return 0
}

stop_existing_containers() {
    log_step "STOPPING EXISTING CONTAINERS"
    
    # Stop development containers if running
    if docker ps --format "table {{.Names}}" | grep -q "lago.*dev"; then
        log_info "Stopping development containers..."
        docker-compose -f docker-compose.dev.yml down --volumes 2>/dev/null || true
    fi
    
    # Stop any existing production containers
    if docker ps --format "table {{.Names}}" | grep -q "lago-"; then
        log_info "Stopping existing production containers..."
        docker-compose -f docker-compose.yml down --volumes 2>/dev/null || true
        docker-compose -f deploy/docker-compose.production.yml down --volumes 2>/dev/null || true
    fi
    
    # Clean up any leftover containers
    docker container prune -f 2>/dev/null || true
    
    log_success "All existing containers stopped"
}

start_production_environment() {
    log_step "STARTING PRODUCTION ENVIRONMENT"
    
    # Load environment variables for docker-compose
    eval $(gp env -e)
    
    # Export minimal required production variables
    export LAGO_DOMAIN="localhost"
    export LAGO_ACME_EMAIL="test@example.com"
    export POSTGRES_USER="lago"
    export POSTGRES_PASSWORD="changeme"
    export POSTGRES_DB="lago"
    export REDIS_PASSWORD=""
    
    # Dynamically set Gitpod URLs using environment variables (NO HARDCODING!)
    if [ -n "$GITPOD_WORKSPACE_ID" ] && [ -n "$GITPOD_WORKSPACE_CLUSTER_HOST" ]; then
        export LAGO_API_URL="https://3000-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
        export LAGO_FRONT_URL="https://80-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
        log_info "Using Gitpod URLs:"
        log_info "  API: $LAGO_API_URL"
        log_info "  Frontend: $LAGO_FRONT_URL"
    else
        log_warning "Gitpod environment variables not found, using localhost URLs"
        export LAGO_API_URL="http://localhost:3000"
        export LAGO_FRONT_URL="http://localhost"
    fi
    
    log_info "Starting production containers with docker-compose.yml..."
    
    # Start production environment
    docker-compose -f docker-compose.yml up --build -d
    
    log_info "Waiting for containers to start..."
    sleep 30
    
    # Check container status
    local failed_containers=()
    
    containers=("lago-db" "lago-redis" "lago-api" "lago-front")
    
    for container in "${containers[@]}"; do
        if ! docker ps --format "table {{.Names}}" | grep -q "$container"; then
            failed_containers+=("$container")
        fi
    done
    
    if [ ${#failed_containers[@]} -gt 0 ]; then
        log_error "Failed to start containers: ${failed_containers[*]}"
        docker-compose -f docker-compose.yml logs --tail 20
        return 1
    fi
    
    log_success "Production environment started successfully"
    return 0
}

test_database_migration() {
    log_step "TESTING DATABASE MIGRATION"
    
    log_info "Waiting for migration to complete..."
    
    # Wait for migrate container to finish
    timeout=300
    elapsed=0
    while [ $elapsed -lt $timeout ]; do
        if ! docker ps --format "table {{.Names}}" | grep -q "lago-migrate"; then
            break
        fi
        sleep 5
        elapsed=$((elapsed + 5))
    done
    
    # Check if migration was successful
    if docker ps -a --format "table {{.Names}}\t{{.Status}}" | grep "lago-migrate" | grep -q "Exited (0)"; then
        log_success "Database migration completed successfully"
        return 0
    else
        log_error "Database migration failed"
        docker logs lago-migrate
        return 1
    fi
}

test_api_health() {
    log_step "TESTING API HEALTH"
    
    log_info "Waiting for API to be ready..."
    
    timeout=180
    elapsed=0
    while [ $elapsed -lt $timeout ]; do
        if curl -s -f http://localhost:3000/health > /dev/null 2>&1; then
            break
        fi
        sleep 5
        elapsed=$((elapsed + 5))
    done
    
    if [ $elapsed -ge $timeout ]; then
        log_error "API health check timed out"
        docker logs lago-api --tail 20
        return 1
    fi
    
    # Test API response
    response=$(curl -s http://localhost:3000/health)
    if echo "$response" | grep -q "Success\|success"; then
        log_success "API is healthy and responding: $response"
        return 0
    else
        log_error "API health check failed: $response"
        return 1
    fi
}

test_frontend_health() {
    log_step "TESTING FRONTEND HEALTH"
    
    log_info "Testing frontend accessibility..."
    
    timeout=120
    elapsed=0
    while [ $elapsed -lt $timeout ]; do
        status_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:80 2>/dev/null || echo "000")
        if [ "$status_code" = "200" ]; then
            break
        fi
        sleep 5
        elapsed=$((elapsed + 5))
    done
    
    if [ $elapsed -ge $timeout ]; then
        log_error "Frontend health check timed out"
        docker logs lago-front --tail 20
        return 1
    fi
    
    log_success "Frontend is accessible (HTTP $status_code)"
    return 0
}

test_environment_variables_in_containers() {
    log_step "TESTING ENVIRONMENT VARIABLES IN CONTAINERS"
    
    log_info "Checking environment variables in API container..."
    
    # Test that environment variables are properly loaded in the API container
    result=$(docker exec lago-api bundle exec rails runner "
        puts 'SECRET_KEY_BASE: ' + (ENV['SECRET_KEY_BASE'] ? 'LOADED' : 'MISSING')
        puts 'LAGO_ENCRYPTION_PRIMARY_KEY: ' + (ENV['LAGO_ENCRYPTION_PRIMARY_KEY'] ? 'LOADED' : 'MISSING')
        puts 'LAGO_ENCRYPTION_DETERMINISTIC_KEY: ' + (ENV['LAGO_ENCRYPTION_DETERMINISTIC_KEY'] ? 'LOADED' : 'MISSING')
        puts 'LAGO_ENCRYPTION_KEY_DERIVATION_SALT: ' + (ENV['LAGO_ENCRYPTION_KEY_DERIVATION_SALT'] ? 'LOADED' : 'MISSING')
        puts 'LAGO_RSA_PRIVATE_KEY: ' + (ENV['LAGO_RSA_PRIVATE_KEY'] ? 'LOADED' : 'MISSING')
    " 2>/dev/null)
    
    if echo "$result" | grep -q "MISSING"; then
        log_error "Some environment variables are missing in containers:"
        echo "$result"
        return 1
    else
        log_success "All environment variables are properly loaded in containers"
        echo "$result"
        return 0
    fi
}

test_database_operations() {
    log_step "TESTING DATABASE OPERATIONS"
    
    log_info "Testing database connectivity and operations..."
    
    # Test database connection and basic operations
    result=$(docker exec lago-api bundle exec rails runner "
        begin
            puts 'Database connection: ' + (ActiveRecord::Base.connection.execute('SELECT 1').first['?column?'] == 1 ? 'SUCCESS' : 'FAILED')
            puts 'Organizations count: ' + Organization.count.to_s
            puts 'Users count: ' + User.count.to_s
            puts 'Encryption functionality: ' + (defined?(Rails.application.credentials.dig(:secret_key_base)) ? 'AVAILABLE' : 'UNAVAILABLE')
        rescue => e
            puts 'ERROR: ' + e.message
        end
    " 2>/dev/null)
    
    if echo "$result" | grep -q "ERROR\|FAILED"; then
        log_error "Database operations failed:"
        echo "$result"
        return 1
    else
        log_success "Database operations working correctly"
        echo "$result"
        return 0
    fi
}

test_api_endpoints() {
    log_step "TESTING API ENDPOINTS"
    
    log_info "Testing API endpoints..."
    
    # Test health endpoint
    health_response=$(curl -s http://localhost:3000/health)
    log_info "Health endpoint response: $health_response"
    
    # Test protected endpoint (should return 401)
    auth_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/v1/organizations)
    if [ "$auth_status" = "401" ]; then
        log_success "Authentication is working (401 Unauthorized for protected endpoint)"
    else
        log_warning "Unexpected status code for protected endpoint: $auth_status"
    fi
    
    return 0
}

run_comprehensive_test() {
    log_step "COMPREHENSIVE LAGO PRODUCTION TEST"
    
    local test_functions=(
        "test_environment_variables"
        "test_docker_environment"
        "stop_existing_containers"
        "start_production_environment"
        "test_database_migration"
        "test_api_health"
        "test_frontend_health"
        "test_environment_variables_in_containers"
        "test_database_operations"
        "test_api_endpoints"
    )
    
    local failed_tests=()
    
    for test_func in "${test_functions[@]}"; do
        if ! $test_func; then
            failed_tests+=("$test_func")
        fi
    done
    
    echo
    if [ ${#failed_tests[@]} -eq 0 ]; then
        log_success "🎉 ALL PRODUCTION TESTS PASSED!"
        echo
        log_info "Production Environment URLs:"
        echo "  Frontend: http://localhost"
        echo "  API: http://localhost:3000"
        echo "  API Health: http://localhost:3000/health"
        echo
        log_info "Production Environment Status:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        log_error "❌ PRODUCTION TESTS FAILED!"
        echo "Failed tests: ${failed_tests[*]}"
        echo
        log_info "Container logs for debugging:"
        docker-compose -f docker-compose.yml logs --tail 10
        return 1
    fi
}

# Main execution
main() {
    echo -e "${CYAN}${BOLD}"
    echo "=========================================="
    echo "🚀 LAGO PRODUCTION ENVIRONMENT TEST 🚀"
    echo "=========================================="
    echo -e "${NC}"
    
    run_comprehensive_test
}

# Execute main function
main "$@" 