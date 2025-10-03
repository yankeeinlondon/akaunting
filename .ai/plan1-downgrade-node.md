# Plan 1: Downgrade Node.js to v16

## Overview

This plan focuses on using a Node.js version that aligns with the existing dependency tree in the Akaunting project. By downgrading to Node.js v16 LTS, we can avoid the engine compatibility issues while maintaining the current package structure.

## Problem Analysis

The current issues stem from:

- Node.js v22 is too modern for many dependencies (e.g., `amqplib@0.5.2` requires `node: '>=0.8 <=9'`)
- Laravel Mix 6 and Vue 2.7 were designed for Node.js v14-v16 era
- Many deprecated packages still function correctly on older Node versions
- npm cache permission error (likely a side effect of failed installations)

## Target Environment

- **Node.js Version**: v16.x (latest v16.20.x recommended)
- **npm Version**: v8.x (comes with Node 16)
- **Rationale**: Node 16 LTS supports:
  - Laravel Mix 6.x
  - Vue 2.7.x
  - Webpack 5.x
  - All current dependencies without major issues

## Implementation Steps

### Step 1: Verify or Install `n` (if not already installed)

**Check if `n` is installed:**

```bash
n --version
```

**If not installed, install `n`:**

```bash
# Install n globally
npm install -g n
```

### Step 2: Install Node.js v16

```bash
# Install and switch to Node 16
n 16

# Or install latest LTS (which is currently v20, but you can specify 16)
n lts

# Verify versions
node --version  # Should show v16.x.x
npm --version   # Should show v8.x.x
```

### Step 3: Clean npm Cache and Existing Installation

```bash
# Clean npm cache completely
npm cache clean --force

# Remove existing node_modules and lock file
rm -rf node_modules
rm -f package-lock.json

# Fix npm cache permissions (if permission errors occur)
sudo chown -R $(whoami) ~/.npm
```

### Step 4: Reinstall Dependencies

```bash
# Install all dependencies
npm install

# This should complete without engine compatibility errors
```

### Step 5: Create .n-node-version File

Create a `.n-node-version` file in the project root to persist the Node version:

```bash
echo "16" > .n-node-version
```

This allows `n` to automatically use the correct version when in this directory (with `n auto` enabled).

### Step 6: Test the Build Process

```bash
# Test development build
npm run dev

# Test watch mode
npm run watch

# Test production build
npm run production
```

### Step 7: Update Documentation

Add to the project README:

```markdown
## Node.js Version Requirement

This project requires Node.js v16.x. We recommend using `n` to manage Node.js versions.

### Using n:
```bash
n 16
npm install
npm run dev
```
```

### Step 8: (Optional) Add npm Script

Add a preinstall check to `package.json`:

```json
{
  "scripts": {
    "preinstall": "node -e \"if(parseInt(process.version.slice(1).split('.')[0]) > 16) { console.error('This project requires Node.js v16.x. Please switch versions: n 16'); process.exit(1); }\""
  }
}
```

## Expected Outcomes

### Successful Installation

- All npm packages install without engine warnings
- No EACCES permission errors
- `node_modules` directory fully populated
- `package-lock.json` created successfully

### Successful Build

- `npm run dev` completes without errors
- Assets compiled to `public/` directory:
  - `public/css/app.css`
  - `public/js/app.js`
  - Vue components compiled correctly
  - Tailwind CSS processed

## Troubleshooting

### If Engine Warnings Persist

```bash
# Install with legacy peer deps (forces compatibility)
npm install --legacy-peer-deps
```

### If Permission Errors Occur

```bash
# Fix npm directory permissions
sudo chown -R $(whoami) ~/.npm
sudo chown -R $(whoami) /usr/local/lib/node_modules

# Or use npm's built-in permission fix
npx npm-check-permissions --fix
```

### If Specific Packages Fail

```bash
# Clear cache and reinstall specific package
npm cache clean --force
npm install <package-name> --force
```

## Pros

✅ **Quick Implementation**: Can be done in 10-15 minutes
✅ **Minimal Risk**: No code or configuration changes required
✅ **Proven Compatibility**: Node 16 is known to work with this stack
✅ **Preserves Current Dependencies**: No need to update packages
✅ **Team-Friendly**: Easy for other developers to replicate with `n`

## Cons

⚠️ **Older Node Version**: Node 16 entered maintenance mode (Sept 2023), will be EOL April 2024
⚠️ **Technical Debt**: Doesn't address deprecated packages
⚠️ **Security**: Older dependencies may have unpatched vulnerabilities
⚠️ **Future Limitations**: May block adoption of newer tools/packages
⚠️ **Temporary Solution**: Will eventually need to modernize

## Long-Term Considerations

This is a **tactical solution** to unblock development. Consider:

1. **Plan for Modernization**: Schedule Plan 2 (dependency upgrades) within 3-6 months
2. **Monitor Node 16 EOL**: Node 16 reaches end-of-life in April 2024
3. **Security Updates**: Regularly check for security patches using `npm audit`
4. **Team Communication**: Ensure all developers know to use Node 16

## Success Criteria

- [ ] Node.js v16 installed and active
- [ ] `npm install` completes without errors
- [ ] `npm run dev` successfully builds assets
- [ ] `.n-node-version` file created for team consistency
- [ ] Documentation updated
- [ ] All team members can replicate the setup

## Next Steps After Completion

1. Verify the Laravel application runs: `php artisan serve`
2. Test frontend functionality in browser
3. Consider running `npm audit` to identify security issues
4. Plan timeline for executing Plan 2 (modernization)
5. Document any remaining deprecation warnings for future reference

---

**Estimated Time**: 15-30 minutes
**Risk Level**: Low
**Recommended For**: Immediate unblocking of development
