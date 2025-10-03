# Plan 2: Modernize Dependencies and Build Tooling

## Overview

This plan involves upgrading the project's build tooling and dependencies to work with modern Node.js versions (v18+, including v22). The primary focus is migrating from Laravel Mix to Vite and updating deprecated packages.

## Problem Analysis

Current issues:
- **Laravel Mix 6** is based on Webpack 5, designed for Node 14-16
- **Vue 2** has reached EOL (Dec 2023)
- **node-sass** has been deprecated in favor of Dart Sass
- **Multiple deprecated packages**: glob, uuid v3, consolidate, etc.
- **Security vulnerabilities** in old dependency versions
- **Engine compatibility** issues with Node.js v22

## Strategic Goals

1. **Migrate to Vite**: Laravel's official recommendation since Laravel 9.19
2. **Update to modern Dart Sass**: Replace deprecated node-sass
3. **Upgrade compatible packages**: Update to versions supporting Node 18+
4. **Replace deprecated packages**: Find modern alternatives
5. **Maintain Vue 2.7**: Keep current frontend (Vue 3 migration is separate project)
6. **Fix security issues**: Address vulnerabilities in dependencies

## Implementation Steps

### Phase 1: Fix npm Cache Issue

```bash
# Fix permission error first
sudo chown -R $(whoami) ~/.npm

# Clean cache
npm cache clean --force

# Remove existing installation
rm -rf node_modules package-lock.json
```

### Phase 2: Migrate from Laravel Mix to Vite

#### Step 2.1: Install Vite Dependencies

Remove Laravel Mix packages and install Vite:

```bash
npm remove laravel-mix laravel-mix-tailwind
npm install --save-dev vite laravel-vite-plugin @vitejs/plugin-vue
```

#### Step 2.2: Create vite.config.js

Create `vite.config.js` in project root:

```javascript
import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';
import vue from '@vitejs/plugin-vue2'; // For Vue 2.7

export default defineConfig({
    plugins: [
        laravel({
            input: [
                'resources/assets/sass/app.css',
                'resources/assets/js/app.js',
                // Add other entry points from webpack.mix.js
            ],
            refresh: true,
        }),
        vue({
            template: {
                transformAssetUrls: {
                    base: null,
                    includeAbsolute: false,
                },
            },
        }),
    ],
    resolve: {
        alias: {
            '@': '/resources/assets/js',
            vue: 'vue/dist/vue.esm.js', // For Vue 2.7
        },
    },
    build: {
        rollupOptions: {
            output: {
                manualChunks: {
                    vendor: ['vue', 'axios', 'lodash'],
                },
            },
        },
    },
});
```

#### Step 2.3: Update package.json Scripts

Replace Mix scripts with Vite:

```json
{
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  }
}
```

#### Step 2.4: Update Blade Templates

Replace Mix helpers with Vite directives in layouts:

```blade
{{-- Old Mix --}}
<link rel="stylesheet" href="{{ mix('css/app.css') }}">
<script src="{{ mix('js/app.js') }}"></script>

{{-- New Vite --}}
@vite(['resources/assets/sass/app.css', 'resources/assets/js/app.js'])
```

#### Step 2.5: Update Laravel Configuration

In `config/app.php`, ensure Vite service provider is loaded (Laravel 9.19+):

```php
// Should already exist in Laravel 10
'providers' => [
    // ...
    Illuminate\Foundation\Providers\ViteServiceProvider::class,
],
```

### Phase 3: Update Core Dependencies

#### Step 3.1: Replace node-sass with Sass

```bash
npm remove node-sass
npm install --save-dev sass
```

#### Step 3.2: Update Deprecated Packages

Update `package.json` dependencies:

```json
{
  "dependencies": {
    // Keep Vue 2.7 (already latest Vue 2)
    "vue": "^2.7.16",

    // Update these packages
    "axios": "^1.7.0",
    "lodash": "^4.17.21",
    "moment": "^2.30.1",
    "dropzone": "^6.0.0-beta.2",
    "flatpickr": "^4.6.13",
    "glightbox": "^3.3.0",
    "mathjs": "^14.0.1",

    // Replace deprecated @themesberg/flowbite
    "flowbite": "^2.5.0", // Remove @themesberg/flowbite

    // Remove popper.js (already have @popperjs/core)
    // "popper.js": "^1.16.1", // REMOVE
    "@popperjs/core": "^2.11.8",

    // Remove tailwind stub package
    // "tailwind": "^4.0.0", // REMOVE
    "tailwindcss": "^3.4.0",

    // Update other packages
    "swiper": "^11.0.0",
    "ws": "^8.18.0"
  },
  "devDependencies": {
    // Vite and plugins (already added in Phase 2)
    "vite": "^5.4.0",
    "laravel-vite-plugin": "^1.0.0",
    "@vitejs/plugin-vue2": "^2.3.0",

    // Update build tools
    "sass": "^1.77.0",
    "autoprefixer": "^10.4.20",
    "postcss": "^8.4.47",
    "tailwindcss": "^3.4.0",

    // Update Vue tooling
    "vue-loader": "^15.11.1",
    "vue-template-compiler": "^2.7.16",

    // Remove webpack-related packages (now using Vite)
    // Keep only what's needed for module compatibility
  }
}
```

#### Step 3.3: Update Package Overrides

Update security-flagged packages:

```json
{
  "overrides": {
    "lodash": "^4.17.21",
    "moment": "^2.30.1",
    "jsonwebtoken": "^9.0.2",
    "ws": "^8.18.0",
    "postcss": "^8.4.47",
    "express": "^4.21.0",
    "body-parser": "^1.20.3",
    "glob": "^10.0.0", // Update from v7/v8
    "uuid": "^10.0.0"  // Update from v3
  }
}
```

### Phase 4: Handle Specific Deprecated Packages

#### Replace or Remove:

1. **consolidate** (deprecated)
   - Used by vue2-editor
   - Check if vue2-editor can be replaced with a modern alternative like Tiptap

2. **uuid v3** → **uuid v10**
   ```bash
   npm install uuid@^10.0.0
   ```

3. **glob v7/v8** → **glob v10**
   - Updated via overrides

4. **Multiple unsupported packages** (processenv, datasette, etc.)
   - These are likely transitive dependencies
   - Will be resolved by updating parent packages

### Phase 5: Configure PostCSS and Tailwind

#### Step 5.1: Update postcss.config.js

Ensure PostCSS is configured for Tailwind:

```javascript
export default {
  plugins: {
    'postcss-import': {},
    'tailwindcss/nesting': 'postcss-nesting',
    tailwindcss: {},
    autoprefixer: {},
  },
}
```

#### Step 5.2: Verify tailwind.config.js

Ensure Tailwind config works with Vite:

```javascript
export default {
  content: [
    './resources/views/**/*.blade.php',
    './resources/assets/js/**/*.vue',
    './resources/assets/js/**/*.js',
  ],
  // ... rest of config
}
```

### Phase 6: Update Build Configuration

#### Step 6.1: Convert webpack.mix.js Logic to Vite

Review existing `webpack.mix.js` and migrate:

```javascript
// Example from Laravel Mix:
mix.js('resources/assets/js/app.js', 'public/js')
   .vue()
   .sass('resources/assets/sass/app.css', 'public/css')
   .tailwind();

// Equivalent in vite.config.js:
laravel({
    input: [
        'resources/assets/js/app.js',
        'resources/assets/sass/app.css',
    ],
    refresh: true,
}),
```

#### Step 6.2: Handle Module-Specific Entries

If modules have their own asset entries, add them to Vite config:

```javascript
input: [
    'resources/assets/sass/app.css',
    'resources/assets/js/app.js',
    'modules/ModuleName/Resources/assets/js/app.js',
    // ... other module entries
],
```

### Phase 7: Testing and Validation

#### Step 7.1: Install Updated Dependencies

```bash
# Install all updated packages
npm install

# Verify no engine warnings
npm list --depth=0
```

#### Step 7.2: Test Development Build

```bash
# Start Vite dev server
npm run dev

# In another terminal, start Laravel
php artisan serve
```

Visit the application and verify:
- Assets load correctly
- Hot Module Replacement (HMR) works
- Vue components render
- Tailwind styles apply
- No console errors

#### Step 7.3: Test Production Build

```bash
# Build for production
npm run build

# Verify output in public/build/
ls -la public/build/

# Test production build
php artisan serve
```

#### Step 7.4: Run Security Audit

```bash
# Check for vulnerabilities
npm audit

# Fix auto-fixable issues
npm audit fix
```

### Phase 8: Update Documentation and CI/CD

#### Step 8.1: Update README.md

```markdown
## Requirements

- PHP 8.1 or higher
- Node.js 18+ or 20+ (LTS recommended)
- Composer 2.x

## Installation

```bash
composer install
npm install
npm run dev  # or npm run build for production
```
```

#### Step 8.2: Update .gitignore

```gitignore
# Vite build output
/public/build
/public/hot

# Keep existing entries
/node_modules
/public/storage
```

#### Step 8.3: Update CI/CD Pipelines

Update GitHub Actions, GitLab CI, or other pipelines:

```yaml
# Example GitHub Actions
- name: Setup Node
  uses: actions/setup-node@v4
  with:
    node-version: '20'

- name: Install dependencies
  run: npm ci

- name: Build assets
  run: npm run build
```

### Phase 9: Module Compatibility

#### Check Module Assets

1. Review each module in `/modules` for custom assets
2. Update module asset compilation if needed
3. Test module functionality after migration

## Migration Checklist

### Pre-Migration
- [ ] Backup current working state
- [ ] Document current webpack.mix.js configuration
- [ ] List all asset entry points
- [ ] Identify module-specific assets

### Migration
- [ ] Install Vite and remove Laravel Mix
- [ ] Create vite.config.js
- [ ] Update package.json scripts
- [ ] Replace node-sass with sass
- [ ] Update deprecated packages
- [ ] Update package overrides for security
- [ ] Convert Mix asset helpers to Vite directives
- [ ] Update tailwind.config.js and postcss.config.js

### Testing
- [ ] Development build works (`npm run dev`)
- [ ] Production build works (`npm run build`)
- [ ] HMR functions correctly
- [ ] All Vue components render
- [ ] Tailwind CSS compiles correctly
- [ ] Module assets work
- [ ] No console errors
- [ ] `npm audit` shows no critical vulnerabilities

### Post-Migration
- [ ] Update documentation
- [ ] Update CI/CD pipelines
- [ ] Commit changes with comprehensive message
- [ ] Train team on new build process

## Pros

✅ **Modern Tooling**: Vite is significantly faster than Webpack
✅ **Better DX**: Instant HMR, faster builds, better error messages
✅ **Node.js v22 Compatible**: Works with latest Node versions
✅ **Security**: Addresses known vulnerabilities
✅ **Official Laravel Support**: Vite is Laravel's recommended build tool
✅ **Future-Proof**: Positions project for easier upgrades
✅ **Performance**: Faster development and build times

## Cons

⚠️ **High Effort**: Requires 4-8 hours of focused work
⚠️ **Risk of Breaking Changes**: Asset references may need updates
⚠️ **Learning Curve**: Team needs to understand Vite
⚠️ **Module Impact**: Custom modules may need asset updates
⚠️ **Testing Required**: Comprehensive testing needed
⚠️ **Temporary Disruption**: May block development during migration

## Risk Mitigation

1. **Create Feature Branch**: `git checkout -b feature/vite-migration`
2. **Incremental Migration**: Migrate one asset entry at a time
3. **Parallel Development**: Keep Mix working until Vite is validated
4. **Comprehensive Testing**: Test all features before merging
5. **Team Communication**: Ensure all developers are prepared
6. **Rollback Plan**: Keep Mix configuration until Vite is stable

## Estimated Timeline

- **Phase 1-2** (Vite Setup): 1-2 hours
- **Phase 3-4** (Dependency Updates): 2-3 hours
- **Phase 5-6** (Configuration): 1-2 hours
- **Phase 7** (Testing): 2-3 hours
- **Phase 8-9** (Documentation & Modules): 1-2 hours

**Total**: 8-12 hours (depending on module complexity)

## Success Criteria

- [ ] All assets compile successfully with Vite
- [ ] Development experience improved (faster HMR)
- [ ] Production builds optimized
- [ ] No deprecated package warnings
- [ ] `npm audit` shows no critical issues
- [ ] Compatible with Node.js 18, 20, and 22
- [ ] Documentation updated
- [ ] Team trained on new process

## Post-Migration Opportunities

After successful migration, consider:

1. **Vue 3 Migration**: Easier with Vite in place
2. **TypeScript**: Vite has excellent TypeScript support
3. **Modern CSS**: PostCSS plugins, CSS modules
4. **Code Splitting**: Advanced chunking strategies
5. **PWA**: Add Vite PWA plugin

## Rollback Plan

If migration fails:

```bash
# Restore original package.json
git checkout main -- package.json

# Reinstall original dependencies
rm -rf node_modules package-lock.json
npm install

# Use original Mix build
npm run dev
```

---

**Estimated Time**: 8-12 hours
**Risk Level**: Medium-High
**Recommended For**: Long-term project health and modernization
**Best Approach**: Execute after Plan 1 stabilizes development
