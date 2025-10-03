#!/bin/bash

# Akaunting Docker Environment Start Script
# This script starts the Akaunting development environment using Docker

set -e  # Exit on error

echo "======================================"
echo "Starting Akaunting Docker Environment"
echo "======================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${NC}→ $1${NC}"
}

# Check if Docker is installed
print_info "Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker Desktop first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi
print_success "Docker is installed"

# Check if Docker is running
print_info "Checking if Docker daemon is running..."
if ! docker info &> /dev/null; then
    print_error "Docker daemon is not running. Please start Docker Desktop."
    exit 1
fi
print_success "Docker daemon is running"

# Check if initialization has been run
print_info "Checking if environment has been initialized..."
if [ ! -f .env ]; then
    print_error "Environment not initialized. Please run ./scripts/initialize.sh first."
    exit 1
fi

# Check if DB is configured for MySQL (not SQLite)
if ! grep -q "DB_CONNECTION=mysql" .env; then
    print_warning "Database not configured for MySQL. Run ./scripts/initialize.sh to set up properly."
fi

print_success "Environment appears to be initialized"

# Start Docker containers
print_info "Starting Docker containers..."
docker-compose up -d
print_success "Docker containers started"

# Wait for MySQL to be healthy
print_info "Waiting for MySQL to be ready..."
MAX_RETRIES=30
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if docker-compose exec -T mysql mysqladmin ping -h localhost -u root -proot_password &> /dev/null; then
        print_success "MySQL is ready"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT+1))
    echo -n "."
    sleep 2
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    print_error "MySQL failed to start within expected time"
    print_info "Try running: docker-compose logs mysql"
    exit 1
fi

echo ""

# Wait for application to be ready
print_info "Waiting for application to be ready..."
sleep 3
print_success "Application should be ready"

# Display status
echo ""
echo "======================================"
echo "Environment Status"
echo "======================================"
echo ""

# Check container status
print_info "Container status:"
docker-compose ps

echo ""
echo "======================================"
echo "Access Information"
echo "======================================"
echo ""
print_success "Akaunting is running!"
echo ""
echo "Access URLs:"
echo "  - Application: http://localhost:8000"
echo "  - phpMyAdmin:  http://localhost:8080"
echo ""
echo "Database Credentials:"
echo "  - Host:     mysql (or localhost:3306 from host)"
echo "  - Database: akaunting"
echo "  - Username: akaunting_user"
echo "  - Password: akaunting_pass"
echo ""
echo "Default Admin Credentials (if sample data was seeded):"
echo "  - Email:    admin@company.com"
echo "  - Password: 123456"
echo ""
echo "Useful commands:"
echo "  - View logs:           docker-compose logs -f"
echo "  - View app logs:       docker-compose logs -f app"
echo "  - Stop environment:    docker-compose stop"
echo "  - Restart environment: docker-compose restart"
echo "  - Stop and remove:     docker-compose down"
echo "  - Execute command:     docker-compose exec app [command]"
echo ""
print_info "Note: The application may take a few seconds to fully start."
echo ""
