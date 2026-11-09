<#
.SYNOPSIS
    Validates the GitHub Template repository for common issues.

.DESCRIPTION
    This script performs comprehensive validation of the GitHub Template to ensure:
    - All links in markdown files are working
    - All placeholder text is clearly marked
    - No leftover project-specific references exist
    - All referenced image files exist
    - Template files follow expected structure

.PARAMETER SkipLinkCheck
    Skip validation of external URLs (useful for offline testing)

.EXAMPLE
    .\Test-Template.ps1
    Runs full validation with all checks enabled

.EXAMPLE
    .\Test-Template.ps1 -SkipLinkCheck
    Runs validation but skips external URL checking

.NOTES
    File Name      : Test-Template.ps1
    Author         : Chris Taylor
    Prerequisite   : PowerShell 7.2 or higher
    Copyright 2025 - Chris Taylor Codes
#>

[CmdletBinding()]
param(
    [switch]$SkipLinkCheck
)

# Initialize results
$script:ValidationErrors = @()
$script:ValidationWarnings = @()
$script:ValidationPassed = @()

# Helper function to write section headers
function Write-ValidationHeader {
    param([string]$Title)
    Write-Host ""
    Write-Host "=======================================================" -ForegroundColor Cyan
    Write-Host " $Title" -ForegroundColor Cyan
    Write-Host "=======================================================" -ForegroundColor Cyan
}

# Helper function to add error
function Add-ValidationError {
    param([string]$Message)
    $script:ValidationErrors += $Message
    Write-Host "  X ERROR: $Message" -ForegroundColor Red
}

# Helper function to add warning
function Add-ValidationWarning {
    param([string]$Message)
    $script:ValidationWarnings += $Message
    Write-Host "  ! WARNING: $Message" -ForegroundColor Yellow
}

# Helper function to add success
function Add-ValidationSuccess {
    param([string]$Message)
    $script:ValidationPassed += $Message
    Write-Verbose "  + PASS: $Message"
}

# Test required files
function Test-RequiredFiles {
    Write-ValidationHeader "Checking Required Files"

    $requiredFiles = @(
        # Docs and community
        'README.md'
        '.github/CONTRIBUTING.md'
        'docs/DONATE.md'
        'LICENSE'
        'CLAUDE.md'
        'AGENTS.md'
        'CHANGELOG.md'
        '.gitignore'
        '.editorconfig'
        '.PSScriptAnalyzerSettings.psd1'

        # Template tooling
        'Scripts/Initialize-Repository.ps1'
        'Scripts/Test-Template.ps1'
        'Scripts/New-TemplateBadges.ps1'
        'Scripts/Initialize-Labels.ps1'
        'Scripts/New-Function.ps1'
        'Scripts/Invoke-QuickTest.ps1'

        # Module source
        'source/ModuleName.psd1'
        'source/ModuleName.psm1'
        'source/en-US/about_ModuleName.help.txt'

        # Build system
        'build.ps1'
        'build.yaml'
        'RequiredModules.psd1'
        'Resolve-Dependency.ps1'
        'Resolve-Dependency.psd1'

        # CI
        '.github/workflows/ci.yml'
        '.github/workflows/pr-validation.yml'

        # Scaffolding templates
        'Templates/Function.ps1'
        'Templates/PrivateFunction.ps1'
        'Templates/Test.Tests.ps1'
        'Templates/PrivateTest.Tests.ps1'

        # Tests
        'Tests/TestHelpers/TestHelper.psm1'
        'Tests/Unit/Module/ModuleName.Module.Tests.ps1'
        'Tests/test-local.ps1'
    )

    foreach ($file in $requiredFiles) {
        if (Test-Path $file) {
            Add-ValidationSuccess "Required file exists: $file"
        } else {
            Add-ValidationError "Required file missing: $file"
        }
    }

    # Check for GitHub templates
    $githubTemplates = @(
        '.github/ISSUE_TEMPLATE/bug_report.md'
        '.github/ISSUE_TEMPLATE/feature_request.md'
        '.github/ISSUE_TEMPLATE/ai_task.md'
        '.github/ISSUE_TEMPLATE/config.yml'
        '.github/PULL_REQUEST_TEMPLATE.md'
        '.github/copilot-instructions.md'
    )

    foreach ($template in $githubTemplates) {
        if (Test-Path $template) {
            Add-ValidationSuccess "GitHub template exists: $template"
        } else {
            Add-ValidationWarning "GitHub template missing: $template"
        }
    }
}

# Test media files
function Test-MediaFiles {
    Write-ValidationHeader "Checking Media Files"

    $mediaDir = 'docs/media'

    if (-not (Test-Path $mediaDir)) {
        Add-ValidationError "Media directory does not exist: $mediaDir"
        return
    }

    $expectedMedia = @{
        'Logo.png' = 'Project logo file'
        'Demo.gif' = 'Demo/screenshot file'
        'BTC.png' = 'Bitcoin QR code'
        'BTC.txt' = 'Bitcoin wallet address'
        'ETH.png' = 'Ethereum QR code'
        'ETH.txt' = 'Ethereum wallet address'
    }

    foreach ($file in $expectedMedia.Keys) {
        $fullPath = Join-Path $mediaDir $file
        if (Test-Path $fullPath) {
            $desc = $expectedMedia[$file]
            Add-ValidationSuccess "Media file exists: $file ($desc)"
        } else {
            $desc = $expectedMedia[$file]
            Add-ValidationWarning "Media file missing: $file ($desc)"
        }
    }
}

# Test markdown links
function Test-MarkdownLinks {
    Write-ValidationHeader "Checking Markdown Links"

    $markdownFiles = Get-ChildItem -Path . -Filter "*.md" -Recurse -File |
        Where-Object { $_.FullName -notmatch '[\\/](node_modules|vendor|\.git|output|\.claude)[\\/]' }

    foreach ($mdFile in $markdownFiles) {
        $content = Get-Content $mdFile.FullName -Raw
        $relativePath = $mdFile.FullName.Replace((Get-Location).Path, '').TrimStart('\')

        # Check for internal file references
        $internalLinks = [regex]::Matches($content, '\[([^\]]+)\]\(([^)]+)\)')

        foreach ($match in $internalLinks) {
            $linkText = $match.Groups[1].Value
            $linkUrl = $match.Groups[2].Value

            # Skip external URLs and anchors
            if ($linkUrl -match '^https?://' -or $linkUrl -match '^#') {
                continue
            }

            # Handle relative paths
            $linkPath = $linkUrl -replace '#.*$', ''  # Remove anchor
            $linkPath = $linkPath -replace '".*$', '' # Remove markdown title
            $linkPath = $linkPath.Trim()

            # Skip empty links, special paths, and relative GitHub URLs
            if (-not $linkPath -or $linkPath -eq '<>' -or $linkPath -match '^\.\./\.\./' -or $linkPath -match '^\.\.\/discussions') {
                continue
            }

            $basePath = Split-Path $mdFile.FullName -Parent
            $fullLinkPath = Join-Path $basePath $linkPath

            if ($linkPath -and -not (Test-Path $fullLinkPath)) {
                Add-ValidationError "Broken internal link in ${relativePath}: '$linkText' -> $linkUrl"
            } else {
                Add-ValidationSuccess "Valid internal link in ${relativePath}: $linkUrl"
            }
        }

        # Check for image references
        $imageRefs = [regex]::Matches($content, '!\[([^\]]*)\]\(([^)]+)\)')

        foreach ($match in $imageRefs) {
            $imagePath = $match.Groups[2].Value

            # Skip external URLs
            if ($imagePath -match '^https?://') {
                continue
            }

            # Remove markdown title from path (e.g., "path/to/image.png "title"")
            $imagePath = $imagePath -replace '".*$', ''
            $imagePath = $imagePath.Trim()

            $basePath = Split-Path $mdFile.FullName -Parent
            $fullImagePath = Join-Path $basePath $imagePath

            if (-not (Test-Path $fullImagePath)) {
                Add-ValidationError "Missing image in ${relativePath}: $imagePath"
            } else {
                Add-ValidationSuccess "Valid image reference in ${relativePath}: $imagePath"
            }
        }
    }
}

# Test external links
function Test-ExternalLinks {
    if ($SkipLinkCheck) {
        Write-Host ""
        Write-Host "Skipping external link validation (SkipLinkCheck enabled)" -ForegroundColor Yellow
        return
    }

    Write-ValidationHeader "Checking External URLs"

    $markdownFiles = Get-ChildItem -Path . -Filter "*.md" -Recurse -File |
        Where-Object { $_.FullName -notmatch '[\\/](node_modules|vendor|\.git|output|\.claude)[\\/]' }

    $externalUrls = @{}

    foreach ($mdFile in $markdownFiles) {
        $content = Get-Content $mdFile.FullName -Raw
        $relativePath = $mdFile.FullName.Replace((Get-Location).Path, '').TrimStart('\')

        # Extract all URLs
        $urlMatches = [regex]::Matches($content, 'https?://[^\s\)]+')

        foreach ($match in $urlMatches) {
            $url = $match.Value.TrimEnd('.', ',', ')', ']')

            # Skip placeholder URLs
            if ($url -match 'example\.com|shields\.io.*YOUR-') {
                continue
            }

            if (-not $externalUrls.ContainsKey($url)) {
                $externalUrls[$url] = @($relativePath)
            } elseif ($externalUrls[$url] -notcontains $relativePath) {
                $externalUrls[$url] += $relativePath
            }
        }
    }

    # Test unique URLs (limited to prevent long execution)
    $urlCount = 0
    $maxUrlsToTest = 20

    foreach ($url in $externalUrls.Keys) {
        if ($urlCount -ge $maxUrlsToTest) {
            Add-ValidationWarning "Skipping remaining URLs (tested $maxUrlsToTest URLs)"
            break
        }

        try {
            $response = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 10 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                Add-ValidationSuccess "Valid URL: $url"
            } else {
                Add-ValidationWarning "Unexpected status code ($($response.StatusCode)) for URL: $url"
            }
        } catch {
            $files = $externalUrls[$url] -join ', '
            Add-ValidationError "Failed to access URL: $url (found in: $files)"
        }

        $urlCount++
        Start-Sleep -Milliseconds 100
    }
}

# Test placeholder text
function Test-PlaceholderText {
    Write-ValidationHeader "Checking for Placeholder Text"

    # Patterns that should NOT appear
    $forbiddenPatterns = @{
        'ConnectWiseManageAPI' = 'Old project-specific reference'
    }

    # Patterns that SHOULD appear
    $requiredPlaceholders = @{
        'YourModuleName|YOUR-USERNAME|YOUR-REPO' = 'Generic placeholder text'
    }

    $markdownFiles = Get-ChildItem -Path . -Filter "*.md" -File |
        Where-Object { $_.Name -notin @('CLAUDE.md', 'CHANGELOG.md') }

    foreach ($mdFile in $markdownFiles) {
        $content = Get-Content $mdFile.FullName -Raw

        # Check for forbidden patterns
        foreach ($pattern in $forbiddenPatterns.Keys) {
            if ($content -match $pattern) {
                $desc = $forbiddenPatterns[$pattern]
                Add-ValidationError "Found forbidden pattern '$pattern' in $($mdFile.Name): $desc"
            }
        }
    }

    # Check README for placeholders
    if (Test-Path 'README.md') {
        $readmeContent = Get-Content 'README.md' -Raw

        $hasPlaceholder = $false
        foreach ($pattern in $requiredPlaceholders.Keys) {
            if ($readmeContent -match $pattern) {
                $hasPlaceholder = $true
                $desc = $requiredPlaceholders[$pattern]
                Add-ValidationSuccess "README contains clear placeholders: $desc"
            }
        }

        if (-not $hasPlaceholder) {
            Add-ValidationWarning "README.md should contain clear placeholder text for users to replace"
        }
    }
}

# Test file structure
function Test-FileStructure {
    Write-ValidationHeader "Checking File Structure"

    # Check README structure
    if (Test-Path 'README.md') {
        $readme = Get-Content 'README.md' -Raw

        $requiredSections = @{
            '## Getting Started' = 'Getting Started section'
            '## (\[)?Contributing' = 'Contributing section'
            'CONTRIBUTING.md' = 'Link to contributing guide'
        }

        foreach ($section in $requiredSections.Keys) {
            if ($readme -match $section) {
                $desc = $requiredSections[$section]
                Add-ValidationSuccess "README contains: $desc"
            } else {
                $desc = $requiredSections[$section]
                Add-ValidationWarning "README missing: $desc"
            }
        }
    }

    # Check CONTRIBUTING.md structure
    if (Test-Path '.github/CONTRIBUTING.md') {
        $contributing = Get-Content '.github/CONTRIBUTING.md' -Raw

        if ($contributing -match 'Bug Reports|Reporting Bugs') {
            Add-ValidationSuccess "CONTRIBUTING.md contains bug reporting section"
        } else {
            Add-ValidationWarning "CONTRIBUTING.md should include bug reporting guidelines"
        }
    }

    # Check CHANGELOG format
    if (Test-Path 'CHANGELOG.md') {
        $changelog = Get-Content 'CHANGELOG.md' -Raw

        if ($changelog -match '\[Unreleased\]') {
            Add-ValidationSuccess "CHANGELOG.md follows Keep a Changelog format"
        } else {
            Add-ValidationWarning "CHANGELOG.md should include [Unreleased] section"
        }
    }
}

# Test git configuration
function Test-GitConfiguration {
    Write-ValidationHeader "Checking Git Configuration"

    # Check .gitignore
    if (Test-Path '.gitignore') {
        $gitignore = Get-Content '.gitignore' -Raw

        $importantPatterns = @(
            '\.vs/'
            '\.vscode/'
            'node_modules'
            '\.env'
        )

        foreach ($pattern in $importantPatterns) {
            $escaped = [regex]::Escape($pattern)
            if ($gitignore -match $escaped) {
                Add-ValidationSuccess ".gitignore includes: $pattern"
            }
        }
    }

    # Check if in git repo
    if (Test-Path '.git') {
        Add-ValidationSuccess "Repository is initialized as git repo"

        # Check for uncommitted changes
        $status = git status --porcelain 2>&1
        if ($LASTEXITCODE -eq 0) {
            if ($status) {
                Add-ValidationWarning "Repository has uncommitted changes"
            } else {
                Add-ValidationSuccess "Repository working tree is clean"
            }
        }
    } else {
        Add-ValidationWarning "Not a git repository (normal for fresh template copy)"
    }
}

# Main execution
Write-Host ""
Write-Host "========================================================" -ForegroundColor Magenta
Write-Host "  GitHub Template Repository Validation" -ForegroundColor Magenta
Write-Host "========================================================" -ForegroundColor Magenta

# Run all validation tests
Test-RequiredFiles
Test-MediaFiles
Test-MarkdownLinks
Test-ExternalLinks
Test-PlaceholderText
Test-FileStructure
Test-GitConfiguration

# Display summary
Write-Host ""
Write-Host "========================================================" -ForegroundColor Magenta
Write-Host "  Validation Summary" -ForegroundColor Magenta
Write-Host "========================================================" -ForegroundColor Magenta

Write-Host ""
Write-Host "+ Passed: " -NoNewline -ForegroundColor Green
Write-Host $script:ValidationPassed.Count

Write-Host "! Warnings: " -NoNewline -ForegroundColor Yellow
Write-Host $script:ValidationWarnings.Count

Write-Host "X Errors: " -NoNewline -ForegroundColor Red
Write-Host $script:ValidationErrors.Count

if ($script:ValidationErrors.Count -gt 0) {
    Write-Host ""
    Write-Host "======================================================" -ForegroundColor Red
    Write-Host "ERRORS FOUND:" -ForegroundColor Red
    Write-Host "======================================================" -ForegroundColor Red
    $script:ValidationErrors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
}

if ($script:ValidationWarnings.Count -gt 0) {
    Write-Host ""
    Write-Host "======================================================" -ForegroundColor Yellow
    Write-Host "WARNINGS:" -ForegroundColor Yellow
    Write-Host "======================================================" -ForegroundColor Yellow
    $script:ValidationWarnings | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
}

# Exit code based on results
if ($script:ValidationErrors.Count -gt 0) {
    Write-Host ""
    Write-Host "X Validation FAILED - Please fix errors above" -ForegroundColor Red
    exit 1
} elseif ($script:ValidationWarnings.Count -gt 0) {
    Write-Host ""
    Write-Host "! Validation PASSED with warnings - Review warnings above" -ForegroundColor Yellow
    exit 0
} else {
    Write-Host ""
    Write-Host "+ Validation PASSED - Template is ready!" -ForegroundColor Green
    exit 0
}
