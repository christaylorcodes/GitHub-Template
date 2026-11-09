# GitHub Template - Complete Usage Guide

This guide will walk you through using this template to create a professional, well-documented GitHub repository in **less than 10 minutes**.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start (Automated)](#quick-start-automated)
- [Manual Setup](#manual-setup)
- [Customization Checklist](#customization-checklist)
- [Advanced Configuration](#advanced-configuration)
- [Validation](#validation)
- [Common Issues](#common-issues)
- [Tips and Best Practices](#tips-and-best-practices)

---

## Prerequisites

Before you begin, ensure you have:

- [x] **Git installed** (version 2.0 or higher)
- [x] **PowerShell 7.6 or higher** (build, tests and helper scripts)
- [x] **GitHub account**
- [x] **Text editor** (VS Code, Sublime, Notepad++, etc.)
- [x] (Optional) **GitHub CLI (`gh`)** for repository creation

> **PowerShell version:** the template targets PowerShell 7.6. To support hosts still on
> 7.4, lower `PowerShellVersion` in `source/<Module>.psd1` to `'7.4'`.

### Checking Prerequisites

```powershell
# Check Git
git --version

# Check PowerShell
$PSVersionTable.PSVersion

# Check GitHub CLI (optional)
gh --version
```

---

## Quick Start (Automated)

The **fastest way** to use this template is with the automation script.

### Method 1: Using GitHub's "Use this template" Button

1. **Click "Use this template"** on GitHub
   - Navigate to: https://github.com/christaylorcodes/GitHub-Template
   - Click the green "Use this template" button
   - Choose "Create a new repository"

2. **Configure your repository**
   - Owner: Your username or organization
   - Repository name: `your-project-name`
   - Description: Brief description of your project
   - Visibility: Public or Private
   - Click "Create repository from template"

3. **Clone your new repository**
   ```bash
   git clone https://github.com/YOUR-USERNAME/your-project-name.git
   cd your-project-name
   ```

4. **Run the initialization script**
   ```powershell
   .\Scripts\Initialize-Repository.ps1 -Name "My Awesome Project" `
                                -Description "A brief description of what this does" `
                                -Author "Your Name" `
                                -GitHubUsername "YOUR-USERNAME" `
                                -InitializeGit
   ```

5. **That's it!** Your repository is ready to use.

### Method 2: Clone and Initialize

```powershell
# 1. Clone the template
git clone https://github.com/christaylorcodes/GitHub-Template.git MyNewProject
cd MyNewProject

# 2. Remove the template's git history
Remove-Item -Path .git -Recurse -Force

# 3. Run initialization script
.\Scripts\Initialize-Repository.ps1 -Name "My Project" `
                            -Description "Project description" `
                            -Author "Your Name" `
                            -GitHubUsername "YOUR-USERNAME" `
                            -InitializeGit

# 4. Create repository on GitHub (using GitHub CLI)
gh repo create MyNewProject --public --source=. --remote=origin --push
```

---

## Manual Setup

**Recommended:** use `Scripts/Initialize-Repository.ps1` (see [Quick Start](#quick-start-automated)).
It performs every step below, including the module renames, GUID and workflow edits that
are easy to miss by hand. Run it with `-WhatIf` first to preview. The manual steps are
listed here so you know exactly what it changes.

### Step 1: Get the Template

**Option A: Download ZIP**
1. Go to https://github.com/christaylorcodes/GitHub-Template
2. Click "Code" → "Download ZIP"
3. Extract to your desired location
4. Rename folder to your project name

**Option B: Clone**
```bash
git clone https://github.com/christaylorcodes/GitHub-Template.git YourProjectName
cd YourProjectName
rm -rf .git  # Remove template's git history
```

### Step 2: Update README.md

Open `README.md` and replace:

```markdown
# Find and replace these:
GitHub-Template          → YourProjectName
christaylorcodes         → your-username
A brief description      → Your project description
YourModuleName           → your-package-name (if applicable)
```

**Key sections to update:**
- Line 5: Project name
- Line 11: Description
- Lines 17-20: Badge URLs
- Lines 42-50: Installation instructions
- Line 39: Add your demo GIF/screenshot

### Step 3: Update CONTRIBUTING.md

```markdown
# Find and replace:
christaylorcodes → your-username
GitHub-Template  → YourProjectName
```

- Review Slack community links (remove or update as needed)
- Adjust style guides for your project type
- Update email/contact information

### Step 4: Update docs/DONATE.md

- Update PayPal link (line 10): `paypal.me/YourPayPalName`
- Generate new BTC QR code or remove if not using
- Generate new ETH QR code or remove if not using
- Update wallet addresses in `docs/media/BTC.txt` and `docs/media/ETH.txt`

### Step 5: Update LICENSE

```markdown
# Update line 3:
Copyright (c) 2025 Your Name
```

Choose a different license if MIT doesn't fit your needs:
- MIT: Permissive, allows commercial use
- Apache 2.0: Patent grant protection
- GPL-3.0: Requires derivative works to be open source

### Step 6: Update SECURITY.md

- Replace `security@[your-domain].com` with your email
- Update contact methods
- Adjust supported versions table
- Review security best practices for your project type

### Step 7: Update CODE_OF_CONDUCT.md

- Replace `conduct@[your-domain].com` with your email
- Update enforcement contacts
- Adjust community values if needed

### Step 8: Replace Media Files

```
docs/media/
├── Logo.png    → Your project logo (recommended: 300px height)
├── Demo.gif    → Your demo/screenshot
├── BTC.png     → Your Bitcoin QR code (or delete)
├── BTC.txt     → Your Bitcoin address (or delete)
├── ETH.png     → Your Ethereum QR code (or delete)
└── ETH.txt     → Your Ethereum address (or delete)
```

**Logo tips:**
- PNG format with transparency
- 300px height (width proportional)
- Clear and recognizable at small sizes

**Demo tips:**
- GIF or PNG screenshot
- Show key features
- Keep file size under 2MB
- Use tools like ScreenToGif, LICEcap, or Kap

### Step 9: Update Module Source, Tests, Workflows and Build Config

Replace `<Module>` with your module name:

1. Rename the module files and replace `ModuleName` inside them:
   - `source/ModuleName.psd1` → `source/<Module>.psd1`
   - `source/ModuleName.psm1` → `source/<Module>.psm1`
   - `source/en-US/about_ModuleName.help.txt` → `source/en-US/about_<Module>.help.txt`
   - `Tests/Unit/Module/ModuleName.Module.Tests.ps1` → `Tests/Unit/Module/<Module>.Module.Tests.ps1`
2. Replace `ModuleName` in `source/Public/Get-ModuleInfo.ps1`, its test in
   `Tests/Unit/Public/`, `Templates/*.ps1`, `AGENTS.md`, `docs/USAGE.md`,
   `docs/PUBLISHING.md` and `docs/examples/`.
3. In the manifest, set a new `GUID` (`[guid]::NewGuid()`), plus `Author`,
   `CompanyName`, `Description` and `Copyright`.
4. In `.github/workflows/ci.yml` and `.github/workflows/pr-validation.yml`, set
   `MODULE_NAME: <Module>`.
5. In `build.yaml`, set `GitHubConfigUserName` and `GitHubConfigUserEmail`.
6. Reset `CHANGELOG.md` to an empty `## [Unreleased]` section.
7. Delete the template-only files: root `DONATE.md` and `Media/` (mirrors),
   `Scripts/Test-Template.ps1`, `Scripts/New-TemplateBadges.ps1`,
   `Scripts/Initialize-Roadmap.ps1`, `docs/TEMPLATE_USAGE.md`,
   `docs/TEMPLATE_DEVELOPMENT.md` and `Tests/Template/`.

### Step 10: Initialize Git

```bash
git init
git add .
git commit -m "Initial commit from GitHub-Template"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/YOUR-REPO.git
git push -u origin main
```

---

## Customization Checklist

Use this checklist to ensure you've customized everything:

### Files to Update

- [ ] **README.md**
  - [ ] Replace project name
  - [ ] Update description
  - [ ] Update badge URLs
  - [ ] Add installation instructions
  - [ ] Replace demo GIF
  - [ ] Update all links

- [ ] **CONTRIBUTING.md**
  - [ ] Update repository links
  - [ ] Adjust style guides
  - [ ] Update community links
  - [ ] Review emoji conventions

- [ ] **DONATE.md**
  - [ ] Update PayPal link
  - [ ] Update/remove crypto addresses
  - [ ] Replace QR codes

- [ ] **LICENSE**
  - [ ] Update copyright year
  - [ ] Update copyright holder

- [ ] **SECURITY.md**
  - [ ] Update contact email
  - [ ] Adjust supported versions
  - [ ] Review security guidelines

- [ ] **CODE_OF_CONDUCT.md**
  - [ ] Update contact email
  - [ ] Review enforcement process

- [ ] **CHANGELOG.md**
  - [ ] Update project name
  - [ ] Add v0.1.0 entry for your project

- [ ] **CLAUDE.md** (Optional)
  - [ ] Update for your project
  - [ ] Or delete if not using Claude

### Files to Replace

- [ ] **docs/media/Logo.png** - Your project logo
- [ ] **docs/media/Demo.gif** - Your demo/screenshot
- [ ] **docs/media/BTC.png** - Your Bitcoin QR (or delete)
- [ ] **docs/media/ETH.png** - Your Ethereum QR (or delete)

### Files to Review

- [ ] **.gitignore** - Add project-specific patterns
- [ ] **.editorconfig** - Adjust formatting preferences
- [ ] **.gitattributes** - Review line ending configuration

### GitHub Settings

- [ ] **Enable GitHub Pages** (if needed)
- [ ] **Configure branch protection** (for main branch)
- [ ] **Enable GitHub Discussions** (optional)
- [ ] **Add repository topics** (tags for discoverability)
- [ ] **Set repository description**
- [ ] **Add repository URL** (if applicable)

---

## Advanced Configuration

### Generating Badges

Use the included badge generator script:

```powershell
.\Scripts\New-TemplateBadges.ps1 -GitHubUsername "YOUR-USERNAME" `
                         -RepositoryName "your-repo" `
                         -License "MIT" `
                         -PackageManager "PSGallery" `
                         -PackageName "YourModuleName" `
                         -UpdateReadme
```

This generates shields.io badges for:
- License
- Build status
- Package version
- Code coverage
- Donations

### GitHub Actions

CI is already included; you do not need to create a workflow:

- `.github/workflows/ci.yml` builds, tests (Ubuntu + Windows), analyzes, and on a
  `vX.Y.Z` / `vX.Y.Z-label` tag publishes to PowerShell Gallery
- `.github/workflows/pr-validation.yml` checks CHANGELOG updates on pull requests

To publish, create the `production` and `prerelease` environments with a
`PSGALLERY_API_KEY` environment secret. See [PUBLISHING.md](PUBLISHING.md).

### Dependabot

`.github/dependabot.yml` is already included. Actions in the workflows are pinned to
commit SHAs, and Dependabot opens one grouped pull request per week when GitHub Actions
updates are available. Review and merge them like any other PR.

### Adding Issue Templates

The template includes issue templates in `.github/ISSUE_TEMPLATE/`:
- `bug_report.md` - For bug reports
- `feature_request.md` - For feature requests
- `ai_task.md` - Structured tasks for AI agents
- `config.yml` - Configuration

Customize these for your project's needs.

### Generating QR Codes

For donation addresses:

**Online tools:**
- https://www.qr-code-generator.com/
- https://www.the-qrcode-generator.com/

**PowerShell (requires qrcode module):**
```powershell
Install-PSResource -Name QRCodeGenerator
New-QRCode -Content "bc1q..." -OutPath "./docs/media/BTC.png"
```

---

## Validation

### Validating Your Project After Initialization

`Scripts/Test-Template.ps1` validates the template itself and is deleted by
`Initialize-Repository.ps1`, so it is not available in your project. Instead:

```powershell
# Build, analyze and test the renamed module
./build.ps1 -ResolveDependency -Tasks noop
./Tests/test-local.ps1

# Look for leftover placeholders (excludes legitimate -ModuleName / $ModuleName)
git grep -nE '(^|[^-$:A-Za-z0-9])ModuleName([^A-Za-z0-9]|$)'
git grep -n "YOUR-USERNAME"
git grep -n "GitHub-Template"
```

All three test-local stages (build, analyze, test) must pass before pushing.

### Manual Validation Checklist

- [ ] All links work (click them!)
- [ ] Images display correctly
- [ ] No "TODO" or "FIXME" comments remain
- [ ] No placeholder text (YOUR-USERNAME, etc.)
- [ ] License is correct for your project
- [ ] Contact information is updated
- [ ] Demo GIF/screenshot shows your project

---

## Common Issues

### Issue: PowerShell Execution Policy Error

```
.\Initialize-Repository.ps1 : File cannot be loaded because running scripts is disabled
```

**Solution:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Issue: Git Not Found

```
git : The term 'git' is not recognized
```

**Solution:**
- Install Git from https://git-scm.com/
- Restart your terminal
- Verify: `git --version`

### Issue: Broken Images in README

```
Images show as broken links on GitHub
```

**Solution:**
- Ensure images are in `docs/media/` directory
- Use relative paths: `./docs/media/Logo.png`
- Commit and push images to repository
- Check file names match exactly (case-sensitive)

### Issue: Badges Not Displaying

```
Badge URLs show broken image icons
```

**Solution:**
- Verify repository is public (or badges support private repos)
- Check URLs are correct (username, repo name)
- For CI badges, ensure GitHub Actions workflow exists
- For package badges, ensure package is published

### Issue: Template Still Shows Old Project Name

```
References to "GitHub-Template" or "ConnectWiseManageAPI" remain
```

**Solution:**
- Search repository: `git grep "GitHub-Template"`
- Use Find and Replace in your editor
- Check CHANGELOG.md (may reference old projects)

---

## Tips and Best Practices

### Before You Start

1. **Plan your project structure** - Know what files you'll need
2. **Choose your license** - MIT is permissive, GPL requires open source
3. **Prepare assets** - Have logo and demo ready
4. **Set up accounts** - GitHub, CI/CD platform, package registry

### During Setup

1. **Use the automation script** - Saves time and reduces errors
2. **Validate frequently** - Run `./Tests/test-local.ps1` after changes
3. **Test locally** - Preview README in your editor
4. **Commit incrementally** - Don't make all changes at once

### After Setup

1. **Add a demo** - Show don't tell (GIF, video, or screenshots)
2. **Write clear installation** - Test instructions on fresh machine
3. **Configure publishing** - Create the `production`/`prerelease` environments and API key secret
4. **Merge Dependabot PRs** - Weekly grouped GitHub Actions updates
5. **Engage community** - Respond to issues and PRs

### Writing Good Documentation

1. **README should answer:**
   - What does this do?
   - Why should I use it?
   - How do I install it?
   - How do I use it?
   - Where can I get help?

2. **Use examples** - Code snippets speak louder than words

3. **Keep it updated** - Review docs with each release

4. **Add badges** - Show build status, coverage, version

5. **Link to docs** - If you have extensive docs, link to them

### Project Maintenance

1. **Regular updates:**
   - Update dependencies monthly
   - Review security advisories weekly
   - Update screenshots when UI changes

2. **Community engagement:**
   - Respond to issues within 48 hours
   - Review PRs within 1 week
   - Thank contributors

3. **Versioning:**
   - Follow [Semantic Versioning](https://semver.org/)
   - Update CHANGELOG.md with each release
   - Tag releases in Git

---

## Time Estimates

| Task | Automated | Manual |
|------|-----------|--------|
| Template download | 1 min | 1 min |
| Initialization | 2 min | 15 min |
| Customization | 2 min | 20 min |
| Asset creation | Varies | Varies |
| Validation | 1 min | 5 min |
| Git setup | 1 min | 3 min |
| **Total (no assets)** | **~7 min** | **~44 min** |

**Asset creation time:**
- Logo: 10-60 minutes (design) or 5 min (use existing)
- Demo GIF: 5-15 minutes
- QR codes: 2 minutes

---

## Next Steps

After setting up your repository:

1. **Write your code!** - The template is ready, now build your project

2. **Configure publishing** - CI is included; add the environments and API key secret ([PUBLISHING.md](PUBLISHING.md))

3. **Publish your module** - Push a `vX.Y.Z` tag to release to PowerShell Gallery

4. **Share your project** - Social media, Reddit, Hacker News

5. **Maintain actively** - Respond to issues, review PRs, update docs

---

## Getting Help

If you need help with this template:

1. **Check the documentation:**
   - [README.md](../README.md) - Quick overview
   - [AGENTS.md](../AGENTS.md) - Comprehensive guide
   - This file - Step-by-step instructions

2. **Run validation:**
   ```powershell
   ./Tests/test-local.ps1
   ```

3. **Search for issues:**
   - Check [GitHub Issues](https://github.com/christaylorcodes/GitHub-Template/issues)
   - Look for similar problems

4. **Ask for help:**
   - Open a [new issue](https://github.com/christaylorcodes/GitHub-Template/issues/new/choose)
   - Use the "Question" template
   - Join community Slack channels

5. **Contribute improvements:**
   - Found a bug? Open an issue
   - Have a suggestion? Submit a PR
   - Improved documentation? We'd love to see it!

---

## Additional Resources

- [GitHub Documentation](https://docs.github.com/)
- [Markdown Guide](https://www.markdownguide.org/)
- [Semantic Versioning](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [Contributor Covenant](https://www.contributor-covenant.org/)
- [Choose a License](https://choosealicense.com/)
- [Shields.io](https://shields.io/) - Badge generator
- [EditorConfig](https://editorconfig.org/)

---

**Last Updated:** 2025-11-04
**Template Version:** 1.0
**Questions?** Open an [issue](https://github.com/christaylorcodes/GitHub-Template/issues)

Happy coding! 🚀
