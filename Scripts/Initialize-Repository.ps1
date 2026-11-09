<#
.SYNOPSIS
    Initializes a new repository from the GitHub Template.

.DESCRIPTION
    This script automates the customization of the GitHub Template repository.
    It replaces all placeholder values with your project-specific information,
    renames module files, populates the module manifest, updates documentation,
    cleans up template-specific files, and optionally initializes a new git repository.

    All replacements are literal and case-sensitive, so names containing regex
    or PowerShell special characters (for example O'Brien or "Saves $5") are
    written exactly as given. The 'ModuleName' placeholder is replaced only as a
    whole token, so Pester's -ModuleName parameter and $ModuleName variables are
    left alone.

.PARAMETER Name
    The name of your project (e.g., "MyAwesomeProject")

.PARAMETER Description
    A brief description of your project

.PARAMETER Author
    The author/maintainer name (e.g., "John Doe")

.PARAMETER GitHubUsername
    Your GitHub username or organization (e.g., "johndoe")

.PARAMETER ModuleName
    The PowerShell module name. Defaults to the Name parameter.

.PARAMETER CompanyName
    The company or vendor name. Defaults to the Author parameter.

.PARAMETER RepositoryName
    The GitHub repository name (if different from Name). Defaults to Name parameter.

.PARAMETER GitHubEmail
    Email used by the release tooling (build.yaml GitHubConfig). Defaults to the
    GitHub no-reply address for GitHubUsername.

.PARAMETER License
    License type. Default: "MIT"

.PARAMETER InitializeGit
    If specified, initializes a new git repository and creates initial commit

.PARAMETER SkipDonation
    If specified, removes donation-related content from the repository

.EXAMPLE
    .\Scripts\Initialize-Repository.ps1 -Name "MyProject" -Description "An awesome tool" -Author "John Doe" -GitHubUsername "johndoe"

.EXAMPLE
    .\Scripts\Initialize-Repository.ps1 -Name "PowerShellModule" -Description "A PowerShell module" -Author "Jane Smith" -GitHubUsername "janesmith" -InitializeGit
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [string]$Description,

    [Parameter(Mandatory = $true)]
    [string]$Author,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?$')]
    [string]$GitHubUsername,

    [Parameter(Mandatory = $false)]
    [string]$ModuleName = $Name,

    [Parameter(Mandatory = $false)]
    [string]$CompanyName = $Author,

    [Parameter(Mandatory = $false)]
    [string]$RepositoryName = $Name,

    [Parameter(Mandatory = $false)]
    [string]$GitHubEmail = "$GitHubUsername@users.noreply.github.com",

    [Parameter(Mandatory = $false)]
    [string]$License = 'MIT',

    [Parameter(Mandatory = $false)]
    [switch]$InitializeGit,

    [Parameter(Mandatory = $false)]
    [switch]$SkipDonation
)

# Script configuration
$ErrorActionPreference = 'Stop'
$CurrentYear = (Get-Date).Year
$ModuleGuid = [guid]::NewGuid().ToString()
$TemplateSlug = 'christaylorcodes/GitHub-Template'
$RepoSlug = "$GitHubUsername/$RepositoryName"

# Validate names that end up in file names, URLs and code
if ($ModuleName -notmatch '^[A-Za-z][A-Za-z0-9._-]*$') {
    throw ("Invalid module name '$ModuleName'. Must start with a letter " +
        'and contain only letters, digits, dots, underscores, and hyphens.')
}
if ($RepositoryName -notmatch '^[A-Za-z0-9._-]+$') {
    throw "Invalid repository name '$RepositoryName'. Use only letters, digits, dots, underscores, and hyphens."
}

# Values written inside single-quoted strings in .psd1 files must have ' doubled
function ConvertTo-PsdLiteral([string]$Value) { $Value.Replace("'", "''") }

# Color output functions
function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "→ $Message" -ForegroundColor Cyan
}

function Write-Caution {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Write-Step {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Magenta
}

function Update-TemplateFile {
    <#
    .SYNOPSIS
        Applies literal, case-sensitive replacements to a file, preserving its BOM.
    .PARAMETER Replace
        Ordered pairs of @(old, new). Applied in order with String.Replace (no regex).
    .PARAMETER ReplaceModuleName
        Replace the 'ModuleName' token as a whole word, skipping '-ModuleName'
        (Pester parameter) and '$ModuleName' / '$script:ModuleName' variables.
    .PARAMETER Transform
        Optional scriptblock receiving and returning the full content.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$Path,
        [object[]]$Replace = @(),
        [switch]$ReplaceModuleName,
        [scriptblock]$Transform
    )

    if (-not (Test-Path -LiteralPath $Path)) { return }

    $fullPath = (Resolve-Path -LiteralPath $Path).Path
    $bytes = [IO.File]::ReadAllBytes($fullPath)
    $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    $content = [IO.File]::ReadAllText($fullPath)

    foreach ($pair in $Replace) {
        $content = $content.Replace([string]$pair[0], [string]$pair[1])
    }

    if ($ReplaceModuleName) {
        $content = [regex]::Replace(
            $content,
            '(?<![-$:A-Za-z0-9])ModuleName(?![A-Za-z0-9])',
            [System.Text.RegularExpressions.MatchEvaluator] { param($m) $ModuleName }
        )
    }

    if ($Transform) {
        $content = & $Transform $content
    }

    $leaf = Split-Path -Leaf $fullPath
    if ($PSCmdlet.ShouldProcess($leaf, 'Replace placeholders')) {
        [IO.File]::WriteAllText($fullPath, $content, [Text.UTF8Encoding]::new($hasBom))
        Write-Success "$leaf customized"
    }
}

function Remove-TemplateItem {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][string]$Path)

    if (Test-Path -LiteralPath $Path) {
        if ($PSCmdlet.ShouldProcess($Path, 'Remove template item')) {
            Remove-Item -LiteralPath $Path -Recurse -Force
            Write-Success "Removed $Path"
        }
    }
}

# Validate we're in the template directory
Write-Step 'Validating Environment'
if (-not (Test-Path '.\README.md') -or -not (Test-Path '.\.github\CONTRIBUTING.md') -or
    -not (Test-Path '.\source\ModuleName.psd1')) {
    throw 'This script must be run from the root of an uninitialized GitHub-Template repository.'
}
Write-Success 'Template directory validated'

$commonReplacements = @(
    , @($TemplateSlug, $RepoSlug)
    , @('YOUR-USERNAME', $GitHubUsername)
    , @('yourusername', $GitHubUsername)
    , @('YOUR-REPO', $RepositoryName)
)

# README.md
Write-Step 'Customizing README.md'
Update-TemplateFile -Path '.\README.md' -Replace (@(
        , @('GitHub Template', $Name)
        , @('YOUR-PROJECT', $Name)
        , @('YOUR-PACKAGE', $ModuleName)
        , @('YourModuleName', $ModuleName)
    ) + $commonReplacements)

# Community and AI instruction files
Write-Step 'Customizing Community and AI Files'
Update-TemplateFile -Path '.\.github\CONTRIBUTING.md' -Replace (@(, @('Chris Taylor Codes', $Name)) + $commonReplacements)
Update-TemplateFile -Path '.\AGENTS.md' -Replace $commonReplacements -ReplaceModuleName -Transform {
    param($c)
    # Strip the Template Development section (template-only content)
    $c -replace '(?s)\r?\n## Template Development.*$', ''
}
Update-TemplateFile -Path '.\CLAUDE.md' -Replace $commonReplacements
Update-TemplateFile -Path '.\.github\copilot-instructions.md' -Replace $commonReplacements
Update-TemplateFile -Path '.\.github\ISSUE_TEMPLATE\config.yml' -Replace $commonReplacements
Update-TemplateFile -Path '.\.github\SECURITY.md' -Replace (@(, @('christaylor.codes', 'yourdomain.com')) + $commonReplacements)
Update-TemplateFile -Path '.\.github\CODE_OF_CONDUCT.md' -Replace @(, @('christaylor.codes', 'yourdomain.com'))
Write-Caution 'Review contact emails in .github/SECURITY.md and .github/CODE_OF_CONDUCT.md'

# LICENSE
Write-Step 'Customizing LICENSE'
Update-TemplateFile -Path '.\LICENSE' -Transform {
    param($c)
    [regex]::Replace($c, 'Copyright \(c\) \d{4} Chris Taylor',
        [System.Text.RegularExpressions.MatchEvaluator] { param($m) "Copyright (c) $CurrentYear $Author" })
}

# CHANGELOG.md: start fresh (the template's own history doesn't belong to the new project).
# Sampler's release task requires an [Unreleased] section.
Write-Step 'Resetting CHANGELOG.md'
if ($PSCmdlet.ShouldProcess('CHANGELOG.md', 'Reset to [Unreleased] stub')) {
    $changelog = @"
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Initial module scaffolding from [GitHub-Template](https://github.com/$TemplateSlug)
"@
    [IO.File]::WriteAllText((Join-Path (Get-Location) 'CHANGELOG.md'), $changelog + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
    Write-Success 'CHANGELOG.md reset'
}

# Module manifest
Write-Step 'Customizing Module Source Files'
$psdAuthor = ConvertTo-PsdLiteral $Author
Update-TemplateFile -Path '.\source\ModuleName.psd1' -Replace (@(
        , @("/YOUR-USERNAME/ModuleName/", "/$GitHubUsername/$RepositoryName/")
        , @("/YOUR-USERNAME/ModuleName'", "/$GitHubUsername/$RepositoryName'")
        , @('YOUR-USERNAME', $GitHubUsername)
        , @('Your Company', (ConvertTo-PsdLiteral $CompanyName))
        , @('Brief description of what this module does', (ConvertTo-PsdLiteral $Description))
    )) -Transform {
    param($c)
    $guidPattern = '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'
    $c = [regex]::Replace($c, $guidPattern, [System.Text.RegularExpressions.MatchEvaluator] { param($m) $ModuleGuid })
    # Copyright first, so 'Your Name' is still present for the pattern to match
    $c = [regex]::Replace($c, '\(c\) \d{4} Your Name',
        [System.Text.RegularExpressions.MatchEvaluator] { param($m) "(c) $CurrentYear $psdAuthor" })
    $c = $c.Replace('Your Name', $psdAuthor)
    [regex]::Replace($c, '(?<![-$:A-Za-z0-9])ModuleName(?![A-Za-z0-9])',
        [System.Text.RegularExpressions.MatchEvaluator] { param($m) $ModuleName })
}
Write-Info "Module GUID: $ModuleGuid"

$codeReplacements = @(
    , @('/YOUR-USERNAME/ModuleName', "/$GitHubUsername/$RepositoryName")
    , @('Your Name', $Author)
) + $commonReplacements

Update-TemplateFile -Path '.\source\Public\Get-ModuleInfo.ps1' -Replace $codeReplacements -ReplaceModuleName
Update-TemplateFile -Path '.\source\ModuleName.psm1' -Replace $codeReplacements -ReplaceModuleName
Update-TemplateFile -Path '.\source\en-US\about_ModuleName.help.txt' -Replace $codeReplacements -ReplaceModuleName

# Tests (TestHelper.psm1 discovers the module name itself, so it is not edited)
Write-Step 'Customizing Tests'
Update-TemplateFile -Path '.\Tests\Unit\Public\Get-ModuleInfo.Tests.ps1' -ReplaceModuleName
Update-TemplateFile -Path '.\Tests\Unit\Module\ModuleName.Module.Tests.ps1' -ReplaceModuleName

# Templates used by New-Function.ps1
Write-Step 'Customizing Templates'
foreach ($templateFile in Get-ChildItem -Path '.\Templates' -Filter '*.ps1' -File) {
    Update-TemplateFile -Path $templateFile.FullName -Replace $codeReplacements -ReplaceModuleName
}

# Documentation
Write-Step 'Customizing Documentation Files'
$docReplacements = @(
    , @('/YOUR-USERNAME/ModuleName', "/$GitHubUsername/$RepositoryName")
    , @('Your Name', $Author)
    , @('Your Company', $CompanyName)
) + $commonReplacements
foreach ($docFile in @('.\docs\PUBLISHING.md', '.\docs\USAGE.md', '.\docs\examples\Example-BasicUsage.ps1')) {
    Update-TemplateFile -Path $docFile -Replace $docReplacements -ReplaceModuleName
}

# Build and CI configuration
Write-Step 'Customizing Build and CI Configuration'
Update-TemplateFile -Path '.\build.yaml' -Replace @(
    , @('GitHubConfigUserName: YOUR-USERNAME', "GitHubConfigUserName: $GitHubUsername")
    , @('GitHubConfigUserEmail: your@email.com', "GitHubConfigUserEmail: $GitHubEmail")
)
foreach ($workflow in @('.\.github\workflows\ci.yml', '.\.github\workflows\pr-validation.yml')) {
    Update-TemplateFile -Path $workflow -Replace @(, @('MODULE_NAME: ModuleName', "MODULE_NAME: $ModuleName"))
}

# Rename module files
Write-Step 'Renaming Module Files'
$fileRenames = @(
    @{ Source = '.\source\ModuleName.psd1'; Target = "$ModuleName.psd1" }
    @{ Source = '.\source\ModuleName.psm1'; Target = "$ModuleName.psm1" }
    @{ Source = '.\source\en-US\about_ModuleName.help.txt'; Target = "about_$ModuleName.help.txt" }
    @{ Source = '.\Tests\Unit\Module\ModuleName.Module.Tests.ps1'; Target = "$ModuleName.Module.Tests.ps1" }
)
foreach ($rename in $fileRenames) {
    $sourceName = Split-Path -Leaf $rename.Source
    if ((Test-Path $rename.Source) -and ($sourceName -cne $rename.Target)) {
        if ($PSCmdlet.ShouldProcess($sourceName, "Rename to $($rename.Target)")) {
            Rename-Item -Path $rename.Source -NewName $rename.Target
            Write-Success "Renamed $sourceName -> $($rename.Target)"
        }
    }
}

# Donation content
# Root DONATE.md and Media/ only exist as backwards-compatible mirrors for links
# to the template itself; new projects never need them.
Write-Step 'Handling Donation Content'
Remove-TemplateItem -Path '.\DONATE.md'
Remove-TemplateItem -Path '.\Media'

if ($SkipDonation) {
    Remove-TemplateItem -Path '.\docs\DONATE.md'
    foreach ($donationFile in @('BTC.png', 'BTC.txt', 'ETH.png', 'ETH.txt')) {
        Remove-TemplateItem -Path (Join-Path '.\docs\media' $donationFile)
    }
    # Remove the README "Support" section that links to DONATE.md
    Update-TemplateFile -Path '.\README.md' -Transform {
        param($c)
        $c -replace '(?s)\r?\n## \[Support\]\(docs/DONATE\.md\).*?(?=\r?\n## |\z)', ''
    }
}
else {
    Update-TemplateFile -Path '.\docs\DONATE.md' -Transform {
        param($c)
        # Drop the template-only mirror note
        $c -replace '(?s)\A<!--.*?-->\s*', ''
    }
    Write-Caution 'docs/DONATE.md still contains the template author''s PayPal link and wallet addresses.'
    Write-Caution 'Replace them (and the QR codes in docs/media/) with your own, or re-run with -SkipDonation.'
}

# Clean up template-specific files
Write-Step 'Cleaning Template Files'
foreach ($item in @(
        '.\Scripts\Test-Template.ps1'
        '.\Scripts\New-TemplateBadges.ps1'
        '.\Scripts\Initialize-Roadmap.ps1'
        '.\docs\TEMPLATE_USAGE.md'
        '.\docs\TEMPLATE_DEVELOPMENT.md'
        '.\Tests\Template'
        '.\.claude\plans'
    )) {
    Remove-TemplateItem -Path $item
}

# Rename AI_SETUP_GUIDE.md to CUSTOMIZATION_GUIDE.md (keep as post-init reference)
$setupGuide = '.\docs\AI_SETUP_GUIDE.md'
if (Test-Path $setupGuide) {
    if ($PSCmdlet.ShouldProcess('AI_SETUP_GUIDE.md', 'Rename to CUSTOMIZATION_GUIDE.md')) {
        Rename-Item -Path $setupGuide -NewName 'CUSTOMIZATION_GUIDE.md'
        Write-Success 'AI_SETUP_GUIDE.md renamed to CUSTOMIZATION_GUIDE.md'
    }
}

# Remove this script last
Remove-TemplateItem -Path $MyInvocation.MyCommand.Definition

# Initialize Git repository
if ($InitializeGit) {
    Write-Step 'Initializing Git Repository'

    if (Test-Path '.\.git') {
        Write-Warning 'Git repository already exists. Skipping git initialization.'
        Write-Info 'If you want to start fresh, delete the .git directory manually first.'
    }
    elseif ($PSCmdlet.ShouldProcess('Repository', 'Initialize git and create initial commit')) {
        git init
        if ($LASTEXITCODE -ne 0) { throw 'git init failed' }
        Write-Success 'Git repository initialized'

        git add .
        if ($LASTEXITCODE -ne 0) { throw 'git add failed' }
        Write-Success 'Files staged for commit'

        $commitMessage = @"
Initial commit - $Name

Project: $Name
Module: $ModuleName
Description: $Description
Author: $Author

Generated from GitHub-Template
https://github.com/$TemplateSlug
"@
        git commit -m $commitMessage
        if ($LASTEXITCODE -ne 0) { throw 'git commit failed (is user.name/user.email configured?)' }
        Write-Success 'Initial commit created'

        Write-Info 'To push to GitHub, create a repository and run:'
        Write-Host "  git remote add origin https://github.com/$RepoSlug.git" -ForegroundColor White
        Write-Host '  git branch -M main' -ForegroundColor White
        Write-Host '  git push -u origin main' -ForegroundColor White
    }
}

# Summary
Write-Step 'Initialization Complete!'
Write-Host ''
Write-Success 'Repository customized successfully!'
Write-Host ''
Write-Host 'Project Details:' -ForegroundColor Yellow
Write-Host "  Name:        $Name"
Write-Host "  Module:      $ModuleName"
Write-Host "  Description: $Description"
Write-Host "  Author:      $Author"
Write-Host "  Company:     $CompanyName"
Write-Host "  GUID:        $ModuleGuid"
Write-Host "  GitHub:      https://github.com/$RepoSlug"
Write-Host ''
Write-Host 'Next Steps:' -ForegroundColor Yellow
$steps = @(
    "Verify module loads: Import-Module ./source/$ModuleName.psd1 -Force"
    'Run build: ./build.ps1 -ResolveDependency -Tasks build'
    'Run tests: ./Tests/test-local.ps1'
    'Review and update ./README.md (badges, description, Logo.png, Demo.gif)'
    'Create the "production" and "prerelease" environments and their PSGALLERY_API_KEY secrets (docs/PUBLISHING.md)'
)
if (-not $SkipDonation) {
    $steps += 'Update donation links and wallet addresses in ./docs/DONATE.md and ./docs/media/'
}
$steps += 'Update contact emails in .github/SECURITY.md and .github/CODE_OF_CONDUCT.md'
$steps += 'Review AGENTS.md and CLAUDE.md for your project'
$steps += 'Run ./Scripts/Initialize-Labels.ps1 to create AI workflow labels (optional)'
for ($i = 0; $i -lt $steps.Count; $i++) {
    Write-Host "  $($i + 1). $($steps[$i])"
}
Write-Host ''
Write-Info "Use 'git checkout -- .' to undo changes (if repo was cloned)"
Write-Info 'Run /customize in Claude Code for guided project setup'
Write-Host ''
Write-Success 'Happy coding!'
