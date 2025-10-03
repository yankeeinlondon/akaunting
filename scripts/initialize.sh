#!/usr/bin/env bash

# Akaunting Docker Environment Initialization Script
# This script prepares a new Akaunting development environment using Docker

set -e  # Exit on error

echo "======================================"
echo "Akaunting Docker Initialization"
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

# Check if volumes already exist (indicates previous installation)
if docker volume ls | grep -q "akaunting_mysql_data"; then
    print_warning "Existing Akaunting installation detected!"
    echo ""
    echo "This script will DELETE ALL DATA including:"
    echo "  - Database contents"
    echo "  - Uploaded files"
    echo "  - All configuration"
    echo ""
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        print_info "Installation cancelled. Use './scripts/start.sh' to start existing installation."
        exit 0
    fi
fi

# Stop and remove existing containers
print_info "Cleaning up any existing containers..."
docker-compose down -v 2>/dev/null || true

# Remove any orphaned volumes
print_info "Removing any orphaned volumes..."
docker volume rm akaunting_mysql_data 2>/dev/null || true
docker volume rm akaunting_storage_data 2>/dev/null || true
print_success "Cleanup complete"

# Build Docker images
print_info "Building Docker images (this may take a few minutes)..."
docker-compose build --no-cache
print_success "Docker images built successfully"

# Start MySQL container first
print_info "Starting MySQL database..."
docker-compose up -d mysql
print_success "MySQL container started"

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
    exit 1
fi

# Create .env file if it doesn't exist
print_info "Setting up environment configuration..."
if [ ! -f .env ]; then
    cp .env.example .env
    print_success "Created .env file from .env.example"
else
    print_warning ".env file already exists, skipping..."
fi

# Update .env with Docker MySQL configuration
print_info "Configuring database connection..."
sed -i.bak 's/DB_CONNECTION=.*/DB_CONNECTION=mysql/' .env
sed -i.bak 's/DB_HOST=.*/DB_HOST=mysql/' .env
sed -i.bak 's/DB_PORT=.*/DB_PORT=3306/' .env
sed -i.bak 's/DB_DATABASE=.*/DB_DATABASE=akaunting/' .env
sed -i.bak 's/DB_USERNAME=.*/DB_USERNAME=akaunting_user/' .env
sed -i.bak 's/DB_PASSWORD=.*/DB_PASSWORD=akaunting_pass/' .env
sed -i.bak 's/APP_ENV=.*/APP_ENV=local/' .env
sed -i.bak 's/APP_INSTALLED=.*/APP_INSTALLED=false/' .env
sed -i.bak 's|APP_URL=.*|APP_URL=http://localhost:8000|' .env
rm -f .env.bak
print_success "Database configuration updated"

# Check for pre-built assets
print_info "Checking for pre-built frontend assets..."
if [ ! -d "public/js" ] || [ ! -f "public/css/app.css" ]; then
    print_warning "Frontend assets not found. Building assets locally (required due to Docker memory constraints)..."

    if ! command -v npm &> /dev/null; then
        print_error "npm is not installed. Please install Node.js 16+ and run: npm install --legacy-peer-deps && npm run production"
        exit 1
    fi

    print_info "Installing Node dependencies..."
    npm install --legacy-peer-deps
    print_success "Node dependencies installed"

    print_info "Building production assets..."
    npm run production
    print_success "Frontend assets compiled"
else
    print_success "Frontend assets found"
fi

# Create public symlink for asset paths
print_info "Creating public symlink..."
if [ ! -L "public/public" ]; then
    cd public && ln -s . public && cd ..
    print_success "Public symlink created"
else
    print_success "Public symlink already exists"
fi

# Start all application containers
print_info "Starting application containers..."
docker-compose up -d
print_success "Application containers started"

# Install Composer dependencies
print_info "Installing PHP dependencies..."
docker-compose exec -T app composer install --optimize-autoloader --ignore-platform-reqs
print_success "PHP dependencies installed"

# Run Akaunting installation
print_info "Installing Akaunting (this will create database tables and admin user)..."
docker-compose exec -T app php artisan install \
  --db-host="mysql" \
  --db-name="akaunting" \
  --db-username="akaunting_user" \
  --db-password="akaunting_pass" \
  --admin-email="admin@company.com" \
  --admin-password="123456" \
  --company-name="My Company" \
  --company-email="info@company.com" \
  --locale="en-GB"
print_success "Akaunting installation completed"

# Seed sample data
print_info "Seeding sample data..."
if docker-compose exec -T app php artisan sample-data:seed --force 2>&1 | grep -q "Seeded"; then
    print_success "Sample data seeded successfully"
else
    print_warning "Sample data seeding may have encountered issues (this is optional)"
fi

# Clear caches
print_info "Clearing application caches..."
docker-compose exec -T app php artisan cache:clear
docker-compose exec -T app php artisan config:clear
docker-compose exec -T app php artisan route:clear
docker-compose exec -T app php artisan view:clear
print_success "Caches cleared"

# Fix permissions
print_info "Setting proper permissions..."
docker-compose exec -T app chown -R www-data:www-data /var/www/html/storage
docker-compose exec -T app chmod -R 755 /var/www/html/storage
docker-compose exec -T app chmod -R 755 /var/www/html/bootstrap/cache
print_success "Permissions set"

# Run sanity checks
echo ""
echo "======================================"
echo "Running Sanity Checks"
echo "======================================"
echo ""

# Check PHP version
print_info "Checking PHP version..."
PHP_VERSION=$(docker-compose exec -T app php --version | head -n 1)
if echo "$PHP_VERSION" | grep -q "8.3"; then
    print_success "PHP version: $PHP_VERSION"
else
    print_warning "PHP version may not be 8.3: $PHP_VERSION"
fi

# Check Node version
print_info "Checking Node.js version..."
NODE_VERSION=$(docker-compose exec -T app node --version)
if echo "$NODE_VERSION" | grep -q "v16"; then
    print_success "Node.js version: $NODE_VERSION"
else
    print_warning "Node.js version may not be 16: $NODE_VERSION"
fi

# Check database connection
print_info "Checking database connection..."
if docker-compose exec -T app php artisan db:show 2>&1 | grep -q "mysql"; then
    print_success "Database connection successful"
else
    print_warning "Database connection check inconclusive"
fi

# Check if migrations ran
print_info "Verifying database tables..."
TABLE_COUNT=$(docker-compose exec -T mysql mysql -u akaunting_user -pakaunting_pass -D akaunting -e "SHOW TABLES;" 2>/dev/null | wc -l)
if [ "$TABLE_COUNT" -gt 10 ]; then
    print_success "Database tables created successfully ($TABLE_COUNT tables)"
else
    print_warning "Expected more database tables (found $TABLE_COUNT)"
fi

# Display access information
echo ""
echo "======================================"
echo "Initialization Complete!"
echo "======================================"
echo ""
print_success "Akaunting is ready to use!"
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
echo "Next steps:"
echo "  1. Run: ./scripts/start.sh    (to start the environment)"
echo "  2. Visit: http://localhost:8000"
echo ""
print_info "Note: The application may take a few seconds to fully start."
echo ""
