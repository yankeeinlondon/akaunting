# Containerization

Akaunting can be run using Docker for a fully containerized development and production environment.

## Docker Setup

The project includes:

* **Dockerfile.local** - Production-ready Dockerfile (requires pre-built assets)
* **docker-compose.yml** - Full stack configuration with MySQL, phpMyAdmin, and Akaunting
* **Automated initialization** - Scripts for easy setup

### Quick Start with Docker

**Prerequisites:**

* Docker Desktop with at least 4GB memory allocated
* Node.js 16+ (for building frontend assets locally)

**Step 1: Build Frontend Assets**

Since `node-sass` requires significant memory during Docker builds, assets should be built locally first:

```bash
npm install --legacy-peer-deps
npm run production
```

**Step 2: Start Services**

```bash
docker-compose up -d
```

This will start:

<!-- * MySQL 8.0 database -->
* Akaunting application (PHP 8.3)
* phpMyAdmin for database management

**Step 3: Initialize Database**

```bash
docker-compose exec app php artisan install \
  --db-host="mysql" \
  --db-name="akaunting" \
  --db-username="akaunting_user" \
  --db-password="akaunting_pass" \
  --admin-email="admin@company.com" \
  --admin-password="123456"
```

**Step 4: Create Public Symlink**

```bash
cd public && ln -s . public
```

### Access the Application

* **Application:** <http://localhost:8000>
* **phpMyAdmin:** <http://localhost:8080>
* **Default Login:** <admin@company.com> / 123456

### Docker Services

**MySQL Database**
* Container: `akaunting-mysql`
* Port: 3306
* Database: `akaunting`
* Credentials: `akaunting_user` / `akaunting_pass`

**Akaunting Application**
* Container: `akaunting-app`
* Port: 8000
* Volume: Mounts current directory for development

**phpMyAdmin**
* Container: `akaunting-phpmyadmin`
* Port: 8080

### Development Workflow

When modifying frontend assets:

```bash
npm run dev          # Development build with watch
npm run production   # Production build
```

Managing containers:

```bash
docker-compose up -d        # Start all services
docker-compose down         # Stop all services
docker-compose logs -f app  # View application logs
docker-compose exec app bash # Access container shell
```

### Environment Configuration

The `.env` file is configured for Docker with the following key settings:

```
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=akaunting
DB_USERNAME=akaunting_user
DB_PASSWORD=akaunting_pass
APP_URL=http://localhost:8000
```

### Troubleshooting

**Build Memory Issues:**
If you encounter memory errors during `docker-compose build`, ensure Docker Desktop has at least 4GB RAM allocated (Settings → Resources → Memory).

**Missing Assets:**
If CSS/JS files return 404 errors, ensure you've:

1. Built assets locally with `npm run production`
2. Created the `public/public` symlink

**Database Connection Errors:**
Wait for MySQL to be healthy before running installation:

```bash
docker-compose exec mysql mysqladmin ping -h localhost -u root -proot_password
```

