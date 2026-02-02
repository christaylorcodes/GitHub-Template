<#
.SYNOPSIS
    Creates GitHub milestones and issues for the template roadmap.

.DESCRIPTION
    Uses the GitHub CLI (gh) to create milestones and structured issues
    for planned template improvements. Each issue follows the ai_task
    template format with objective, requirements, acceptance criteria,
    and scoped file lists.

    This script is idempotent for milestones (creates if missing) but
    will create duplicate issues if run twice. Run once per planning session.

    Requires the gh CLI to be installed and authenticated.

.PARAMETER DryRun
    If specified, shows what would be created without making changes.

.EXAMPLE
    .\Scripts\Initialize-Roadmap.ps1

    Creates all milestones and issues on the current repository.

.EXAMPLE
    .\Scripts\Initialize-Roadmap.ps1 -DryRun

    Shows what would be created without making any changes.

.NOTES
    Requires: GitHub CLI (gh) installed and authenticated
#>
[CmdletBinding()]
param(
    [Parameter()]
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

# ── Preflight ────────────────────────────────────────────────────────────────

if (-not (Get-Command 'gh' -ErrorAction SilentlyContinue)) {
    Write-Error 'GitHub CLI (gh) is not installed. Install from https://cli.github.com/'
    return
}

$null = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error 'GitHub CLI is not authenticated. Run: gh auth login'
    return
}

# ── Helper ───────────────────────────────────────────────────────────────────

function New-Milestone {
    param(
        [string]$Title,
        [string]$Description
    )

    if ($DryRun) {
        Write-Host "  [DRY RUN] Would create milestone: $Title" -ForegroundColor Yellow
        return
    }

    # Check if milestone already exists
    $existing = gh api repos/{owner}/{repo}/milestones --jq ".[].title" 2>&1
    if ($existing -contains $Title) {
        Write-Host "  Milestone exists: $Title" -ForegroundColor DarkGray
        return
    }

    Write-Host "  Creating milestone: $Title ... " -NoNewline
    $result = gh api repos/{owner}/{repo}/milestones --method POST -f title="$Title" -f description="$Description" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host 'OK' -ForegroundColor Green
    } else {
        Write-Host "FAILED: $result" -ForegroundColor Red
    }
}

function New-Issue {
    param(
        [string]$Title,
        [string]$Body,
        [string]$Milestone,
        [string[]]$Labels = @('ai-task', 'ai-ready')
    )

    if ($DryRun) {
        Write-Host "  [DRY RUN] Would create issue: $Title" -ForegroundColor Yellow
        Write-Host "            Milestone: $Milestone | Labels: $($Labels -join ', ')" -ForegroundColor DarkYellow
        return
    }

    Write-Host "  Creating issue: $Title ... " -NoNewline
    $labelArg = $Labels -join ','
    $result = gh issue create --title $Title --body $Body --milestone $Milestone --label $labelArg 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "OK ($result)" -ForegroundColor Green
    } else {
        Write-Host "FAILED: $result" -ForegroundColor Red
    }
}

# ── Milestones ───────────────────────────────────────────────────────────────

Write-Host ''
Write-Host 'Creating Milestones' -ForegroundColor Cyan
Write-Host '====================' -ForegroundColor Cyan

New-Milestone -Title 'v1.1.0 Release' -Description 'Ship the current body of work — commit, tag, and publish the v1.1.0 changes.'
New-Milestone -Title 'v1.2.0 - Template Polish' -Description 'Fix stale paths, add missing examples, and close gaps identified in the v1.1.0 review.'
New-Milestone -Title 'v1.3.0 - Quality of Life' -Description 'Developer experience improvements, documentation enhancements, and extended automation.'

# ── Issues: v1.1.0 Release ──────────────────────────────────────────────────

Write-Host ''
Write-Host 'Creating Issues: v1.1.0 Release' -ForegroundColor Cyan
Write-Host '=================================' -ForegroundColor Cyan

New-Issue -Milestone 'v1.1.0 Release' -Labels @('ai-task', 'ai-ready', 'priority-high') `
    -Title '[AI] Commit, tag, and release v1.1.0' `
    -Body @'
## Objective
Commit all outstanding v1.1.0 changes, create the git tag, and push to trigger the publish workflow.

## Context
The entire v1.1.0 body of work (build system overhaul, new scripts, CI/CD, AI integration, documentation) is complete but sitting uncommitted in the working tree. The CHANGELOG already has the `[1.1.0] - 2026-02-01` entry.

## Requirements
- [ ] Stage all v1.1.0 changes (review diff carefully before staging)
- [ ] Create a clean commit with a descriptive message summarizing the release
- [ ] Tag the commit as `v1.1.0`
- [ ] Push the commit and tag to origin

## Acceptance Criteria
- [ ] `git status` shows a clean working tree
- [ ] `git log --oneline -1` shows the v1.1.0 commit
- [ ] `git tag -l v1.1.0` returns the tag
- [ ] GitHub Actions publish workflow triggers successfully (if secrets are configured)

## Files to Modify
- All currently unstaged/untracked files shown in `git status`

## Out of Scope
- Do not modify any file content — this is purely a commit-and-ship task
- Do not fix bugs found during review — open separate issues for those
'@

# ── Issues: v1.2.0 - Template Polish ────────────────────────────────────────

Write-Host ''
Write-Host 'Creating Issues: v1.2.0 - Template Polish' -ForegroundColor Cyan
Write-Host '============================================' -ForegroundColor Cyan

New-Issue -Milestone 'v1.2.0 - Template Polish' -Labels @('ai-task', 'ai-ready', 'priority-high', 'bug') `
    -Title '[AI] Fix stale paths in Test-Template.ps1' `
    -Body @'
## Objective
Update Test-Template.ps1 to reference the correct file paths after the v1.1.0 directory reorganization.

## Context
Several files were moved in v1.1.0:
- `Media/` → `docs/media/`
- `CONTRIBUTING.md` (root) → `.github/CONTRIBUTING.md`

Test-Template.ps1 still references the old locations, so validation will report false errors/warnings.

## Requirements
- [ ] Update `Test-MediaFiles` to check `docs/media/` instead of `Media/`
- [ ] Update `Test-RequiredFiles` to check `.github/CONTRIBUTING.md` instead of `CONTRIBUTING.md`
- [ ] Update `Test-FileStructure` CONTRIBUTING.md content check to use `.github/CONTRIBUTING.md`
- [ ] Verify the script runs cleanly against the current repo structure

## Acceptance Criteria
- [ ] `.\Scripts\Test-Template.ps1 -SkipLinkCheck` reports no false errors from stale paths
- [ ] All existing validation logic still works correctly
- [ ] PSScriptAnalyzer reports zero errors on the modified script

## Files to Modify
- `Scripts/Test-Template.ps1`

## Out of Scope
- Adding new validation checks (separate issue)
- Fixing external link checking behavior
'@

New-Issue -Milestone 'v1.2.0 - Template Polish' -Labels @('ai-task', 'ai-ready', 'priority-medium') `
    -Title '[AI] Fix README section mismatch with Test-Template validator' `
    -Body @'
## Objective
Align the Test-Template.ps1 file structure checks with the actual README.md section headings.

## Context
`Test-FileStructure` in Test-Template.ps1 looks for `## Installation` but the README uses `## Getting Started`. The validator will report a false warning.

## Requirements
- [ ] Update `Test-FileStructure` to check for `Getting Started` instead of (or in addition to) `Installation`
- [ ] Review all section name checks in the validator against current README structure
- [ ] Ensure the check works both for the template README and for a post-initialization README

## Acceptance Criteria
- [ ] `.\Scripts\Test-Template.ps1 -SkipLinkCheck` does not warn about missing README sections that exist
- [ ] PSScriptAnalyzer reports zero errors

## Files to Modify
- `Scripts/Test-Template.ps1`

## Out of Scope
- Restructuring the README itself
'@

New-Issue -Milestone 'v1.2.0 - Template Polish' -Labels @('ai-task', 'ai-ready', 'priority-medium') `
    -Title '[AI] Add [Unreleased] section to CHANGELOG.md' `
    -Body @'
## Objective
Add an `[Unreleased]` section to CHANGELOG.md following Keep a Changelog conventions.

## Context
The CHANGELOG recommends maintaining an `[Unreleased]` section, and `Test-FileStructure` checks for it, but the current CHANGELOG does not have one. This should be a permanent section at the top that accumulates changes between releases.

## Requirements
- [ ] Add `## [Unreleased]` section above `## [1.1.0]`
- [ ] Include empty subsection stubs (Added, Changed, Fixed) as a guide
- [ ] Add comparison link at the bottom: `[Unreleased]: https://github.com/christaylorcodes/GitHub-Template/compare/v1.1.0...HEAD`

## Acceptance Criteria
- [ ] `Test-FileStructure` no longer warns about missing [Unreleased] section
- [ ] CHANGELOG follows Keep a Changelog format

## Files to Modify
- `CHANGELOG.md`

## Out of Scope
- Rewriting existing changelog entries
'@

New-Issue -Milestone 'v1.2.0 - Template Polish' -Labels @('ai-task', 'ai-ready', 'priority-medium', 'enhancement') `
    -Title '[AI] Add example private function with matching test' `
    -Body @'
## Objective
Add a sample private helper function and corresponding Pester test to demonstrate the Private/ pattern to template users.

## Context
The template includes `source/Public/Get-ModuleInfo.ps1` as an example of a public function, but `source/Private/` is empty. New users have no reference for how private functions should be structured, tested (with `InModuleScope`), or documented.

## Requirements
- [ ] Create `source/Private/Format-OutputData.ps1` (or similar utility name) as a simple private helper
- [ ] Function should use comment-based help (`.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.OUTPUTS`)
- [ ] Function should follow the style guide: approved verb, `[CmdletBinding()]`, proper parameter attributes
- [ ] Create `Tests/Unit/Private/Format-OutputData.Tests.ps1` with Pester 5.6+ syntax
- [ ] Test must use `InModuleScope` to access the private function
- [ ] Include at least 2-3 test cases demonstrating the pattern

## Acceptance Criteria
- [ ] `./Tests/test-local.ps1` passes with the new function and tests
- [ ] PSScriptAnalyzer reports zero errors on both files
- [ ] The private function is NOT exported (verify with `Get-Command -Module ModuleName`)
- [ ] Test file demonstrates `InModuleScope` usage clearly

## Files to Modify
- `source/Private/Format-OutputData.ps1` (new)
- `Tests/Unit/Private/Format-OutputData.Tests.ps1` (new)

## Out of Scope
- Modifying the module loader (it already auto-discovers Private/ files)
- Adding integration tests (separate issue)

## Technical Notes
- Keep the function simple — it exists to demonstrate the pattern, not to provide real utility
- A data formatting/transformation helper is a natural fit for a private function
- The Templates/PrivateFunction.ps1 and Templates/PrivateTest.Tests.ps1 already exist as scaffolding templates; the example should follow the same patterns
'@

New-Issue -Milestone 'v1.2.0 - Template Polish' -Labels @('ai-task', 'ai-ready', 'priority-medium', 'enhancement') `
    -Title '[AI] Add example PowerShell class with matching test' `
    -Body @'
## Objective
Add a sample PowerShell class and corresponding Pester test to demonstrate the Classes/ pattern to template users.

## Context
The template includes `source/Classes/` in the module loader order (classes load first, before Private and Public), but the directory is empty. New users have no reference for how classes integrate with the module.

## Requirements
- [ ] Create `source/Classes/ModuleConfig.ps1` (or similar) with a simple PowerShell class
- [ ] Class should demonstrate: properties, a constructor, and at least one method
- [ ] Create `Tests/Unit/Classes/ModuleConfig.Tests.ps1` with Pester 5.6+ syntax
- [ ] Include 2-3 test cases covering construction and method behavior

## Acceptance Criteria
- [ ] `./Tests/test-local.ps1` passes with the new class and tests
- [ ] PSScriptAnalyzer reports zero errors
- [ ] Class is usable from both Private and Public functions (loaded first in module)

## Files to Modify
- `source/Classes/ModuleConfig.ps1` (new)
- `Tests/Unit/Classes/ModuleConfig.Tests.ps1` (new)

## Out of Scope
- Complex inheritance or interface patterns
- Modifying the module loader
'@

New-Issue -Milestone 'v1.2.0 - Template Polish' -Labels @('ai-task', 'ai-ready', 'priority-low', 'enhancement') `
    -Title '[AI] Add example integration test' `
    -Body @'
## Objective
Add a sample integration test to demonstrate cross-function testing patterns.

## Context
`Tests/Integration/` exists but is empty. The `Templates/IntegrationTest.Tests.ps1` template exists for scaffolding, but there is no concrete example showing how integration tests differ from unit tests in this project.

## Requirements
- [ ] Create `Tests/Integration/ModuleIntegration.Tests.ps1`
- [ ] Test should import the module and verify that public + private + class components work together
- [ ] Use the `Integration` Pester tag
- [ ] Include at least 2 test cases

## Acceptance Criteria
- [ ] `./Tests/test-local.ps1` passes with the new test
- [ ] Test is tagged so it can be run selectively: `Invoke-Pester -Tag Integration`
- [ ] Test demonstrates a pattern clearly different from unit tests

## Files to Modify
- `Tests/Integration/ModuleIntegration.Tests.ps1` (new)

## Out of Scope
- Modifying the test runner configuration
- External service integration (keep it self-contained)
'@

New-Issue -Milestone 'v1.2.0 - Template Polish' -Labels @('ai-task', 'ai-ready', 'priority-medium') `
    -Title '[AI] Update Initialize-Repository.ps1 for new private/class example files' `
    -Body @'
## Objective
Update the initialization script to handle placeholder replacement in the new example private function, class, and test files.

## Context
Once the private function example (Format-OutputData.ps1) and class example (ModuleConfig.ps1) are added, Initialize-Repository.ps1 needs to replace `ModuleName` placeholders in those files during project setup.

## Requirements
- [ ] Add placeholder replacement for `source/Private/Format-OutputData.ps1`
- [ ] Add placeholder replacement for `source/Classes/ModuleConfig.ps1`
- [ ] Add placeholder replacement for `Tests/Unit/Private/Format-OutputData.Tests.ps1`
- [ ] Add placeholder replacement for `Tests/Unit/Classes/ModuleConfig.Tests.ps1`
- [ ] Add placeholder replacement for `Tests/Integration/ModuleIntegration.Tests.ps1`

## Acceptance Criteria
- [ ] Running `Initialize-Repository.ps1 -WhatIf` shows the new files being processed
- [ ] After initialization, no `ModuleName` placeholder text remains in the new files
- [ ] PSScriptAnalyzer reports zero errors

## Files to Modify
- `Scripts/Initialize-Repository.ps1`

## Out of Scope
- Modifying the example files themselves (those are separate issues)

## Technical Notes
- This issue depends on the private function, class, and integration test issues being completed first
'@

# ── Issues: v1.3.0 - Quality of Life ────────────────────────────────────────

Write-Host ''
Write-Host 'Creating Issues: v1.3.0 - Quality of Life' -ForegroundColor Cyan
Write-Host '============================================' -ForegroundColor Cyan

New-Issue -Milestone 'v1.3.0 - Quality of Life' -Labels @('ai-task', 'ai-ready', 'priority-medium', 'enhancement') `
    -Title '[AI] Add Initialize-Repository self-cleanup for template-only files' `
    -Body @'
## Objective
After initialization, automatically remove files that are only relevant to the template repository itself and not to derived projects.

## Context
Files like `docs/TEMPLATE_DEVELOPMENT.md`, `Scripts/Test-Template.ps1`, `Scripts/New-TemplateBadges.ps1`, and this roadmap script are only useful in the template repo. After a user runs `Initialize-Repository.ps1`, these files remain and can confuse new users.

## Requirements
- [ ] Add a cleanup step at the end of `Initialize-Repository.ps1`
- [ ] Remove template-only files: `docs/TEMPLATE_DEVELOPMENT.md`, `Scripts/Test-Template.ps1`, `Scripts/New-TemplateBadges.ps1`, `Scripts/Initialize-Roadmap.ps1`
- [ ] Guard with `-WhatIf` / `ShouldProcess` support (consistent with the rest of the script)
- [ ] Add a `-KeepTemplateFiles` switch to skip cleanup if desired
- [ ] Log which files were removed

## Acceptance Criteria
- [ ] After initialization, template-only files are gone by default
- [ ] `-KeepTemplateFiles` preserves them
- [ ] `-WhatIf` shows what would be removed without acting
- [ ] PSScriptAnalyzer reports zero errors

## Files to Modify
- `Scripts/Initialize-Repository.ps1`

## Out of Scope
- Removing the Templates/ directory (those are useful for scaffolding new functions in derived projects)
'@

New-Issue -Milestone 'v1.3.0 - Quality of Life' -Labels @('ai-task', 'ai-ready', 'priority-medium', 'enhancement') `
    -Title '[AI] Document Codecov integration setup' `
    -Body @'
## Objective
Add documentation for setting up Codecov code coverage reporting in derived repositories.

## Context
The `ci.yml` workflow already uploads coverage data to Codecov, but there is no documentation explaining how to:
1. Create a Codecov account and link the repo
2. Add the `CODECOV_TOKEN` secret to GitHub
3. Optionally add a `codecov.yml` configuration file
4. Add the Codecov badge to README

Without this, users see the upload step in CI but have no coverage reporting.

## Requirements
- [ ] Add a "Code Coverage" section to `docs/PUBLISHING.md` or create `docs/CODECOV_SETUP.md`
- [ ] Document account setup, token configuration, and badge generation
- [ ] Include a sample `codecov.yml` with sensible defaults (target coverage, flags, etc.)
- [ ] Add Codecov badge placeholder to the badge generation script

## Acceptance Criteria
- [ ] A new user can follow the guide end-to-end and see coverage reports
- [ ] Internal links from other docs reference the new section/file
- [ ] No broken links

## Files to Modify
- `docs/PUBLISHING.md` or `docs/CODECOV_SETUP.md` (new)
- `Scripts/New-TemplateBadges.ps1` (add Codecov badge option)

## Out of Scope
- Changing the test workflow itself
- Enforcing minimum coverage thresholds in CI
'@

New-Issue -Milestone 'v1.3.0 - Quality of Life' -Labels @('ai-task', 'ai-ready', 'priority-low', 'enhancement') `
    -Title '[AI] Add Invoke-QuickTest documentation to AGENTS.md' `
    -Body @'
## Objective
Document the Invoke-QuickTest.ps1 script in AGENTS.md so AI agents and developers know about the fast feedback workflow.

## Context
`Scripts/Invoke-QuickTest.ps1` provides targeted, fast test execution during development, but it is not documented in AGENTS.md (the single source of truth for build/test commands). Agents default to `test-local.ps1` for everything, missing the faster option.

## Requirements
- [ ] Add Invoke-QuickTest.ps1 usage examples to the Testing section of AGENTS.md
- [ ] Document the available parameters: `-FunctionName`, `-IncludeAnalyzer`, `-OutputFormat`
- [ ] Explain when to use QuickTest vs test-local.ps1 vs the full build

## Acceptance Criteria
- [ ] AGENTS.md Testing section includes QuickTest documentation
- [ ] Examples are copy-paste ready
- [ ] No broken links in AGENTS.md

## Files to Modify
- `AGENTS.md`

## Out of Scope
- Modifying the QuickTest script itself
'@

New-Issue -Milestone 'v1.3.0 - Quality of Life' -Labels @('ai-task', 'ai-ready', 'priority-low', 'enhancement') `
    -Title '[AI] Add pre-commit hook for PSScriptAnalyzer' `
    -Body @'
## Objective
Provide an optional git pre-commit hook that runs PSScriptAnalyzer on staged `.ps1` files before allowing a commit.

## Context
Currently, code quality issues are caught either during `test-local.ps1` (manual) or in CI (slow feedback). A pre-commit hook would catch analyzer errors immediately, preventing bad commits from being created.

## Requirements
- [ ] Create `.githooks/pre-commit` script that runs PSScriptAnalyzer on staged `.ps1` files
- [ ] Only analyze files that are staged (not the entire `source/` directory)
- [ ] Block commit on Error-severity findings; allow Warning-severity with a message
- [ ] Add a setup section to AGENTS.md or CONTRIBUTING.md explaining how to enable it (`git config core.hooksPath .githooks`)
- [ ] Make it optional — do not auto-enable during initialization

## Acceptance Criteria
- [ ] Staging a file with an analyzer error and attempting to commit is blocked with a clear message
- [ ] Staging a clean file allows the commit to proceed
- [ ] The hook runs only on staged `.ps1` files, not the entire repo
- [ ] Documentation explains setup and opt-in

## Files to Modify
- `.githooks/pre-commit` (new)
- `AGENTS.md` or `.github/CONTRIBUTING.md` (documentation)

## Out of Scope
- Pre-push hooks (test-local.ps1 already serves that purpose)
- Automatic hook installation during repository initialization
'@

New-Issue -Milestone 'v1.3.0 - Quality of Life' -Labels @('ai-task', 'ai-ready', 'priority-low', 'enhancement') `
    -Title '[AI] Create Demo GIF showing template initialization workflow' `
    -Body @'
## Objective
Replace the placeholder Demo.gif with an actual recording showing the template setup workflow.

## Context
The README references `docs/media/Demo.gif` but this is a placeholder file. A real demo GIF showing the initialization workflow would help users understand what the template provides at a glance.

## Requirements
- [ ] Record a terminal session showing: clone → Initialize-Repository.ps1 → build → test → first function scaffolding
- [ ] Keep the recording under 30 seconds
- [ ] Use a clean terminal with readable font size
- [ ] Save as `docs/media/Demo.gif` (replace the placeholder)

## Acceptance Criteria
- [ ] GIF displays correctly in the README on GitHub
- [ ] File size is reasonable (< 5 MB)
- [ ] Recording shows a realistic end-to-end workflow

## Files to Modify
- `docs/media/Demo.gif` (replace)

## Out of Scope
- Logo design (separate task)
- Video recording (GIF only)

## Technical Notes
- Tools like `terminalizer`, `vhs`, or `asciinema` + `agg` can create terminal GIFs
- Consider using `vhs` (https://github.com/charmbracelet/vhs) for reproducible recordings via a `.tape` file
'@

# ── Summary ──────────────────────────────────────────────────────────────────

Write-Host ''
Write-Host '========================================================' -ForegroundColor Magenta
Write-Host '  Roadmap Initialization Complete' -ForegroundColor Magenta
Write-Host '========================================================' -ForegroundColor Magenta
Write-Host ''
Write-Host '  Milestones created: 3' -ForegroundColor White
Write-Host '    - v1.1.0 Release          (1 issue)' -ForegroundColor White
Write-Host '    - v1.2.0 - Template Polish (7 issues)' -ForegroundColor White
Write-Host '    - v1.3.0 - Quality of Life (5 issues)' -ForegroundColor White
Write-Host '  Total issues: 13' -ForegroundColor White
Write-Host ''

if ($DryRun) {
    Write-Host 'This was a dry run. Run without -DryRun to apply changes.' -ForegroundColor Yellow
} else {
    Write-Host 'Run "gh issue list --state open" to see all created issues.' -ForegroundColor Green
    Write-Host 'Run "gh api repos/{owner}/{repo}/milestones --jq ''.[].title''" to see milestones.' -ForegroundColor Green
}
