# Template Development

> **Note:** This documentation is only relevant in the template repository itself. It is removed when a new project is initialized from this template.

## Template Scripts

- `Scripts/Initialize-Repository.ps1` — Replaces all template placeholders with project-specific values, renames module files, populates the manifest (new GUID), resets CHANGELOG, removes template-only files, optionally initializes git. It does not create backups; use `-WhatIf` to preview
- `Scripts/Initialize-Labels.ps1` — Creates recommended GitHub labels for AI workflow via `gh` CLI (kept in initialized projects)

Template-only scripts (removed by `Initialize-Repository.ps1`):

- `Scripts/Test-Template.ps1` — Validates template integrity (required files, links, placeholders, structure)
- `Scripts/New-TemplateBadges.ps1` — Generates shields.io badges for various package managers and CI systems
- `Scripts/Initialize-Roadmap.ps1` — Seeds the template repository's roadmap issues/milestones

## New Repository Setup (AI Agents)

If a user has created a new repository from this template and asks you to set it up, follow the [AI Setup Guide](AI_SETUP_GUIDE.md). That guide contains:

1. Questions to gather from the user before starting
2. Two setup methods (automated script vs. manual step-by-step)
3. Complete placeholder-to-file mapping
4. Validation steps

Do NOT start modifying files until you have gathered all required inputs from the user.

## Template Commands

```powershell
# Validate the template
./Scripts/Test-Template.ps1
./Scripts/Test-Template.ps1 -SkipLinkCheck

# Initialize a new project from this template
./Scripts/Initialize-Repository.ps1 -Name "MyProject" -Description "..." -Author "..." -GitHubUsername "user"

# Generate badges
./Scripts/New-TemplateBadges.ps1 -GitHubUsername "user" -RepositoryName "MyProject" -PackageManager PSGallery -PackageName "MyProject"

# Create AI workflow labels on a GitHub repo
./Scripts/Initialize-Labels.ps1
./Scripts/Initialize-Labels.ps1 -DryRun
```

## Template Placeholders

The following placeholders are replaced by `Initialize-Repository.ps1`:

- `ModuleName` — replaced with the project/module name
- `YOUR-USERNAME` — replaced with the GitHub username
- `YOUR-REPO` — replaced with the repository name
- `YOUR-PROJECT` — replaced with the project name
- `YOUR-PACKAGE` — replaced with the module name
- `christaylorcodes/GitHub-Template` — replaced with `username/reponame`
