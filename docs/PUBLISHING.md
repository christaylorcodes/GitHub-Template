# Publishing PowerShell Modules to PSGallery

Complete guide for publishing PowerShell modules to PowerShell Gallery with automated CI/CD.

## Table of Contents

- [Quick Start](#quick-start)
- [Prerequisites](#prerequisites)
- [Initial Setup](#initial-setup)
- [CI/CD Pipeline](#cicd-pipeline)
- [Local Pre-Push Validation](#local-pre-push-validation)
- [Release Process](#release-process)
- [Troubleshooting](#troubleshooting)

## Quick Start

```powershell
# 1. Test locally before pushing
./Tests/test-local.ps1

# 2. Commit your changes
git add .
git commit -m "Your changes"
git push origin main

# 3. Create and push a release tag
git tag -a v1.0.0 -m "Release v1.0.0 - Description"
git push origin v1.0.0
```

The CI/CD pipeline will automatically:
- Build and test your module
- Run PSScriptAnalyzer
- Publish to PowerShell Gallery
- Create a GitHub Release

## Prerequisites

### PowerShell Gallery API Key

1. Create account at [PowerShell Gallery](https://www.powershellgallery.com)
2. Navigate to Account → API Keys
3. Create new API key with "Push new packages and package versions" permission
4. **Save the key securely** - you can't view it again!

### GitHub Repository Setup

1. Create repository on GitHub
2. Clone locally and copy template files
3. Configure git remote:
   ```powershell
   git remote add origin https://github.com/username/ModuleName.git
   ```

## Initial Setup

### Step 1: Configure GitHub Secret

Add your PSGallery API key to GitHub:

**Repository Level (Simple):**
1. Go to: `https://github.com/username/repo/settings/secrets/actions`
2. Click "New repository secret"
3. Name: `PSGALLERY_API_KEY`
4. Value: Your API key from PowerShell Gallery
5. Click "Add secret"

**Organization Level (Reusable - requires GitHub organization):**
1. Convert personal account to organization if needed
2. Go to: `https://github.com/organizations/orgname/settings/secrets/actions`
3. Add `PSGALLERY_API_KEY` once
4. All repos automatically inherit it

### Step 2: Update Module Manifest

Edit `source/ModuleName.psd1`:

```powershell
@{
    ModuleVersion = '1.0.0'
    Author = 'Your Name'
    CompanyName = 'Your Company'
    Description = 'Module description'

    Tags = @('Keyword1', 'Keyword2')  # For PSGallery search
    ProjectUri = 'https://github.com/username/ModuleName'
    LicenseUri = 'https://github.com/username/ModuleName/blob/main/LICENSE'

    ReleaseNotes = @'
## Version 1.0.0
- Initial release
- Feature 1
- Feature 2
'@
}
```

### Step 3: Update CHANGELOG.md

```markdown
# Changelog

## [Unreleased]

## [1.0.0] - 2026-01-21

### Initial Release
- Feature 1
- Feature 2
```

## CI/CD Pipeline

### Workflow Overview

The `.github/workflows/ci.yml` pipeline handles everything automatically:

```
┌──────────────────────────────────────────────────┐
│  Push Tag: v1.0.0 or v1.0.0-beta1                │
└────────────────┬─────────────────────────────────┘
                 │
    ┌────────────▼──────────────┐
    │  1. VERSION & VALIDATE    │
    │  - Parse version from tag │
    │  - Detect prerelease      │
    │  - Validate tag matches   │
    │    module manifest        │
    └────────────┬──────────────┘
                 │ (fails fast on mismatch)
    ┌────────────▼──────────────┐
    │  2. BUILD & TEST          │
    │  - Install dependencies   │
    │  - PSScriptAnalyzer       │
    │  - Pester tests           │
    │  - Build module           │
    └────────────┬──────────────┘
                 │
    ┌────────────▼──────────────┐
    │  3. PUBLISH               │
    │  - Publish to PSGallery   │
    │  - Add -Prerelease flag   │
    │    when tag has suffix    │
    └────────────┬──────────────┘
                 │
    ┌────────────▼──────────────┐
    │  4. RELEASE               │
    │  - Extract CHANGELOG      │
    │  - Create GitHub Release  │
    │  - Upload module ZIP      │
    └───────────────────────────┘
```

### What Happens Automatically

When you push a tag matching `v*.*.*`:

| Step | What it does | On failure |
| ---- | ------------ | ---------- |
| Version validation | Compares tag to `ModuleVersion` in manifest | Workflow stops with clear error |
| Tests & analysis | Runs Pester + PSScriptAnalyzer | Workflow stops, nothing published |
| PSGallery publish | Publishes module (with `-Prerelease` if tag has suffix) | Workflow stops |
| GitHub Release | Extracts notes from CHANGELOG.md, creates release, attaches ZIP | Release created with fallback text if CHANGELOG section not found |

### What You Do Manually

1. Update `ModuleVersion` in `source/ModuleName.psd1`
2. Add a version entry to `CHANGELOG.md`
3. Run `./Tests/test-local.ps1`
4. Commit, push, then create and push the tag

The tag version **must match** the manifest `ModuleVersion` — the workflow will reject mismatches.

### Version Detection

The pipeline automatically determines version from git tags:

- **Stable**: `v1.0.0` → Version 1.0.0, Prerelease = ""
- **Prerelease**: `v1.0.0-beta1` → Version 1.0.0, Prerelease = "beta1"
- **No tag**: Uses manifest version, **does not publish**

### Branch Strategy

#### Option 1: Single Branch (Simple)
- All work on `main`
- Tag `main` for releases
- Best for: Solo developers, simple projects

#### Option 2: Prerelease Branch (Recommended)
- **main**: Stable releases only
  - Tag `v1.0.0`, `v2.0.0` for stable
- **prerelease**: Active development
  - Tag `v1.1.0-beta1`, `v1.1.0-rc1` for testing
  - Merge to `main` when ready for stable

```powershell
# Create prerelease branch
git checkout -b prerelease
git push -u origin prerelease

# Publish prerelease
git tag -a v1.1.0-beta1 -m "Beta release"
git push origin v1.1.0-beta1

# When ready for stable, merge to main
git checkout main
git merge prerelease
git tag -a v1.1.0 -m "Stable release"
git push origin main v1.1.0
```

## Local Pre-Push Validation

**ALWAYS run this before pushing:**

```powershell
./Tests/test-local.ps1
```

This runs the same checks as CI/CD:

1. **Build** - Ensures module compiles
2. **PSScriptAnalyzer** - Checks code quality
3. **Pester Tests** - Validates functionality

**Benefits:**
- Catch errors in ~30 seconds vs 5+ minutes in CI
- Save GitHub Actions minutes
- Faster feedback loop

### Options

```powershell
# Full validation
./Tests/test-local.ps1

# Skip tests (faster)
./Tests/test-local.ps1 -SkipTests

# Skip build (if already built)
./Tests/test-local.ps1 -SkipBuild

# Only run PSScriptAnalyzer
./Tests/test-local.ps1 -SkipBuild -SkipTests
```

## Release Process

### Stable Release (v1.0.0)

```powershell
# 1. Update version in source/ModuleName.psd1
ModuleVersion = '1.0.0'

# 2. Update CHANGELOG.md
## [1.0.0] - 2026-01-21
### Added
- New feature X

# 3. Test locally
./Tests/test-local.ps1

# 4. Commit changes
git add .
git commit -m "Prepare v1.0.0 release"
git push origin main

# 5. Create and push tag
git tag -a v1.0.0 -m "Release v1.0.0 - Description"
git push origin v1.0.0
```

### Prerelease (v1.1.0-beta1)

```powershell
# 1. Work on prerelease branch
git checkout prerelease

# 2. Make changes and commit
git add .
git commit -m "Add new feature"
git push origin prerelease

# 3. Tag prerelease
git tag -a v1.1.0-beta1 -m "Beta release for testing"
git push origin v1.1.0-beta1
```

Users install with:
```powershell
Install-Module -Name ModuleName -AllowPrerelease
```

### Promoting Prerelease to Stable

```powershell
# 1. Merge prerelease to main
git checkout main
git merge prerelease
git push origin main

# 2. Tag stable release
git tag -a v1.1.0 -m "Stable release v1.1.0"
git push origin v1.1.0
```

## Troubleshooting

### Version Already Published

**Error:**
```
The module 'ModuleName' with version '1.0.0' cannot be published as the
current version '1.0.0' is already available in the repository
```

**Solution:**
The improved workflow now handles this gracefully. It will skip re-publishing but still create the GitHub release.

If you need to fix and re-release:
1. Increment version to `1.0.1`
2. Tag as `v1.0.1`

### GitHub Release Permission Denied

**Error:**
```
Resource not accessible by integration
```

**Solution:**
Ensure the workflow has correct permissions (already fixed in template):

```yaml
publish:
  permissions:
    contents: write  # Required to create releases
```

### PSScriptAnalyzer Failures

**Common Issues:**

1. **Brace placement**
   ```powershell
   # Bad
   if ($condition) {
       # code
   } else {
       # code
   }

   # Good
   if ($condition) {
       # code
   }
   else {
       # code
   }
   ```

2. **Missing process block**
   ```powershell
   # Bad
   function Get-Something {
       [CmdletBinding()]
       param(
           [Parameter(ValueFromPipeline)]
           [string]$Name
       )
       # code
   }

   # Good
   function Get-Something {
       [CmdletBinding()]
       param(
           [Parameter(ValueFromPipeline)]
           [string]$Name
       )
       process {
           # code
       }
   }
   ```

3. **WiFi/Password parameters**

   If your module handles WiFi passphrases or similar string passwords (not security credentials), add to `PSScriptAnalyzerSettings.psd1`:

   ```powershell
   ExcludeRules = @(
       'PSAvoidUsingPlainTextForPassword'
       'PSAvoidUsingUsernameAndPasswordParams'
   )
   ```

### Test Failures

**Debug locally:**

```powershell
# Run tests with detailed output
./build.ps1 -Tasks test

# Run specific test file
Invoke-Pester -Path tests/Unit/Module.Tests.ps1 -Output Detailed
```

### Build Failures

**Common causes:**

1. **Missing dependencies**
   ```powershell
   ./build.ps1 -ResolveDependency -Tasks noop
   ```

2. **Module version mismatch**
   - Check `source/ModuleName.psd1` version matches expectations
   - Verify tests aren't checking for specific versions

3. **File encoding issues**
   - Ensure all `.ps1`/`.psm1` files are UTF-8 with BOM
   - Check line endings are consistent (LF or CRLF)

## Lessons Learned

Based on real-world PowerShell Gallery publishing experience:

### 1. Always Test Locally First
- Running `test-local.ps1` before every push saves time
- Catches 95% of issues in seconds
- GitHub Actions should be for final validation

### 2. Use Git Tags for Versions
- Single source of truth
- No version mismatch between manifest and tags
- Clear release history

### 3. Prerelease Branch Strategy
- `main` for stable releases only
- `prerelease` for active development
- Tag format determines if it's prerelease

### 4. PSScriptAnalyzer Configuration
- Some rules need exclusions for real-world code
- Document why rules are excluded

### 5. Workflow Permissions
- GitHub Actions needs explicit `contents: write` for releases
- Don't assume default GITHUB_TOKEN has all permissions

### 6. Handle Re-Publishing Gracefully
- Already-published versions shouldn't fail pipeline
- Allow re-running builds without errors
- Still create GitHub release even if PSGallery publish skipped

## Migration Guide

### Upgrading an Existing Module

If you already have a module and want to adopt this template's CI/CD:

1. Copy the CI/CD workflows:
   ```powershell
   cp .github/workflows/ci.yml <your-module>/.github/workflows/
   cp .github/workflows/pr-validation.yml <your-module>/.github/workflows/
   ```

2. Copy quality tools:
   ```powershell
   cp .PSScriptAnalyzerSettings.psd1 <your-module>/
   cp Tests/test-local.ps1 <your-module>/Tests/
   ```

3. Copy the build system:
   ```powershell
   cp build.ps1 <your-module>/
   cp build.yaml <your-module>/
   cp RequiredModules.psd1 <your-module>/
   cp Resolve-Dependency.ps1 <your-module>/
   cp Resolve-Dependency.psd1 <your-module>/
   ```

4. Update your module's paths and names in the copied files
5. Follow the [Initial Setup](#initial-setup) steps above

## Additional Resources

- [PowerShell Gallery](https://www.powershellgallery.com)
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Sampler](https://github.com/gaelcolas/Sampler)
- [ModuleBuilder](https://github.com/PoshCode/ModuleBuilder)
- [Pester](https://pester.dev)
- [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer)

## Quick Reference

### Common Commands

```powershell
# Local validation
./Tests/test-local.ps1

# Build only
./build.ps1 -Tasks build

# Test only
./build.ps1 -Tasks test

# Analyze only
./build.ps1 -Tasks test

# Create tag
git tag -a v1.0.0 -m "Message"

# Push tag
git push origin v1.0.0

# Delete tag (if mistake)
git tag -d v1.0.0
git push origin :refs/tags/v1.0.0
```

### Tag Format

- Stable: `v1.0.0`, `v2.1.3`
- Prerelease: `v1.0.0-beta1`, `v1.0.0-rc2`, `v2.0.0-alpha1`

### Files to Update for New Release

1. `source/ModuleName.psd1` — set `ModuleVersion` to match your planned tag (e.g., `1.2.0` for tag `v1.2.0`)
2. `CHANGELOG.md` — add a `## [1.2.0] - YYYY-MM-DD` section
3. Create and push git tag — **must match manifest version** or the workflow will fail
