# AGENTS.md

This file provides context for AI coding agents (Claude Code, GitHub Copilot, Cursor, Windsurf, Codex, and others) working in this repository.

## Project Overview

**ModuleName** is a PowerShell module hosted at <https://github.com/YOUR-USERNAME/YOUR-REPO>.

- **Language**: PowerShell 7.2+
- **Build System**: Sampler / ModuleBuilder
- **Test Framework**: Pester 5.6+
- **Linter**: PSScriptAnalyzer
- **License**: MIT

## Quick Start

```powershell
# Bootstrap dependencies (required first time)
./build.ps1 -ResolveDependency -Tasks noop

# Run full pipeline (Clean -> Build -> Test)
./build.ps1

# Local pre-push validation (build + analyze + test)
./Tests/test-local.ps1
```

## Build Commands

All commands require **PowerShell 7.2+** and use Sampler/ModuleBuilder with InvokeBuild as the task runner. Configuration lives in `build.yaml` and `RequiredModules.psd1`.

```powershell
# Individual tasks
./build.ps1 -Tasks test             # Run Pester tests (builds first)
./build.ps1 -Tasks build            # Build module to output/
./build.ps1 -Tasks publish          # Publish to PowerShell Gallery

# Bootstrap + build (first time or after dependency changes)
./build.ps1 -ResolveDependency -Tasks build

# Local validation (build + analyze + test)
./Tests/test-local.ps1
./Tests/test-local.ps1 -SkipBuild       # Skip build step
./Tests/test-local.ps1 -SkipTests       # Skip Pester tests
./Tests/test-local.ps1 -SkipAnalyze     # Skip PSScriptAnalyzer
```

## Architecture

### Directory Layout

```
YOUR-REPO/
  build.ps1                  # Sampler bootstrap and task runner (vendor)
  build.yaml                 # Build pipeline configuration
  RequiredModules.psd1       # Build dependency specifications
  Resolve-Dependency.ps1     # Dependency resolver (vendor)
  Resolve-Dependency.psd1    # Resolver configuration
  source/
    ModuleName.psd1          # Module manifest
    ModuleName.psm1          # Root module (auto-loads subdirectories)
    Classes/                 # PowerShell class definitions (loaded first)
    Private/                 # Internal helper functions (not exported)
    Public/                  # Exported functions (one file per function)
  Tests/
    Unit/Public/             # Tests for exported functions
    Unit/Private/            # Tests for internal functions
    Integration/             # Integration tests
    TestHelpers/             # Shared test utilities
  Templates/                 # Boilerplate for new functions/tests
  Scripts/                   # Automation scripts
  output/                    # Build output (gitignored)
  docs/                      # Documentation and media assets
    media/                   # Logo, demo GIF, donation QR codes
```

### Directory Structure Rationale

The root directory is kept minimal — only files that tools or conventions require at root level:

- **`README.md`, `LICENSE`** — GitHub expects these at root for repository display.
- **`AGENTS.md`, `CLAUDE.md`** — AI agent tools resolve these from root.
- **`.gitignore`, `.editorconfig`, `.gitattributes`** — Standard dotfiles that editors and git look for at root.
- **`.PSScriptAnalyzerSettings.psd1`** — IDE extensions (VS Code PowerShell) auto-detect this at root.

Everything else is organized by purpose:

- **`.github/`** — GitHub-specific files: workflows, issue templates, PR template, and community docs (`CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`). GitHub natively recognizes community health files in this folder.
- **`source/`** — Module source code only. No tests, no build scripts, no docs.
- **`Tests/`** — All test code and the local validation script (`test-local.ps1`). Mirrors `source/` structure with `Unit/Public/`, `Unit/Private/`, and `Integration/`.
- **`docs/`** — All documentation and media assets (`docs/media/`). Keeps images, guides, and help files together rather than scattered across root.
- **`Scripts/`** — Developer automation (scaffolding, initialization, validation). Not part of the module itself.
- **`Templates/`** — Code generation boilerplate. Separate from `Scripts/` because templates are passive data files, not executable automation.

### Module Loading Order

During development, the source `.psm1` auto-discovers and dot-sources files: Classes -> Private -> Public. When built with ModuleBuilder (`./build.ps1 -Tasks build`), all source files are compiled into a single `.psm1` in `output/`. No registration step is needed when adding new files — ModuleBuilder discovers them automatically.

### Organizing Large Modules

For modules with many functions, organize `Public/` into domain subdirectories:

```
source/Public/
  Authentication/
    Connect-MyService.ps1
    Disconnect-MyService.ps1
  Company/
    Get-Company.ps1
    New-Company.ps1
  Service/
    Get-Ticket.ps1
    Update-Ticket.ps1
```

ModuleBuilder discovers files recursively — all `.ps1` files under `Public/` are exported regardless of nesting depth. The same applies to `Private/` and `Classes/`. Recommended when a module exceeds ~20 exported functions.

### Build System

Uses [Sampler](https://github.com/gaelcolas/Sampler) + [ModuleBuilder](https://github.com/PoshCode/ModuleBuilder):

- `build.yaml` — declarative pipeline configuration (tasks, Pester settings, PSScriptAnalyzer settings)
- `RequiredModules.psd1` — build dependency specifications (resolved to `output/RequiredModules/`)
- `build.ps1` — Sampler bootstrap and InvokeBuild wrapper (vendor file)
- `Resolve-Dependency.ps1` — multi-strategy dependency resolver: ModuleFast / PSResourceGet / PSDepend (vendor file)
- Build output goes to `output/ModuleName/<version>/`

### Test Framework

- Pester 5.6+ with configuration in `build.yaml`
- Test results: NUnit format to `output/testResults/testResults.xml`
- Tests can run against the built module in `output/` (via `./build.ps1 -Tasks test`) or against source directly (via `Invoke-QuickTest.ps1`)

### CI/CD

- `ci.yml` — Unified pipeline: Build → Test (Ubuntu + Windows matrix) → Analyze → Publish (tag-gated)
- `pr-validation.yml` — CHANGELOG and version checks on pull requests
- Version is extracted from git tags (`v1.2.3` for stable, `v1.2.3-beta1` for prerelease)
- Publishing requires `PSGALLERY_API_KEY` secret

## Common Patterns

### Exposing Classes to Consumers

PowerShell classes defined inside a module's `.psm1` are **not visible** outside the module scope. If consumers need to use your classes directly (e.g., typed parameters, return types), move them to a standalone `.ps1` file and add it to the manifest:

```powershell
# In ModuleName.psd1
ScriptsToProcess = @('Classes\MyClass.ps1')
```

This runs the script in the caller's session before importing the module, making the class types available. See [about_Classes — Exporting classes](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_classes#exporting-classes-with-type-accelerators).

### Module Cleanup (OnRemove)

Modules that create disposable resources (HTTP clients, database connections, runspace pools, event subscriptions) should register a cleanup handler:

```powershell
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    if ($script:HttpClient) {
        $script:HttpClient.Dispose()
        $script:HttpClient = $null
    }
}
```

This runs when `Remove-Module` is called or the session ends. Add it at the end of your `.psm1` after the export block.

## Code Conventions

For the full style guide covering formatting, naming, error handling, logging, preferred modules, and security requirements, see [docs/PowerShell-StyleGuide.md](docs/PowerShell-StyleGuide.md).

For detailed code review patterns and checklists (not needed every session), see [docs/PowerShell-DeepReview.md](docs/PowerShell-DeepReview.md).

### Quick Reference

Enforced by PSScriptAnalyzer (`.PSScriptAnalyzerSettings.psd1`) and `.editorconfig`:

- 4-space indentation (spaces, not tabs)
- Max line length: 120 characters
- Open braces on same line (`if ($true) {`)
- Single quotes for constants, double quotes only for interpolation
- Approved verbs only (`Get-Verb`)
- Comment-based help required before all exported functions
- Target PowerShell 7.2+ for modules (see [StyleGuide](docs/PowerShell-StyleGuide.md) for endpoint script targets)
- PowerShell files: UTF-8 with BOM, CRLF line endings
- Use `Write-Verbose`/`Write-Debug` in modules, Windows Event Log (default) in standalone scripts

### Git Commit Style

- Present tense, imperative mood ("Add feature" not "Added feature")
- Max 72 characters on first line
- Reference issues with `#123` after the first line
- Optional emoji prefix (`:bug:` for fixes, `:memo:` for docs, `:art:` for formatting)

## Adding New Functions

1. Create the function file at `source/Public/Verb-Noun.ps1` (or `source/Private/` for internal helpers). For larger modules, use domain subdirectories: `source/Public/ServiceArea/Verb-Noun.ps1`
2. Use `Templates/Function.ps1` (Public) or `Templates/PrivateFunction.ps1` (Private) as the starting template
3. Create matching test:
   - Public: `Tests/Unit/Public/Verb-Noun.Tests.ps1` (use `Templates/Test.Tests.ps1`)
   - Private: `Tests/Unit/Private/Verb-Noun.Tests.ps1` (use `Templates/PrivateTest.Tests.ps1`)
4. Or use the scaffolding script: `.\Scripts\New-Function.ps1 -FunctionName Verb-Noun -Type Public`
5. The module auto-discovers new files on import — no manifest or registration changes needed
6. Quick-test: `.\Scripts\Invoke-QuickTest.ps1 -FunctionName Verb-Noun -IncludeAnalyzer`
7. Full validation: `./Tests/test-local.ps1` before committing

## Testing Workflow

Tests are the feedback loop. Without them, agents guess whether code works. With them, agents know. Write tests first or alongside implementation, never as an afterthought. See [docs/PowerShell-StyleGuide.md](docs/PowerShell-StyleGuide.md) for testable design patterns, what good tests look like, and mocking guidance.

### Quick Test (AI Development Loop)

During iterative development, use the quick test runner for fast feedback:

```powershell
# Test a specific function with PSScriptAnalyzer (recommended default)
./Scripts/Invoke-QuickTest.ps1 -FunctionName Get-ModuleInfo -IncludeAnalyzer

# JSON output for programmatic parsing
./Scripts/Invoke-QuickTest.ps1 -FunctionName Get-ModuleInfo -IncludeAnalyzer -OutputFormat Structured

# Run module health tests only
./Scripts/Invoke-QuickTest.ps1 -Module

# Quick mode via test-local.ps1 (skip build, targeted)
./Tests/test-local.ps1 -Quick -FunctionName Get-ModuleInfo
```

### Full Validation (Before Commit/PR)

```powershell
# Full pipeline: build + PSScriptAnalyzer + Pester tests with code coverage
./Tests/test-local.ps1
```

### AI Agent Testing Protocol

**No code is complete without passing tests.** A function without a test is unfinished work. Follow this closed-loop for all implementations:

1. **Write** the function and its test file together (use `.\Scripts\New-Function.ps1` to scaffold both)
2. **Quick-test** with `./Scripts/Invoke-QuickTest.ps1 -FunctionName <Name> -IncludeAnalyzer -OutputFormat Structured`
3. **Parse** the JSON output -- if `success` is `false`, read `failedTests` and `analyzerErrors`
4. **Fix** the issues identified in the structured output
5. **Re-test** (repeat from step 2 until `success` is `true`)
6. **Full validate** with `./Tests/test-local.ps1` before committing

Do not claim work is done until the full validation passes. PSScriptAnalyzer is mandatory -- always use `-IncludeAnalyzer` during the development loop.

### Test Organization

| Location | Purpose | Tags | Template |
|----------|---------|------|----------|
| `Tests/Unit/Module/` | Module import, manifest, exports | `Unit`, `Module` | (included) |
| `Tests/Unit/Public/` | Public function tests | `Unit`, `Public` | `Templates/Test.Tests.ps1` |
| `Tests/Unit/Private/` | Private function tests (InModuleScope) | `Unit`, `Private` | `Templates/PrivateTest.Tests.ps1` |
| `Tests/Integration/` | Cross-function and external tests | `Integration` | `Templates/IntegrationTest.Tests.ps1` |
| `Tests/TestHelpers/` | Shared test utilities (TestHelper.psm1) | N/A | (included) |

### Writing Tests for New Functions

Every new function must have a corresponding test file. The `New-Function.ps1` scaffolding script creates both automatically.

### Writing Tests for Private Functions

Private functions are not exported and must be tested using `InModuleScope`:

```powershell
It 'Should process data correctly' {
    InModuleScope $script:Module.Name {
        $result = ConvertTo-InternalFormat -InputData 'test'
        $result.ProcessedData | Should -Be 'test'
    }
}
```

### PSScriptAnalyzer Requirements

- Zero PSScriptAnalyzer **errors** required for all code
- Warnings are acceptable but should be minimized
- Use `.PSScriptAnalyzerSettings.psd1` for project rules
- Run standalone: `Invoke-ScriptAnalyzer -Path ./source -Recurse -Settings ./.PSScriptAnalyzerSettings.psd1`

## AI Contribution Workflow

This section covers the essential commands. For the full coordination protocol, label state machine, multi-agent coordination, and issue creation guide, see [docs/PROJECT_PLANNING.md](docs/PROJECT_PLANNING.md).

### Finding Work

Query GitHub Issues for available tasks:

```powershell
# Issues structured for AI agents
gh issue list --label ai-ready --state open

# Good starter tasks
gh issue list --label "good-first-issue" --state open

# All open issues in a milestone
gh milestone list
gh issue list --milestone "Milestone Name" --state open
```

### Issue Labels

| Label | Meaning |
| ----- | ------- |
| `ai-task` | Issue is structured with acceptance criteria for AI agents |
| `ai-ready` | Task is available — no one is working on it |
| `ai-in-progress` | An agent has claimed this and is actively working |
| `ai-review` | PR submitted, awaiting human review |
| `ai-blocked` | Agent needs human input to proceed |
| `good-first-issue` | Simple task suitable for any contributor |

### Claiming an Issue

Before starting work, claim the issue so other agents do not duplicate effort:

```powershell
gh issue edit <number> --add-label ai-in-progress --remove-label ai-ready
```

When you open a PR, update the label:

```powershell
gh issue edit <number> --add-label ai-review --remove-label ai-in-progress
```

If you get stuck and cannot continue:

```powershell
gh issue comment <number> --body "Blocked: <description of what is needed>"
gh issue edit <number> --add-label ai-blocked --remove-label ai-in-progress
```

### Working on an Issue

1. Claim the issue (see above)
2. Create a feature branch: `git checkout -b feature/issue-number-short-description`
3. Read the full issue body, requirements, and acceptance criteria
4. Implement function and test file together (scaffold with `.\Scripts\New-Function.ps1`)
5. Quick-test iteratively until passing (`Invoke-QuickTest.ps1 -IncludeAnalyzer -OutputFormat Structured`)
6. Run `./Tests/test-local.ps1` to validate (build + analyze + test must all pass)
7. Commit with a message referencing the issue: `Add feature X (fixes #123)`
8. Push and open a pull request
9. Update the issue label to `ai-review`

### PR Requirements

- All CI checks must pass (test, analyze, build)
- Tests must cover new or changed functionality
- PSScriptAnalyzer must report zero errors
- PR description must reference the issue being addressed

### What AI Agents Should NOT Do

- Do not modify CI workflow files without explicit instruction
- Do not add new dependencies without discussing in an issue first
- Do not commit secrets, credentials, or API keys
- Do not modify `.github/CODEOWNERS` or branch protection settings
- Do not push directly to `main` — always use pull requests

## Template Development

> **Note:** This section is only present in the template repository.

For template scripts, placeholder reference, and setup instructions, see [docs/TEMPLATE_DEVELOPMENT.md](docs/TEMPLATE_DEVELOPMENT.md).
