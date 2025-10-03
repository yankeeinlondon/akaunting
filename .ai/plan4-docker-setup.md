# Plan 4: Docker-Based Development Environment

## Overview

This plan creates a complete Docker-based development environment for Akaunting that resolves all the compatibility issues encountered in previous plans.

### Why Docker?

After attempting Plans 1-3, we discovered fundamental compatibility issues:

1. **PHP 8.4 Incompatibility**: The host system has PHP 8.4.13, but Laravel 10 and Akaunting require PHP 8.1-8.3. PHP 8.4 introduced strict constant handling that breaks Akaunting's installer (`Undefined constant "AKAUNTING_PHP"` error).

2. **Node.js 22 Incompatibility**: The host system initially had Node 22, but Laravel Mix 6 and Vue 2.7 require Node 16 or earlier.

3. **Database Flexibility**: SQLite was used as a workaround in Plan 3, but a production-like MySQL environment is preferable for development.

4. **Environment Isolation**: Docker ensures all developers work in identical environments regardless of their host system configuration.

## Architecture

### Services

The Docker environment consists of three services:

```
┌─────────────────────────────────────────────────────┐
│                   Host Machine                       │
│                                                      │
│  ┌────────────────────────────────────────────────┐ │
│  │         Docker Network (akaunting-network)     │ │
│  │                                                │ │
│  │  ┌──────────────┐  ┌──────────────────────┐  │ │
│  │  │   MySQL 8.0  │  │   Akaunting App      │  │ │
│  │  │              │  │   - PHP 8.3-fpm      │  │ │
│  │  │  Port: 3306  │  │   - Node 16          │  │ │
│  │  │              │  │   - Artisan serve    │  │ │
│  │  │  Health      │◄─┤   Port: 8000         │  │ │
│  │  │  checks      │  │                      │  │ │
│  │  └──────────────┘  └──────────────────────┘  │ │
│  │         ▲                                     │ │
│  │         │                                     │ │
│  │  ┌──────┴──────────┐                         │ │
│  │  │  phpMyAdmin     │                         │ │
│  │  │  Port: 8080     │                         │ │
│  │  └─────────────────┘                         │ │
│  └────────────────────────────────────────────────┘ │
│                                                      │
│  Exposed Ports:                                      │
│  - 8000 → Akaunting Application                     │
│  - 8080 → phpMyAdmin                                 │
│  - 3306 → MySQL                                      │
└─────────────────────────────────────────────────────┘
```

#### 1. MySQL Service
- **Image**: `mysql:8.0`
- **Purpose**: Production-like database server
- **Port**: 3306 (exposed to host)
- **Credentials**:
  - Root password: `root_password`
  - Database: `akaunting`
  - User: `akaunting_user`
  - Password: `akaunting_pass`
- **Features**:
  - Health checks to ensure readiness
  - Persistent volume (`mysql_data`)

#### 2. Application Service
- **Base Image**: Custom Dockerfile (PHP 8.3-fpm)
- **Purpose**: Akaunting application server
- **Port**: 8000 (exposed to host)
- **Features**:
  - PHP 8.3 with all required extensions
  - Node.js 16 for asset compilation
  - Composer 2 for dependency management
  - Multi-stage build (base + development)
  - Source code mounted as volume for live editing
  - Runs `php artisan serve` as command

#### 3. phpMyAdmin Service
- **Image**: `phpmyadmin:latest`
- **Purpose**: Web-based database management
- **Port**: 8080 (exposed to host)
- **Features**:
  - Auto-connects to MySQL service
  - Root access pre-configured

### Volumes

- **mysql_data**: Persists MySQL database between container restarts
- **storage_data**: Persists Laravel storage directory
- **Source mount**: `.` → `/var/www/html` for live code editing

### Network

All services communicate via a bridge network (`akaunting-network`) which provides:
- Service discovery by name (e.g., `mysql` hostname)
- Isolation from other Docker networks
- Internal DNS resolution

## Files Created

### 1. Dockerfile

Multi-stage Dockerfile with two stages:

**Base Stage** (`FROM php:8.3-fpm AS base`):
- System dependencies (git, curl, libpng, libxml2, libzip, etc.)
- PHP extensions: bcmath, ctype, fileinfo, intl, gd, mbstring, pdo, pdo_mysql, tokenizer, xml, zip
- Composer 2 from official image
- Node.js 16 via NodeSource repository
- npm 8
- Production dependencies and asset build
- Proper file permissions for www-data

**Development Stage** (`FROM base AS development`):
- Inherits from base
- Installs dev dependencies
- Exposes port 8000
- Runs `php artisan serve`

### 2. docker-compose.yml

Orchestrates all three services with:
- Service dependencies (app depends on mysql health check)
- Port mappings
- Environment variables
- Volume mounts
- Network configuration

### 3. scripts/initialize.sh

Comprehensive initialization script (250+ lines) that:

1. **Pre-flight Checks**:
   - Verifies Docker and Docker Compose installation
   - Checks if Docker daemon is running

2. **Environment Setup**:
   - Stops and removes any existing containers
   - Builds Docker images with `--no-cache`
   - Starts MySQL and waits for health check (up to 60 seconds)
   - Creates/updates `.env` file with MySQL configuration

3. **Application Setup**:
   - Starts application container
   - Installs Composer dependencies with `--optimize-autoloader --ignore-platform-reqs`
   - Installs npm dependencies with `--legacy-peer-deps`
   - Builds frontend assets with `npm run dev`
   - Generates application key

4. **Database Setup**:
   - Runs migrations with `--force` flag
   - Seeds sample data via `php artisan sample-data:seed --force`

5. **Finalization**:
   - Clears all Laravel caches (config, route, view, cache)
   - Sets proper permissions on storage and bootstrap/cache

6. **Sanity Checks**:
   - Verifies PHP 8.3 installation
   - Verifies Node 16 installation
   - Tests database connection
   - Counts database tables (should be 10+)

7. **Output**:
   - Colored success/warning/error messages
   - Access URLs and credentials
   - Next steps instructions

### 4. scripts/start.sh

Simplified startup script that:

1. **Validation**:
   - Checks Docker installation and daemon status
   - Verifies environment has been initialized (`.env` exists)
   - Warns if database not configured for MySQL

2. **Startup**:
   - Starts all Docker containers via `docker-compose up -d`
   - Waits for MySQL health check
   - Allows application startup time (3 seconds)

3. **Status Display**:
   - Shows container status via `docker-compose ps`
   - Displays access URLs and credentials
   - Lists useful Docker commands

## Prerequisites

- **Docker Desktop**: Installed and running
- **Disk Space**: ~2GB for images and volumes
- **Ports Available**: 3306, 8000, 8080
- **Internet Connection**: Required for initial image pulls

## Installation Steps

### First Time Setup

```bash
# 1. Make scripts executable
chmod +x scripts/initialize.sh scripts/start.sh

# 2. Run initialization (this will take 5-10 minutes)
./scripts/initialize.sh
```

The initialization script will:
- Build Docker images
- Install all dependencies
- Set up the database with sample data
- Configure the application
- Run sanity checks

Expected output:
```
======================================
Akaunting Docker Initialization
======================================

→ Checking Docker installation...
✓ Docker is installed
→ Checking if Docker daemon is running...
✓ Docker daemon is running
→ Cleaning up any existing containers...
✓ Cleanup complete
→ Building Docker images (this may take a few minutes)...
[Build output...]
✓ Docker images built successfully

[... continued setup steps ...]

======================================
Initialization Complete!
======================================

✓ Akaunting is ready to use!

Access URLs:
  - Application: http://localhost:8000
  - phpMyAdmin:  http://localhost:8080

Database Credentials:
  - Host:     mysql (or localhost:3306 from host)
  - Database: akaunting
  - Username: akaunting_user
  - Password: akaunting_pass

Default Admin Credentials (if sample data was seeded):
  - Email:    admin@company.com
  - Password: 123456
```

### Subsequent Starts

```bash
# Start the environment
./scripts/start.sh
```

This will:
- Start all containers
- Wait for MySQL to be ready
- Display access information

## Usage

### Access URLs

- **Application**: http://localhost:8000
- **phpMyAdmin**: http://localhost:8080
  - Server: `mysql`
  - Username: `root`
  - Password: `root_password`

### Default Credentials

If sample data was seeded during initialization:
- **Email**: admin@company.com
- **Password**: 123456

### Common Commands

```bash
# View all container logs
docker-compose logs -f

# View only application logs
docker-compose logs -f app

# Execute artisan commands
docker-compose exec app php artisan [command]

# Access application shell
docker-compose exec app bash

# Access MySQL shell
docker-compose exec mysql mysql -u akaunting_user -pakaunting_pass akaunting

# Stop the environment
docker-compose stop

# Stop and remove containers (data persists in volumes)
docker-compose down

# Stop and remove everything including volumes (DESTRUCTIVE)
docker-compose down -v

# Restart a specific service
docker-compose restart app

# Rebuild images
docker-compose build --no-cache

# View container status
docker-compose ps
```

### Development Workflow

1. **Start Environment**:
   ```bash
   ./scripts/start.sh
   ```

2. **Make Code Changes**:
   - Edit files in your local directory
   - Changes are immediately reflected (source code is mounted)

3. **Rebuild Assets** (if you changed JS/CSS):
   ```bash
   docker-compose exec app npm run dev
   # Or for watch mode:
   docker-compose exec app npm run watch
   ```

4. **Run Migrations** (if you changed database schema):
   ```bash
   docker-compose exec app php artisan migrate
   ```

5. **Clear Cache** (if you changed config/routes):
   ```bash
   docker-compose exec app php artisan cache:clear
   docker-compose exec app php artisan config:clear
   ```

6. **Stop Environment**:
   ```bash
   docker-compose stop
   ```

## Technical Details

### PHP Extensions Installed

All extensions required by Akaunting:
- bcmath - Arbitrary precision mathematics
- ctype - Character type checking
- fileinfo - File information
- intl - Internationalization
- gd - Image processing (with freetype and jpeg support)
- mbstring - Multibyte string handling
- pdo - Database abstraction
- pdo_mysql - MySQL driver
- tokenizer - PHP tokenizer
- xml - XML parsing
- zip - ZIP archive handling

### Environment Variables

The `.env` file is automatically configured by `initialize.sh` with:

```env
APP_ENV=local
APP_DEBUG=true

DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=akaunting
DB_USERNAME=akaunting_user
DB_PASSWORD=akaunting_pass
```

### Multi-Stage Build Benefits

The Dockerfile uses multi-stage builds for:

1. **Image Size Optimization**: Base stage can be used for production (without dev dependencies)
2. **Build Caching**: Dependencies are cached in layers
3. **Flexibility**: Easy to create production-ready images in the future

### Health Checks

MySQL service includes health checks:
```yaml
healthcheck:
  test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-proot_password"]
  interval: 10s
  timeout: 5s
  retries: 5
```

This ensures the application only starts after MySQL is ready.

## Comparison with Previous Plans

### Plan 1: Node Downgrade (Direct on Host)
- **Pros**: Simple, no Docker overhead
- **Cons**: Still using PHP 8.4 (incompatible), modifies host system
- **Result**: npm dependencies installed but runtime errors due to PHP 8.4

### Plan 2: Modernize Dependencies
- **Status**: Not executed (would require extensive code changes)
- **Scope**: Upgrade to Vite, Vue 3, Node 22
- **Effort**: High (estimated 2-3 days of work)

### Plan 3: Fix PHP Setup (SQLite on Host)
- **Pros**: Quick workaround for database
- **Cons**: PHP 8.4 incompatible, SQLite not production-like, manual setup required
- **Result**: Database working but application throws constant errors

### Plan 4: Docker Setup (Current)
- **Pros**:
  - Correct PHP version (8.3)
  - Correct Node version (16)
  - Production-like database (MySQL)
  - Complete environment isolation
  - Reproducible across all machines
  - Sample data included
- **Cons**:
  - Requires Docker Desktop
  - Initial setup takes longer (~10 minutes)
  - Slightly more resource usage
- **Result**: ✅ Complete working environment

## Troubleshooting

### Container Won't Start

**Check Docker is running**:
```bash
docker info
```

**Check container logs**:
```bash
docker-compose logs app
docker-compose logs mysql
```

**Rebuild containers**:
```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Port Already in Use

**Identify what's using the port**:
```bash
lsof -i :8000  # Check app port
lsof -i :3306  # Check MySQL port
lsof -i :8080  # Check phpMyAdmin port
```

**Solution 1: Stop the conflicting service**

**Solution 2: Change ports in docker-compose.yml**:
```yaml
ports:
  - "8001:8000"  # Host:Container
```

### MySQL Connection Failed

**Wait longer**:
MySQL can take up to 60 seconds to initialize the first time.

**Check MySQL logs**:
```bash
docker-compose logs mysql
```

**Verify MySQL is running**:
```bash
docker-compose ps
```

**Reset MySQL volume**:
```bash
docker-compose down -v
./scripts/initialize.sh
```

### Permission Denied Errors

**Fix storage permissions**:
```bash
docker-compose exec app chown -R www-data:www-data /var/www/html/storage
docker-compose exec app chmod -R 755 /var/www/html/storage
```

### npm/Composer Errors

**Clear npm cache**:
```bash
docker-compose exec app npm cache clean --force
docker-compose exec app npm install --legacy-peer-deps
```

**Clear Composer cache**:
```bash
docker-compose exec app composer clear-cache
docker-compose exec app composer install --optimize-autoloader
```

### Application Returns 500 Error

**Check application logs**:
```bash
docker-compose logs app
```

**Check Laravel logs**:
```bash
docker-compose exec app tail -f storage/logs/laravel.log
```

**Clear all caches**:
```bash
docker-compose exec app php artisan cache:clear
docker-compose exec app php artisan config:clear
docker-compose exec app php artisan route:clear
docker-compose exec app php artisan view:clear
```

**Re-run migrations**:
```bash
docker-compose exec app php artisan migrate:fresh --seed
docker-compose exec app php artisan sample-data:seed --force
```

### Complete Reset

If all else fails, start from scratch:

```bash
# Stop and remove everything
docker-compose down -v

# Remove any stale .env configuration
# (Will be recreated by initialize.sh)
# cp .env .env.backup  # Optional: backup first

# Re-initialize
./scripts/initialize.sh
```

## Performance Considerations

### Docker Desktop Settings

Recommended settings for optimal performance:
- **CPUs**: 4+
- **Memory**: 4GB+
- **Disk Image Size**: 60GB+

### Volume Performance

The source code is mounted as a volume for live editing. This can be slower on macOS/Windows due to cross-platform file system differences.

**For better performance on macOS**:
- Use Docker Desktop with VirtioFS (enabled by default in recent versions)
- Consider using mutagen or docker-sync for large projects

**For production deployments**:
- Remove volume mounts
- Copy code into image during build
- Use production build stage without dev dependencies

### Database Performance

MySQL is configured with default settings. For better performance:

1. Add MySQL configuration in `docker-compose.yml`:
```yaml
mysql:
  command: --default-authentication-plugin=mysql_native_password --max_connections=500
```

2. Or create a custom `my.cnf` and mount it:
```yaml
volumes:
  - ./docker/my.cnf:/etc/mysql/conf.d/my.cnf
```

## Future Enhancements

Possible improvements to this Docker setup:

1. **Production Stage**: Add production build stage to Dockerfile
2. **nginx**: Replace `artisan serve` with nginx + PHP-FPM for better performance
3. **Redis**: Add Redis service for caching and queues
4. **Mailhog**: Add Mailhog for email testing
5. **Xdebug**: Add Xdebug for debugging support
6. **CI/CD**: Create GitHub Actions workflow using these Docker images
7. **Multi-environment**: Create separate compose files for dev/staging/prod

## Maintenance

### Updating Dependencies

**Update Composer dependencies**:
```bash
docker-compose exec app composer update
docker-compose exec app php artisan migrate
```

**Update npm dependencies**:
```bash
docker-compose exec app npm update
docker-compose exec app npm run dev
```

### Backing Up Data

**Backup database**:
```bash
docker-compose exec mysql mysqldump -u akaunting_user -pakaunting_pass akaunting > backup.sql
```

**Restore database**:
```bash
docker-compose exec -T mysql mysql -u akaunting_user -pakaunting_pass akaunting < backup.sql
```

**Backup uploads/storage**:
```bash
tar -czf storage-backup.tar.gz storage/app/
```

## Conclusion

Plan 4 provides a robust, isolated development environment that solves all compatibility issues encountered in Plans 1-3. By using Docker, we ensure:

- ✅ Correct PHP version (8.3)
- ✅ Correct Node version (16)
- ✅ Production-like MySQL database
- ✅ Complete environment isolation
- ✅ Sample data for immediate testing
- ✅ Reproducible across all development machines

The two-script approach (`initialize.sh` and `start.sh`) makes it easy to set up once and start quickly on subsequent uses.
