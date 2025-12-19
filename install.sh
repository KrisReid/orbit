#!/bin/bash

# =============================================================================
# Orbit Installation Script
# =============================================================================
# This script prepares Orbit for self-hosted deployment by:
# - Checking prerequisites (Docker, Docker Compose)
# - Generating secure secrets
# - Creating configuration from template
# - Validating the setup
#
# Usage:
#   ./install.sh              # Interactive setup
#   ./install.sh --defaults   # Use defaults (for CI/testing)
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
ENV_EXAMPLE="${SCRIPT_DIR}/.env.example"

# =============================================================================
# Helper Functions
# =============================================================================

print_banner() {
    echo -e "${BLUE}"
    echo "  ╔═══════════════════════════════════════════════════════════════╗"
    echo "  ║                                                               ║"
    echo "  ║     ██████╗ ██████╗ ██████╗ ██╗████████╗                     ║"
    echo "  ║    ██╔═══██╗██╔══██╗██╔══██╗██║╚══██╔══╝                     ║"
    echo "  ║    ██║   ██║██████╔╝██████╔╝██║   ██║                        ║"
    echo "  ║    ██║   ██║██╔══██╗██╔══██╗██║   ██║                        ║"
    echo "  ║    ╚██████╔╝██║  ██║██████╔╝██║   ██║                        ║"
    echo "  ║     ╚═════╝ ╚═╝  ╚═╝╚═════╝ ╚═╝   ╚═╝                        ║"
    echo "  ║                                                               ║"
    echo "  ║           Self-Hosted Installation Script                     ║"
    echo "  ║                                                               ║"
    echo "  ╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

generate_secret() {
    # Generate a secure random string
    if command -v openssl &> /dev/null; then
        openssl rand -base64 32 | tr -d '/+=' | head -c 32
    elif command -v python3 &> /dev/null; then
        python3 -c "import secrets; print(secrets.token_urlsafe(32)[:32])"
    else
        # Fallback using /dev/urandom
        head -c 32 /dev/urandom | base64 | tr -d '/+=' | head -c 32
    fi
}

generate_password() {
    # Generate a secure password (16 chars, alphanumeric)
    if command -v openssl &> /dev/null; then
        openssl rand -base64 24 | tr -d '/+=' | head -c 16
    elif command -v python3 &> /dev/null; then
        python3 -c "import secrets; print(secrets.token_urlsafe(16)[:16])"
    else
        head -c 16 /dev/urandom | base64 | tr -d '/+=' | head -c 16
    fi
}

# =============================================================================
# Prerequisite Checks
# =============================================================================

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local missing=()
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        missing+=("docker")
    else
        log_success "Docker is installed ($(docker --version | cut -d' ' -f3 | tr -d ','))"
    fi
    
    # Check Docker Compose (v2)
    if docker compose version &> /dev/null; then
        log_success "Docker Compose is installed ($(docker compose version --short))"
    elif command -v docker-compose &> /dev/null; then
        log_warning "Found docker-compose (legacy). Recommend upgrading to Docker Compose v2"
    else
        missing+=("docker-compose")
    fi
    
    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running. Please start Docker and try again."
        exit 1
    fi
    
    if [ ${#missing[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing[*]}"
        echo ""
        echo "Please install the missing tools:"
        echo "  - Docker: https://docs.docker.com/get-docker/"
        echo "  - Docker Compose: https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    log_success "All prerequisites met!"
    echo ""
}

# =============================================================================
# Configuration
# =============================================================================

configure_environment() {
    local use_defaults=$1
    
    log_info "Configuring environment..."
    
    # Check if .env already exists
    if [ -f "$ENV_FILE" ]; then
        if [ "$use_defaults" = "true" ]; then
            log_warning ".env file already exists. Using existing configuration."
            return 0
        fi
        
        echo ""
        read -p "$(echo -e ${YELLOW}".env file already exists. Overwrite? [y/N]: "${NC})" overwrite
        if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
            log_info "Keeping existing configuration."
            return 0
        fi
    fi
    
    # Check if .env.example exists
    if [ ! -f "$ENV_EXAMPLE" ]; then
        log_error ".env.example not found. Please ensure you're running this script from the Orbit directory."
        exit 1
    fi
    
    # Copy template
    cp "$ENV_EXAMPLE" "$ENV_FILE"
    
    # Generate secrets
    log_info "Generating secure secrets..."
    local secret_key=$(generate_secret)
    local postgres_password=$(generate_password)
    
    # Replace placeholders in .env
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s|SECRET_KEY=CHANGE_ME_GENERATE_SECURE_KEY|SECRET_KEY=${secret_key}|g" "$ENV_FILE"
        sed -i '' "s|POSTGRES_PASSWORD=CHANGE_ME_GENERATE_SECURE_PASSWORD|POSTGRES_PASSWORD=${postgres_password}|g" "$ENV_FILE"
    else
        # Linux
        sed -i "s|SECRET_KEY=CHANGE_ME_GENERATE_SECURE_KEY|SECRET_KEY=${secret_key}|g" "$ENV_FILE"
        sed -i "s|POSTGRES_PASSWORD=CHANGE_ME_GENERATE_SECURE_PASSWORD|POSTGRES_PASSWORD=${postgres_password}|g" "$ENV_FILE"
    fi
    
    log_success "Generated secure SECRET_KEY"
    log_success "Generated secure POSTGRES_PASSWORD"
    
    # Interactive configuration
    if [ "$use_defaults" != "true" ]; then
        echo ""
        log_info "Configuration options:"
        echo ""
        
        # Domain
        read -p "$(echo -e ${BLUE}"Enter your domain (e.g., orbit.mycompany.com) [localhost]: "${NC})" domain
        domain=${domain:-localhost}
        
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|DOMAIN=localhost|DOMAIN=${domain}|g" "$ENV_FILE"
        else
            sed -i "s|DOMAIN=localhost|DOMAIN=${domain}|g" "$ENV_FILE"
        fi
        
        # ACME Email (only if not localhost)
        if [ "$domain" != "localhost" ]; then
            read -p "$(echo -e ${BLUE}"Enter email for TLS certificates [admin@example.com]: "${NC})" acme_email
            acme_email=${acme_email:-admin@example.com}
            
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' "s|ACME_EMAIL=admin@example.com|ACME_EMAIL=${acme_email}|g" "$ENV_FILE"
            else
                sed -i "s|ACME_EMAIL=admin@example.com|ACME_EMAIL=${acme_email}|g" "$ENV_FILE"
            fi
        fi
        
        # Task ID Prefix
        read -p "$(echo -e ${BLUE}"Enter task ID prefix (e.g., MYORG) [ORBIT]: "${NC})" task_prefix
        task_prefix=${task_prefix:-ORBIT}
        
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|TASK_ID_PREFIX=ORBIT|TASK_ID_PREFIX=${task_prefix}|g" "$ENV_FILE"
        else
            sed -i "s|TASK_ID_PREFIX=ORBIT|TASK_ID_PREFIX=${task_prefix}|g" "$ENV_FILE"
        fi
    fi
    
    log_success "Configuration saved to .env"
    echo ""
}

# =============================================================================
# Validation
# =============================================================================

validate_configuration() {
    log_info "Validating configuration..."
    
    # Source the .env file
    set -a
    source "$ENV_FILE"
    set +a
    
    local errors=()
    
    # Check required variables
    if [ -z "$SECRET_KEY" ] || [ "$SECRET_KEY" = "CHANGE_ME_GENERATE_SECURE_KEY" ]; then
        errors+=("SECRET_KEY is not set or using default value")
    fi
    
    if [ -z "$POSTGRES_PASSWORD" ] || [ "$POSTGRES_PASSWORD" = "CHANGE_ME_GENERATE_SECURE_PASSWORD" ]; then
        errors+=("POSTGRES_PASSWORD is not set or using default value")
    fi
    
    if [ -z "$DOMAIN" ]; then
        errors+=("DOMAIN is not set")
    fi
    
    # Check for production security issues
    if [ "$DOMAIN" != "localhost" ] && [ "$DEBUG" = "true" ]; then
        log_warning "DEBUG is enabled for non-localhost deployment. Consider setting DEBUG=false"
    fi
    
    if [ ${#errors[@]} -ne 0 ]; then
        log_error "Configuration validation failed:"
        for error in "${errors[@]}"; do
            echo "  - $error"
        done
        exit 1
    fi
    
    log_success "Configuration is valid!"
    echo ""
}

# =============================================================================
# Summary
# =============================================================================

print_summary() {
    # Source the .env file
    set -a
    source "$ENV_FILE"
    set +a
    
    echo -e "${GREEN}"
    echo "╔═══════════════════════════════════════════════════════════════════╗"
    echo "║                    Installation Complete!                         ║"
    echo "╚═══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo "Configuration Summary:"
    echo "  Domain:          ${DOMAIN}"
    echo "  Task ID Prefix:  ${TASK_ID_PREFIX}"
    echo "  Debug Mode:      ${DEBUG}"
    echo ""
    
    if [ "$DOMAIN" = "localhost" ]; then
        echo -e "${YELLOW}Local Testing Mode${NC}"
        echo ""
        echo "To start Orbit locally (HTTP only):"
        echo ""
        echo -e "  ${BLUE}docker compose -f docker-compose.prod.yml up -d${NC}"
        echo ""
        echo "Access Orbit at:"
        echo -e "  ${GREEN}http://localhost${NC}"
        echo ""
    else
        echo -e "${GREEN}Production Mode${NC}"
        echo ""
        echo "To start Orbit with TLS:"
        echo ""
        echo -e "  ${BLUE}docker compose -f docker-compose.prod.yml -f docker-compose.tls.yml up -d${NC}"
        echo ""
        echo "Access Orbit at:"
        echo -e "  ${GREEN}https://${DOMAIN}${NC}"
        echo ""
        echo -e "${YELLOW}Note:${NC} Ensure your DNS is configured to point ${DOMAIN} to this server."
        echo ""
    fi
    
    echo "Default login credentials:"
    echo -e "  Email:    ${BLUE}admin@orbit.example.com${NC}"
    echo -e "  Password: ${BLUE}admin123${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  Change the default password after first login!${NC}"
    echo ""
    
    echo "Useful commands:"
    echo "  View logs:       docker compose -f docker-compose.prod.yml logs -f"
    echo "  Stop:            docker compose -f docker-compose.prod.yml down"
    echo "  Update:          docker compose -f docker-compose.prod.yml pull && docker compose -f docker-compose.prod.yml up -d"
    echo ""
    
    echo "Documentation:"
    echo "  - Self-hosting guide: docs/SELF-HOSTING.md"
    echo "  - API documentation:  http${DOMAIN:+s}://${DOMAIN}/docs (when DEBUG=true)"
    echo ""
}

# =============================================================================
# Main
# =============================================================================

main() {
    local use_defaults=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --defaults)
                use_defaults=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --defaults    Use default values (non-interactive)"
                echo "  --help, -h    Show this help message"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    print_banner
    
    check_prerequisites
    configure_environment "$use_defaults"
    validate_configuration
    print_summary
}

main "$@"
