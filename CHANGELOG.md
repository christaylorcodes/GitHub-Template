# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-02-01

### Added

#### Build System

- Sampler/ModuleBuilder build pipeline (`build.ps1`, `build.yaml`, `RequiredModules.psd1`)
- Multi-strategy dependency resolver (`Resolve-Dependency.ps1`)
- Local pre-push validation script (`Tests/test-local.ps1`)

#### Module Structure

- PowerShell module manifest and loader (`source/ModuleName.psd1`, `source/ModuleName.psm1`)
- Auto-discovery module loader (Classes, Private, Public)
- Example public function (`source/Public/Get-ModuleInfo.ps1`)

#### Templates

- Public function template (`Templates/Function.ps1`)
- Private function template (`Templates/PrivateFunction.ps1`)
- PowerShell class template (`Templates/Class.ps1`)
- Pester test template (`Templates/Test.Tests.ps1`)

#### Automation Scripts

- [New-Function.ps1](Scripts/New-Function.ps1) function scaffolding tool
- [Test-Template.ps1](Scripts/Test-Template.ps1) template integrity validation
- [New-TemplateBadges.ps1](Scripts/New-TemplateBadges.ps1) shields.io badge generator
- [Initialize-Labels.ps1](Scripts/Initialize-Labels.ps1) AI workflow label creation via `gh` CLI

#### Tests

- Pester 5.6+ test structure (`Tests/Unit/`, `Tests/Integration/`, `Tests/TestHelpers/`)
- Example unit test (`Tests/Unit/Public/Get-ModuleInfo.Tests.ps1`)

#### CI/CD Workflows

- Unified CI/CD pipeline (`.github/workflows/ci.yml`) — Build → Test (matrix) → Analyze → Publish
- PR validation workflow (`.github/workflows/pr-validation.yml`) — CHANGELOG and version checks

#### AI Integration

- [AGENTS.md](AGENTS.md) universal AI agent instructions (Claude Code, GitHub Copilot, Cursor, Codex)
- [GitHub Copilot instructions](.github/copilot-instructions.md) for Copilot-specific context
- [AI task issue template](.github/ISSUE_TEMPLATE/ai_task.md) for structured AI-assignable work items
- AI Contributors section in [CONTRIBUTING.md](.github/CONTRIBUTING.md) with label definitions and quality standards
- AI contribution checkbox in [PR template](.github/PULL_REQUEST_TEMPLATE.md)
- Fresh `.claude/plan.md` skeleton generation for derived repos during initialization

#### Documentation

- [CODE_OF_CONDUCT.md](.github/CODE_OF_CONDUCT.md) (Contributor Covenant v2.1)
- [SECURITY.md](.github/SECURITY.md) security policy
- [docs/USAGE.md](docs/USAGE.md) module usage guide
- [docs/PUBLISHING.md](docs/PUBLISHING.md) PSGallery publishing guide
- [docs/TEMPLATE_USAGE.md](docs/TEMPLATE_USAGE.md) template setup guide
- `docs/en-US/about_ModuleName.help.txt` PowerShell help topic
- `docs/examples/Example-BasicUsage.ps1`

#### Configuration

- `.editorconfig` multi-language formatting rules
- `.gitattributes` line endings, diff drivers, linguist hints
- `.PSScriptAnalyzerSettings.psd1` with 75+ rules and PS 7.0-7.5 compatibility
- `.vscode/settings.json` and `.vscode/extensions.json`

### Changed

- Migrated build system to Sampler/ModuleBuilder (replaced custom InvokeBuild scripts)
- Renamed module source directory from `src/` to `source/` (Sampler convention)
- Standardized on PowerShell 7+ only (removed Desktop/5.1 compatibility)
- Removed PSFramework as default dependency (use Write-Verbose/Write-Debug instead)
- Trimmed .gitignore to PowerShell-focused patterns
- Replaced PSFramework logging in Templates/ with native PowerShell cmdlets

### Removed

- Custom InvokeBuild build scripts (`Build/build.ps1`, `Build/ModuleName.build.ps1`, `Build/PSDepend.psd1`)
- Individual CI workflows (test.yml, analyze.yml, publish.yml) — replaced by unified `ci.yml`
- Duplicate PSScriptAnalyzerSettings.psd1 (keeping .PSScriptAnalyzerSettings.psd1)
- Redundant documentation (WHATS_NEW.md, SETUP_CHECKLIST.md, TEMPLATE_IMPROVEMENTS.md, MAP.md, gantt.mmd)

### Fixed

- Fixed test-local.ps1 to use Sampler/ModuleBuilder build system
- Fixed `src/` path references to `source/` across all documentation
- Updated Pester dependency from 5.3.1 to 5.6.1
- Added PowerShell 7.5 to PSScriptAnalyzer compatibility targets

---

## [1.0.0] - 2025-11-04

### Added
- Comprehensive [CLAUDE.md](CLAUDE.md) documentation for AI and human developers
- [Initialize-Repository.ps1](Scripts/Initialize-Repository.ps1) automation script for quick repository setup
- GitHub issue templates:
  - Bug report template
  - Feature request template
  - Question template
  - Issue template configuration
- GitHub pull request template with comprehensive checklist
- Improved README.md with:
  - Generic placeholder badges with clear customization instructions
  - Multi-language installation examples (PowerShell, Python, Node.js, Ruby)
  - License badge
- Expanded .gitignore with comprehensive patterns for multiple languages and environments
- CHANGELOG.md following Keep a Changelog format
- Community engagement templates:
  - [CONTRIBUTING.md](.github/CONTRIBUTING.md) with detailed contribution guidelines
  - [DONATE.md](docs/DONATE.md) with multiple payment options
- Media assets (`docs/media/`) with:
  - Logo placeholder
  - Demo GIF placeholder
  - Cryptocurrency donation QR codes and addresses

### Changed
- Updated badge URLs from project-specific to generic placeholders
- Enhanced installation section with multiple package manager examples
- Improved documentation structure and clarity

### Fixed
- Removed outdated ConnectWiseManageAPI references from badges
- Corrected placeholder values in README.md

---

## How to Use This Changelog

### Version Format
- **MAJOR.MINOR.PATCH** (e.g., 1.0.0)
  - **MAJOR**: Incompatible API changes
  - **MINOR**: Added functionality in a backward compatible manner
  - **PATCH**: Backward compatible bug fixes

### Categories
- **Added**: New features
- **Changed**: Changes in existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Removed features
- **Fixed**: Bug fixes
- **Security**: Security improvements and vulnerability fixes

### Example Entry
```markdown
## [1.2.0] - 2025-02-15

### Added
- New user authentication system
- Support for OAuth2 providers
- Email verification feature

### Changed
- Updated database schema to support new auth system
- Improved error messages for better debugging

### Fixed
- Fixed memory leak in session management
- Resolved race condition in async operations

### Security
- Patched XSS vulnerability in user input handling
- Updated dependencies to address CVE-2025-1234
```

### Tips
1. **Keep unreleased changes**: Maintain an [Unreleased] section at the top for ongoing development
2. **Add dates**: Always include release dates in YYYY-MM-DD format
3. **Link issues**: Reference GitHub issues with `#123` or full URLs
4. **Group by type**: Organize changes by category (Added, Changed, Fixed, etc.)
5. **Be descriptive**: Write clear, concise descriptions that users can understand
6. **Highlight breaking changes**: Clearly mark breaking changes in the Changed section
7. **Security first**: Always document security fixes (consider using private disclosure first)

### Useful Links
- [Keep a Changelog](https://keepachangelog.com/)
- [Semantic Versioning](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)

---

## Template Version History

This changelog template is versioned separately from your project.

### Template v1.0.0 - 2025-11-04
- Initial changelog template with comprehensive structure
- Added usage instructions and examples
- Included Keep a Changelog and Semantic Versioning references

---

**Note**: Remember to update this file with every release! Keeping a good changelog helps users understand what has changed and makes it easier for them to decide whether to update.

[1.1.0]: https://github.com/christaylorcodes/GitHub-Template/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/christaylorcodes/GitHub-Template/releases/tag/v1.0.0
