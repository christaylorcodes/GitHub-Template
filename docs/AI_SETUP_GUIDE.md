# Project Customization Guide

> **Audience:** AI coding agents (Claude Code, GitHub Copilot, Cursor, Codex, Windsurf, and others).
> For Claude Code users, run `/customize` for an interactive walkthrough.

This document guides AI agents through customizing a repository that was created from the GitHub Template. Follow these instructions when a user asks you to help set up or personalize their project.

---

## 1. Run the Initialization Script (if not already done)

If `Scripts/Initialize-Repository.ps1` still exists, the template has not been initialized yet.

### Gather Information

Ask the user for ALL of the following before running the script.

| # | Input | Required | Default | Used For |
|---|-------|----------|---------|----------|
| 1 | **Module name** (PascalCase, e.g., `MyAwesomeModule`) | Yes | -- | File names, manifest, all code references |
| 2 | **Module description** (one sentence) | Yes | -- | Manifest Description, README summary |
| 3 | **Author name** (e.g., `Jane Smith`) | Yes | -- | Manifest Author, LICENSE, function headers |
| 4 | **GitHub username** (e.g., `janesmith`) | Yes | -- | All GitHub URLs, badge URLs |
| 5 | **Company name** | No | Author name | Manifest CompanyName |
| 6 | **Repository name** | No | Module name | GitHub URLs (when repo name differs) |
| 7 | **Remove donation content?** | No | Yes (remove) | Whether to keep PayPal/crypto donation pages |
| 8 | **Re-initialize git?** | No | No | Only needed if using clone method |

### Run the Script

```powershell
.\Scripts\Initialize-Repository.ps1 `
    -Name "ProjectName" `
    -Description "Brief description of the module" `
    -Author "Author Name" `
    -GitHubUsername "githubuser" `
    -ModuleName "ModuleName" `
    -CompanyName "Company Name" `
    -RepositoryName "repo-name" `
    -SkipDonation `
    -InitializeGit
```

Use `-WhatIf` first to preview all changes without applying them.

---

## 2. Customize Project Content

After the script runs, these items need human or agent attention.

### README.md

The script replaces placeholder URLs and the title, but the prose still describes the template. Rewrite these sections for the actual project:

- **H4 subtitle** -- replace the template tagline with a one-liner about this project
- **Introduction paragraph** -- rewrite the "This template gives you everything..." paragraph
- **What's Included table** -- replace with features of this module
- **Getting Started** -- rewrite to show how to install and use this module
- **AI Agents section** -- remove or simplify (template-specific marketing)

### CONTRIBUTING.md

- Review Slack channel links -- replace or remove if not applicable
- Update the title if it still references the template

### Contact Emails

The script sets `yourdomain.com` as a placeholder. Update with real addresses:

- `SECURITY.md` -- security contact email
- `CODE_OF_CONDUCT.md` -- conduct contact email

### Badges

Update README.md badge URLs once CI/CD is configured:

- Build status badge -- point to your GitHub Actions workflow
- Code quality badge -- point to your Codacy/SonarCloud project
- Version badge -- update once published to PSGallery
- Remove the Aikido security badge if not using that service

### CHANGELOG.md

Replace the template version history with a meaningful first entry for this project.

---

## 3. Adapt Existing Code (Optional)

If the user has an existing PowerShell module they want to bring into this structure:

### Copy Source Files

1. Copy existing public functions into `source/Public/` (one function per file)
2. Copy existing private/helper functions into `source/Private/`
3. Copy existing classes into `source/Classes/`

### Create Tests

For each function copied in, create a matching test file:

- `Tests/Unit/Public/Verb-Noun.Tests.ps1` for public functions
- `Tests/Unit/Private/Verb-Noun.Tests.ps1` for private functions
- Use `Templates/Test.Tests.ps1` and `Templates/PrivateTest.Tests.ps1` as starting points

### Update the Manifest

Edit `source/<ModuleName>.psd1`:

- Add any required modules to `RequiredModules`
- Update `Tags` for PSGallery discovery
- Update `ReleaseNotes` for the current version
- Set `FunctionsToExport` if you want an explicit list instead of wildcard

### Wire Up Dependencies

If the existing module depends on other modules:

1. Add them to `RequiredModules` in the manifest
2. Add them to `RequiredModules.psd1` for build-time installation
3. Add `#Requires -Modules ModuleName` to functions that need them

---

## 4. Validate

### Check for Remaining Placeholders

```powershell
# These should all return no results after setup
git grep -i "ModuleName"
git grep "YOUR-USERNAME"
git grep "YOUR-REPO"
git grep "YOUR-PROJECT"
git grep "YOUR-PACKAGE"
git grep "yourusername"
git grep "Your Name"
git grep "Your Company"
git grep "christaylorcodes"
git grep "christaylor\.codes"
```

### Verify Module Functionality

```powershell
Import-Module "./source/<ModuleName>.psd1" -Force
Get-ModuleInfo
Remove-Module "<ModuleName>" -Force
```

### Run Full Build and Test Pipeline

```powershell
# Bootstrap build dependencies (first time)
./build.ps1 -ResolveDependency -Tasks build

# Run full pipeline (Clean -> Analyze -> Test -> Build)
./Tests/test-local.ps1
```

All three checks (build, PSScriptAnalyzer, Pester tests) must pass.

---

## 5. Remaining Manual Steps

After all customization is complete, remind the user about:

1. Replace `docs/media/Logo.png` with their project logo
2. Replace `docs/media/Demo.gif` with a project demo or screenshot
3. Set up the `PSGALLERY_API_KEY` repository secret for publishing
4. Run `Scripts/Initialize-Labels.ps1` to create AI workflow labels (optional)
5. Configure GitHub repository settings (branch protection, topics, discussions)

---

## Placeholder Reference

| Placeholder | Replace With | Notes |
|-------------|-------------|-------|
| `ModuleName` | Module name | Also used in file names |
| `YOUR-USERNAME` | GitHub username | Uppercase with hyphens |
| `YOUR-REPO` | Repository name | Uppercase with hyphens |
| `YOUR-PROJECT` | Project display name | README only |
| `YOUR-PACKAGE` | Module/package name | README only |
| `Your Name` | Author full name | Mixed case |
| `Your Company` | Company/vendor name | Mixed case |
| `yourusername` | GitHub username | Lowercase, in URLs |
| `christaylorcodes/GitHub-Template` | `username/repo` | Full path replacement |
| `christaylor.codes` | Your email domain | SECURITY.md and CODE_OF_CONDUCT.md |
