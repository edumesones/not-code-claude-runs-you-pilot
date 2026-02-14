# Publishing ralph-spec-agent-mem to NPM

Complete guide to publish the methodology to npm as `ralph-spec-agent-mem`.

## Prerequisites

### 1. NPM Account

```bash
# Create account at npmjs.com if you don't have one
# Then login:
npm login
```

Enter your credentials:
- Username: `edumesones` (or your npm username)
- Password: `***`
- Email: `edumesones@gmail.com`
- Two-factor authentication code (if enabled)

### 2. Verify Configuration

```bash
# Check you're logged in
npm whoami

# Should output: edumesones (or your username)
```

## Pre-Publication Checklist

### 1. Verify Package Files

```bash
# See what will be published
npm pack --dry-run

# This shows all files that will be included
# Check that:
# ✅ bin/ directory is included
# ✅ install.sh and install.ps1 are included
# ✅ .claude/ directory is included
# ✅ docs/ directory is included
# ✅ .memory-system/ is included
# ❌ node_modules/ is excluded
# ❌ .git/ is excluded
# ❌ test results are excluded
```

### 2. Test Locally

```bash
# Create a test package
npm pack

# This creates: ralph-spec-agent-mem-1.0.0.tgz

# Install it globally to test
npm install -g ./ralph-spec-agent-mem-1.0.0.tgz

# Test the CLI
ralph-spec-agent-mem --help
ralph-spec-agent-mem --version

# Test installation (use a test directory)
cd /tmp/test-project
ralph-spec-agent-mem install

# Cleanup
npm uninstall -g ralph-spec-agent-mem
rm ralph-spec-agent-mem-1.0.0.tgz
```

### 3. Verify package.json

Check these fields in `package.json`:

```json
{
  "name": "ralph-spec-agent-mem",           ✅
  "version": "1.0.0",                       ✅ Update before each publish
  "description": "...",                     ✅
  "keywords": [...],                        ✅
  "homepage": "...",                        ✅
  "repository": {...},                      ✅
  "author": "Eduardo Mesones <...>",        ✅
  "license": "MIT",                         ✅
  "bin": {...}                              ✅
}
```

### 4. Verify README.md

The `README.md` file is displayed on npmjs.com package page.

Check:
- ✅ Clear description
- ✅ Installation instructions
- ✅ Usage examples
- ✅ Links to documentation
- ✅ Badges (version, license)

## Publishing Steps

### 1. First-Time Publication

```bash
# Make sure you're in the project root
cd /path/to/not-code-claude-runs-you-pilot

# Verify all files are committed
git status

# Publish to npm
npm publish
```

**Expected output:**
```
+ ralph-spec-agent-mem@1.0.0
```

### 2. Verify Publication

```bash
# Check the package page
npm view ralph-spec-agent-mem

# Visit the npm page
open https://www.npmjs.com/package/ralph-spec-agent-mem
```

### 3. Test Installation

```bash
# Install from npm
npm install -g ralph-spec-agent-mem

# Test
ralph-spec-agent-mem --version
ralph-spec-agent-mem --help

# Test installation in a new project
mkdir /tmp/test-npm-install
cd /tmp/test-npm-install
ralph-spec-agent-mem
```

## Updating the Package

### 1. Update Version

Follow [Semantic Versioning](https://semver.org/):

- **Patch** (1.0.0 → 1.0.1): Bug fixes
- **Minor** (1.0.0 → 1.1.0): New features, backward compatible
- **Major** (1.0.0 → 2.0.0): Breaking changes

```bash
# Bump version automatically
npm version patch   # 1.0.0 → 1.0.1
npm version minor   # 1.0.0 → 1.1.0
npm version major   # 1.0.0 → 2.0.0

# This also creates a git tag
```

### 2. Publish Update

```bash
# Commit changes
git add .
git commit -m "Bump version to X.Y.Z"

# Push with tags
git push origin main --tags

# Publish to npm
npm publish
```

## Common Issues

### "Package already exists"

If you get this error, the package name is already taken.

**Solution**: Choose a different name or use a scoped package:
```bash
# Change name in package.json to:
"name": "@yourusername/ralph-spec-agent-mem"

# Then publish with access flag
npm publish --access public
```

### "You must be logged in"

**Solution**:
```bash
npm logout
npm login
```

### "Two-factor authentication required"

**Solution**:
```bash
# Enable 2FA on npmjs.com
# Then use authentication code during publish
npm publish --otp=123456
```

### "Permission denied"

**Solution**: Make sure bin files are executable:
```bash
chmod +x bin/ralph-spec-agent-mem
chmod +x bin/postinstall.js
git add bin/
git commit -m "Make bin files executable"
```

## Unpublishing (Emergency Only)

⚠️ **Warning**: Unpublishing is permanent and can break dependents.

Only unpublish if:
- Published within last 72 hours
- No other packages depend on it
- Critical security issue

```bash
# Unpublish specific version
npm unpublish ralph-spec-agent-mem@1.0.0

# Unpublish all versions (DANGEROUS)
npm unpublish ralph-spec-agent-mem --force
```

**Better alternative**: Deprecate instead:
```bash
npm deprecate ralph-spec-agent-mem@1.0.0 "Security issue, please upgrade"
```

## Maintenance Checklist

### Regular Updates

- [ ] Update dependencies (if any added)
- [ ] Update documentation
- [ ] Test on all platforms (Windows, macOS, Linux)
- [ ] Update CHANGELOG.md
- [ ] Bump version
- [ ] Publish

### Version Strategy

- **v1.x.x**: Current stable (9-phase with VERIFY)
- **v2.x.x**: Major breaking changes (if methodology evolves)

## Distribution Stats

After publishing, monitor:

```bash
# View download stats
npm view ralph-spec-agent-mem

# Check weekly downloads
https://www.npmjs.com/package/ralph-spec-agent-mem
```

## Alternative Distribution

If you don't want to use npm, users can still install via:

```bash
# Direct from GitHub
curl -fsSL https://raw.githubusercontent.com/edumesones/not-code-claude-runs-you-pilot/main/install.sh | bash

# Or clone and run
git clone https://github.com/edumesones/not-code-claude-runs-you-pilot.git
cd not-code-claude-runs-you-pilot
bash install.sh
```

## Next Steps After Publishing

1. ✅ Update GitHub README with npm badge
2. ✅ Announce on social media / dev communities
3. ✅ Add to Claude Code documentation (if applicable)
4. ✅ Create GitHub release matching npm version
5. ✅ Monitor issues and feedback

## Support

If you encounter issues:

1. Check [npm documentation](https://docs.npmjs.com/)
2. Ask on [npm support](https://www.npmjs.com/support)
3. GitHub issues: https://github.com/edumesones/not-code-claude-runs-you-pilot/issues

---

**Happy Publishing! 🚀**
