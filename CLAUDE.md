# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Akaunting is an online accounting software built with Laravel 10, VueJS 2, Tailwind CSS, and Livewire. It features a modular architecture with a RESTful API for extensibility.

**Tech Stack:**
- Backend: Laravel 10 (PHP 8.1+)
- Frontend: Vue 2.7, Livewire 3
- CSS: Tailwind CSS 3
- Build: Laravel Mix 6
- Testing: PHPUnit 10.5

## Development Commands

### Installation
```bash
# Install dependencies
composer install
npm install

# Build assets
npm run dev          # Development build
npm run watch        # Watch mode
npm run production   # Production build

# Install Akaunting
php artisan install --db-name="akaunting" --db-username="root" --db-password="pass" --admin-email="admin@company.com" --admin-password="123456"

# Optional: Create sample data
php artisan sample-data:seed
```

### Testing
```bash
# Run all tests
vendor/bin/phpunit

# Run specific test suite
vendor/bin/phpunit --testsuite=Unit
vendor/bin/phpunit --testsuite=Feature

# Run tests in parallel
vendor/bin/paratest
```

Tests are located in:
- `/tests/Unit` - Unit tests
- `/tests/Feature` - Feature tests
- `/modules/**/Tests/Unit` - Module unit tests
- `/modules/**/Tests/Feature` - Module feature tests

### IDE Helpers
```bash
# Generate IDE helper files (auto-runs after composer install/update)
php artisan ide-helper:generate
php artisan ide-helper:meta
php artisan ide-helper:models --nowrite
```

## Architecture

### Multi-Tenancy & Company Scoping
- All routes (except install/guest/wizard) are prefixed with `{company_id}`
- Models extend `App\Abstracts\Model` which includes company scoping via the `Tenants` trait
- Use `allCompanies()` scope to bypass company filtering

### Modular Architecture
- Modules are stored in `/modules` directory
- Uses `akaunting/laravel-module` package for module management
- Each module can have its own routes, controllers, models, views, migrations
- Module routes use custom route macros: `Route::admin()`, `Route::portal()`, `Route::api()`, etc.

### Route Structure
The application has multiple route contexts, each with its own middleware group:
- **Install** (`/install`) - Installation wizard
- **Guest** - Login, register, password reset
- **Wizard** (`{company_id}/wizard`) - Initial company setup
- **Common** (`{company_id}`) - Shared authenticated routes
- **Admin** (`{company_id}`) - Admin panel routes
- **Portal** (`{company_id}/portal`) - Customer/vendor portal
- **Preview** (`{company_id}/preview`) - Document preview
- **Signed** (`{company_id}/signed`) - Signed URL routes
- **API** (`/api`) - RESTful API (stateless, uses Sanctum)

All route files are in `/routes` directory. Route provider is at `app/Providers/Route.php`.

### Base Classes & Abstracts
Key abstract classes in `/app/Abstracts`:
- **Model** - Base model with multi-tenancy, soft deletes, search string, caching
- **Controller** - Base controller with common methods
- **ApiController** - API controller base
- **FormRequest** - Form request validation base
- **Job** / **JobShouldQueue** - Job bases
- **Export** / **Import** - Import/export bases
- **Report** - Report generation base
- **Widget** - Dashboard widget base

### Controllers by Domain
- **Auth** - User authentication (login, register, forgot password, users)
- **Banking** - Accounts, transactions, reconciliations, transfers
- **Sales** - Invoices, customers, recurring invoices
- **Purchases** - Bills, vendors, recurring bills
- **Common** - Items, contacts, companies, dashboards, reports, imports
- **Settings** - Categories, currencies, taxes, email templates, company settings
- **Modals** - AJAX modal controllers
- **Modules** - App store functionality
- **Portal** - Customer/vendor portal
- **Install** - Installation and updates

### Models & Domain Objects
Models are organized by domain in `/app/Models`:
- **Auth** - User, Role, Permission
- **Banking** - Account, Transaction, Transfer, Reconciliation
- **Document** - Document, DocumentItem, DocumentTotal (base for invoices/bills)
- **Common** - Company, Contact, Item, Dashboard, Widget
- **Setting** - Category, Currency, Tax, EmailTemplate
- **Module** - Module management

All models:
- Use `App\Abstracts\Model` as base
- Include multi-tenancy (company_id scoping)
- Support soft deletes by default
- Include model caching via `genealabs/laravel-model-caching`
- Use search string filtering via `lorisleiva/laravel-search-string`

### Document System
Invoices and Bills extend the same base document system:
- Base model: `App\Models\Document\Document`
- Related: `DocumentItem`, `DocumentTotal`, `DocumentHistory`
- Supports recurring documents (type ending with '-recurring')
- Uses document types: invoice, bill, invoice-recurring, bill-recurring

### Jobs Pattern
- Jobs are in `/app/Jobs/{Domain}` (e.g., Banking, Document, Setting)
- Queued jobs extend `App\Abstracts\JobShouldQueue`
- Sync jobs extend `App\Abstracts\Job`

### Traits for Shared Logic
Key traits in `/app/Traits`:
- **DateTime** - Company date/time formatting
- **Documents** - Document-related helpers
- **Modules** - Module management helpers
- **Permissions** - Permission checking
- **Recurring** - Recurring document logic
- **Transactions** - Transaction helpers
- **ViewComponents** - View component rendering

### Frontend Architecture
- Vue 2.7 components in `/resources/assets/js/components`
- Page-specific entry points in `/resources/assets/js/views/{domain}/` (compiled via webpack.mix.js)
- Tailwind CSS in `/resources/assets/sass/app.css`
- Blade templates in `/resources/views`
- Livewire components for reactive features

### API
- RESTful API at `/api` prefix
- Authentication via Laravel Sanctum
- Controllers in `/app/Http/Controllers/Api`
- Rate limited (configured in Route provider)

### Helper Functions
Global helpers in `/app/Utilities/helpers.php`:
- `user()` - Get authenticated user
- `user_id()` - Get current user ID
- `company_date()` / `company_date_format()` - Company date formatting
- And many other accounting-specific helpers

### Scopes
Custom query scopes (via traits on Model):
- `companyId($id)` - Filter by company
- `allCompanies()` - Remove company scope
- `enabled()` / `disabled()` - Filter by enabled status
- `isRecurring()` / `isNotRecurring()` - Filter recurring documents
- `collect($sort)` - Get filtered, sorted, paginated results
- `collectForExport()` - Export-optimized query

### Overrides
Custom overrides in `/overrides` for:
- Laravel framework classes (Illuminate namespace)
- Livewire classes
- Third-party packages (Maatwebsite Excel, etc.)

Overridden classes are excluded from classmap in `composer.json` and namespaced in autoload PSR-4.

## Code Style
- Follow PSR coding standards
- Imitate existing Akaunting code patterns
- Use descriptive variable names
- Models use singular names, database tables use plural
