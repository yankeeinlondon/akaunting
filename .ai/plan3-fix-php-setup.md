# Plan 3: Fix PHP Setup and Missing Vendor Directory

## Problem Analysis

### Primary Issue: Missing vendor/autoload.php

The error occurs because the `vendor/` directory doesn't exist:

```
PHP Fatal error: Failed opening required '/Volumes/coding/forks/akaunting/bootstrap/../vendor/autoload.php'
```

**Root Cause**: `composer install` was never run. In Plan 1, we only ran `npm install` to install JavaScript dependencies, but we skipped the PHP dependency installation step.

### Secondary Issue: PHP Version Compatibility

**Current PHP Version**: 8.4.13
**Required by composer.json**: ^8.1 (which means 8.1.x, 8.2.x, or 8.3.x)

PHP 8.4 was released in November 2024, which is after Laravel 10's stable release. While the `^8.1` constraint technically allows 8.4, there may be compatibility issues because:

1. Laravel 10 was developed and tested primarily on PHP 8.1-8.3
2. PHP 8.4 introduced deprecations and changes that may affect Laravel 10 packages
3. Some dependencies may not have been tested with PHP 8.4

### Good News: PHP Extensions

All required PHP extensions are already installed ✅:

- ✅ BCMath
- ✅ Ctype
- ✅ cURL
- ✅ DOM
- ✅ FileInfo
- ✅ Intl
- ✅ GD
- ✅ JSON
- ✅ Mbstring
- ✅ OpenSSL
- ✅ PDO (including pdo_mysql, pdo_pgsql, pdo_sqlite)
- ✅ Tokenizer
- ✅ XML
- ✅ Zip

## Implementation Plan

### Phase 1: Install PHP Dependencies (Immediate Fix)

#### Step 1.1: Run Composer Install

```bash
composer install
```

This will:
- Download all PHP packages defined in `composer.lock`
- Create the `vendor/` directory
- Generate `vendor/autoload.php`
- Run post-install scripts (IDE helper generation)

**Expected Duration**: 2-5 minutes depending on network speed

#### Step 1.2: Verify Installation

```bash
# Check vendor directory exists
ls -la vendor/autoload.php

# Verify Artisan works
php artisan --version
```

**Expected Output**: Should show Laravel version (10.x)

### Phase 2: Test Laravel Installation Command

#### Step 2.1: Run Installation

```bash
php artisan install \
  --db-name="akaunting" \
  --db-username="root" \
  --db-password="pass" \
  --admin-email="admin@company.com" \
  --admin-password="123456"
```

**Note**: This requires a database server (MySQL/MariaDB/PostgreSQL) to be running.

#### Step 2.2: Handle Potential Issues

If installation fails, check:

1. **Database connection**:
   ```bash
   # For MySQL/MariaDB
   mysql -u root -ppass -e "SHOW DATABASES;"

   # For PostgreSQL
   psql -U root -l
   ```

2. **PHP 8.4 compatibility errors**:
   - If you see deprecation warnings or errors, proceed to Phase 3

### Phase 3: PHP Version Management (If Needed)

#### Option A: Install PHP 8.3 via Homebrew

If PHP 8.4 causes compatibility issues:

```bash
# Install PHP 8.3
brew install php@8.3

# Unlink current PHP
brew unlink php

# Link PHP 8.3
brew link php@8.3 --force --overwrite

# Verify version
php --version  # Should show 8.3.x
```

#### Option B: Use phpbrew or phpenv

If you need to manage multiple PHP versions:

```bash
# Install phpbrew
curl -L -O https://github.com/phpbrew/phpbrew/releases/latest/download/phpbrew.phar
chmod +x phpbrew.phar
sudo mv phpbrew.phar /usr/local/bin/phpbrew

# Initialize
phpbrew init

# Install PHP 8.3
phpbrew install 8.3 +default +mysql +pdo +gd +intl +zip

# Switch to PHP 8.3
phpbrew switch 8.3
```

### Phase 4: Database Setup

#### Step 4.1: Verify Database Server

Check if you have a database server installed:

```bash
# MySQL/MariaDB
which mysql
mysql --version

# PostgreSQL
which psql
psql --version

# SQLite (lightweight option, no server needed)
which sqlite3
sqlite3 --version
```

#### Step 4.2: Install Database Server (If Needed)

**Option 1: MySQL via Homebrew**
```bash
brew install mysql
brew services start mysql

# Secure installation
mysql_secure_installation
```

**Option 2: MariaDB via Homebrew**
```bash
brew install mariadb
brew services start mariadb

# Secure installation
mysql_secure_installation
```

**Option 3: PostgreSQL via Homebrew**
```bash
brew install postgresql@16
brew services start postgresql@16

# Create user
createuser root --createdb --pwprompt
```

**Option 4: SQLite (Simplest, No Server)**
```bash
# SQLite is usually pre-installed on macOS
# No setup needed, just change installation command:
php artisan install \
  --db-type="sqlite" \
  --admin-email="admin@company.com" \
  --admin-password="123456"
```

#### Step 4.3: Create Database

For MySQL/MariaDB:
```bash
mysql -u root -p -e "CREATE DATABASE akaunting CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
```

For PostgreSQL:
```bash
createdb akaunting
```

For SQLite:
```bash
# No database creation needed, Laravel will create the file
```

## Execution Checklist

### Required Steps (Must Do)
- [ ] Run `composer install`
- [ ] Verify `vendor/autoload.php` exists
- [ ] Test `php artisan --version`
- [ ] Verify database server is running
- [ ] Create `akaunting` database (or use SQLite)
- [ ] Run `php artisan install` command

### Optional Steps (If Issues Arise)
- [ ] Downgrade to PHP 8.3 if compatibility issues occur
- [ ] Install database server if not present
- [ ] Configure database credentials in `.env` file

## Expected Outcomes

### Successful Installation

After `composer install`:
```
✓ vendor/ directory created
✓ vendor/autoload.php exists
✓ ~500+ packages installed
✓ IDE helper files generated
```

After `php artisan install`:
```
✓ .env file created with database credentials
✓ Application key generated
✓ Database tables created
✓ Admin user created
✓ Sample data seeded (if requested)
```

### Success Indicators

1. **Composer Success**:
   ```bash
   ls -la vendor/autoload.php
   # Should exist and not error
   ```

2. **Artisan Works**:
   ```bash
   php artisan --version
   # Should show: Laravel Framework 10.x.x
   ```

3. **Installation Complete**:
   ```bash
   php artisan serve
   # Should start development server at http://localhost:8000
   ```

## Troubleshooting

### Issue: Composer Install Fails with PHP 8.4 Errors

**Symptom**: Deprecation warnings or package incompatibilities

**Solution**:
1. Try `composer install --ignore-platform-reqs` (temporary workaround)
2. If that fails, downgrade to PHP 8.3 (Phase 3)

### Issue: Database Connection Failed

**Symptom**: SQLSTATE errors during installation

**Solutions**:
1. Verify database server is running: `brew services list`
2. Check credentials are correct
3. Ensure database exists: `mysql -u root -p -e "SHOW DATABASES;"`
4. Use SQLite as fallback (no server needed)

### Issue: Permission Errors During Installation

**Symptom**: Cannot write to storage or bootstrap/cache

**Solution**:
```bash
# Fix Laravel directory permissions
chmod -R 755 storage bootstrap/cache
```

### Issue: Post-Install Scripts Fail (IDE Helpers)

**Symptom**: ide-helper commands error during composer install

**Solution**:
```bash
# Install without scripts, then run manually
composer install --no-scripts

# Later, run scripts manually if needed
php artisan ide-helper:generate
php artisan ide-helper:meta
```

## Quick Start Summary

**Fastest path to get Akaunting running**:

```bash
# 1. Install PHP dependencies
composer install

# 2. Option A: Use SQLite (no database server needed)
php artisan install \
  --db-type="sqlite" \
  --admin-email="admin@company.com" \
  --admin-password="123456"

# 3. Start development server
php artisan serve

# 4. Visit http://localhost:8000
```

**OR if you prefer MySQL/MariaDB**:

```bash
# 1. Install PHP dependencies
composer install

# 2. Ensure MySQL/MariaDB is running
brew services start mysql  # or mariadb

# 3. Create database
mysql -u root -p -e "CREATE DATABASE akaunting CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# 4. Install Akaunting
php artisan install \
  --db-name="akaunting" \
  --db-username="root" \
  --db-password="YOUR_PASSWORD" \
  --admin-email="admin@company.com" \
  --admin-password="123456"

# 5. Start development server
php artisan serve
```

## Notes

1. **PHP 8.4 Compatibility**: While all extensions are present, PHP 8.4 is very new (released Nov 2024). If you encounter issues, downgrading to PHP 8.3 LTS is recommended.

2. **Database Choice**:
   - **SQLite**: Easiest for development, no server setup
   - **MySQL/MariaDB**: Production-like environment, better for testing
   - **PostgreSQL**: Advanced features, good for complex queries

3. **Security**: The default credentials shown above are for local development only. Never use these in production.

4. **Next Steps After Installation**:
   - Configure email settings in `.env`
   - Set up cron jobs for scheduled tasks
   - Configure queue workers if using queues
   - Review `config/` files for customization

---

**Estimated Time**: 5-15 minutes (depending on database setup)
**Risk Level**: Low
**Blockers**: Database server must be installed and running
