<#
.SYNOPSIS
    Generates shields.io badge URLs for GitHub projects.

.DESCRIPTION
    This script helps create consistent badge URLs for common services like:
    - Build status (GitHub Actions, AppVeyor, CircleCI, etc.)
    - Code quality (Codacy, Code Climate, etc.)
    - Package managers (PowerShell Gallery, npm, PyPI, RubyGems, etc.)
    - License badges
    - Version badges
    - Custom badges

.PARAMETER GitHubUsername
    GitHub username or organization name

.PARAMETER RepositoryName
    GitHub repository name

.PARAMETER License
    License type (e.g., MIT, Apache-2.0, GPL-3.0)

.PARAMETER PackageManager
    Package manager type: PSGallery, npm, PyPI, RubyGems, Crates, Go

.PARAMETER PackageName
    Name of the package in the package manager

.PARAMETER UpdateReadme
    If specified, updates the README.md file with generated badges

.PARAMETER OutputFormat
    Output format: Markdown (default), HTML, or AsciiDoc

.EXAMPLE
    .\New-TemplateBadges.ps1 -GitHubUsername "christaylorcodes" -RepositoryName "MyProject" -License "MIT"
    Generates basic badges for a GitHub project

.EXAMPLE
    .\New-TemplateBadges.ps1 -GitHubUsername "myuser" -RepositoryName "myapp" -PackageManager npm -PackageName "myapp" -UpdateReadme
    Generates badges and updates README.md

.NOTES
    File Name      : New-TemplateBadges.ps1
    Author         : Chris Taylor
    Prerequisite   : PowerShell 7.6 or higher
    Copyright 2025 - Chris Taylor Codes
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$GitHubUsername,

    [Parameter(Mandatory=$true)]
    [string]$RepositoryName,

    [string]$License = "MIT",

    [ValidateSet('PSGallery', 'npm', 'PyPI', 'RubyGems', 'Crates', 'Go', 'None')]
    [string]$PackageManager = 'None',

    [string]$PackageName,

    [switch]$UpdateReadme,

    [ValidateSet('Markdown', 'HTML', 'AsciiDoc')]
    [string]$OutputFormat = 'Markdown'
)

# Badge generation functions
function New-GitHubActionsBadge {
    param(
        [string]$Username,
        [string]$Repo,
        [string]$WorkflowName = "CI",
        [string]$Branch = "main"
    )

    $encodedWorkflow = [Uri]::EscapeDataString($WorkflowName)
    $url = "https://github.com/$Username/$Repo/workflows/$encodedWorkflow/badge.svg?branch=$Branch"
    $link = "https://github.com/$Username/$Repo/actions"

    return @{
        ImageUrl = $url
        Link = $link
        Alt = "Build Status"
    }
}

function New-LicenseBadge {
    param(
        [string]$License,
        [string]$Username,
        [string]$Repo
    )

    $encodedLicense = [Uri]::EscapeDataString($License)
    $color = switch ($License) {
        "MIT" { "blue" }
        "Apache-2.0" { "blue" }
        "GPL-3.0" { "blue" }
        default { "lightgrey" }
    }

    $url = "https://img.shields.io/badge/License-$encodedLicense-$color.svg"
    $link = "https://github.com/$Username/$Repo/blob/main/LICENSE"

    return @{
        ImageUrl = $url
        Link = $link
        Alt = "License"
    }
}

function New-PackageManagerBadge {
    param(
        [string]$Manager,
        [string]$PackageName
    )

    switch ($Manager) {
        'PSGallery' {
            return @{
                ImageUrl = "https://img.shields.io/powershellgallery/v/$PackageName.svg"
                Link = "https://www.powershellgallery.com/packages/$PackageName"
                Alt = "PowerShell Gallery Version"
            }
        }
        'npm' {
            return @{
                ImageUrl = "https://img.shields.io/npm/v/$PackageName.svg"
                Link = "https://www.npmjs.com/package/$PackageName"
                Alt = "npm Version"
            }
        }
        'PyPI' {
            return @{
                ImageUrl = "https://img.shields.io/pypi/v/$PackageName.svg"
                Link = "https://pypi.org/project/$PackageName"
                Alt = "PyPI Version"
            }
        }
        'RubyGems' {
            return @{
                ImageUrl = "https://img.shields.io/gem/v/$PackageName.svg"
                Link = "https://rubygems.org/gems/$PackageName"
                Alt = "Gem Version"
            }
        }
        'Crates' {
            return @{
                ImageUrl = "https://img.shields.io/crates/v/$PackageName.svg"
                Link = "https://crates.io/crates/$PackageName"
                Alt = "Crates.io Version"
            }
        }
        'Go' {
            return @{
                ImageUrl = "https://img.shields.io/github/v/tag/$PackageName.svg?label=go"
                Link = "https://pkg.go.dev/$PackageName"
                Alt = "Go Version"
            }
        }
    }
}

function New-CodeQualityBadge {
    param(
        [string]$Service,
        [string]$Username,
        [string]$Repo,
        [string]$ProjectId = ""
    )

    switch ($Service) {
        'Codacy' {
            if ($ProjectId) {
                return @{
                    ImageUrl = "https://api.codacy.com/project/badge/Grade/$ProjectId"
                    Link = "https://www.codacy.com/gh/$Username/$Repo"
                    Alt = "Codacy Grade"
                }
            }
        }
        'CodeClimate' {
            return @{
                ImageUrl = "https://api.codeclimate.com/v1/badges/$ProjectId/maintainability"
                Link = "https://codeclimate.com/github/$Username/$Repo/maintainability"
                Alt = "Maintainability"
            }
        }
        'Codecov' {
            return @{
                ImageUrl = "https://codecov.io/gh/$Username/$Repo/branch/main/graph/badge.svg"
                Link = "https://codecov.io/gh/$Username/$Repo"
                Alt = "Code Coverage"
            }
        }
    }
}

function New-DonateBadge {
    param(
        [string]$Service,
        [string]$Username
    )

    switch ($Service) {
        'PayPal' {
            return @{
                ImageUrl = "https://img.shields.io/badge/Donate-PayPal-green.svg"
                Link = "https://paypal.me/$Username"
                Alt = "Donate via PayPal"
            }
        }
        'GitHub' {
            return @{
                ImageUrl = "https://img.shields.io/badge/Sponsor-GitHub-pink.svg"
                Link = "https://github.com/sponsors/$Username"
                Alt = "Sponsor on GitHub"
            }
        }
    }
}

function Format-Badge {
    param(
        [hashtable]$Badge,
        [string]$Format
    )

    switch ($Format) {
        'Markdown' {
            return "[![$($Badge.Alt)]($($Badge.ImageUrl))]($($Badge.Link))"
        }
        'HTML' {
            return "<a href=`"$($Badge.Link)`"><img src=`"$($Badge.ImageUrl)`" alt=`"$($Badge.Alt)`"></a>"
        }
        'AsciiDoc' {
            return "image:$($Badge.ImageUrl)[$($Badge.Alt), link=`"$($Badge.Link)`"]"
        }
    }
}

# Main execution
Write-Host ""
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "  GitHub Template Badge Generator" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

$badges = @()

# Generate license badge
Write-Host "Generating License badge..." -ForegroundColor Green
$licenseBadge = New-LicenseBadge -License $License -Username $GitHubUsername -Repo $RepositoryName
$badges += $licenseBadge
Write-Host "  $(Format-Badge -Badge $licenseBadge -Format $OutputFormat)"

# Generate GitHub Actions badge
Write-Host ""
Write-Host "Generating GitHub Actions badge..." -ForegroundColor Green
$actionsBadge = New-GitHubActionsBadge -Username $GitHubUsername -Repo $RepositoryName
$badges += $actionsBadge
Write-Host "  $(Format-Badge -Badge $actionsBadge -Format $OutputFormat)"

# Generate package manager badge if specified
if ($PackageManager -ne 'None' -and $PackageName) {
    Write-Host ""
    Write-Host "Generating $PackageManager badge..." -ForegroundColor Green
    $packageBadge = New-PackageManagerBadge -Manager $PackageManager -PackageName $PackageName
    if ($packageBadge) {
        $badges += $packageBadge
        Write-Host "  $(Format-Badge -Badge $packageBadge -Format $OutputFormat)"
    }
}

# Generate code coverage badge
Write-Host ""
Write-Host "Generating Code Coverage badge (Codecov)..." -ForegroundColor Green
$codecovBadge = New-CodeQualityBadge -Service 'Codecov' -Username $GitHubUsername -Repo $RepositoryName
if ($codecovBadge) {
    $badges += $codecovBadge
    Write-Host "  $(Format-Badge -Badge $codecovBadge -Format $OutputFormat)"
}

# Generate donate badge
Write-Host ""
Write-Host "Generating Donate badge (PayPal)..." -ForegroundColor Green
$donateBadge = New-DonateBadge -Service 'PayPal' -Username $GitHubUsername
if ($donateBadge) {
    $badges += $donateBadge
    Write-Host "  $(Format-Badge -Badge $donateBadge -Format $OutputFormat)"
}

# Display all badges together
Write-Host ""
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "  All Badges ($OutputFormat format)" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

foreach ($badge in $badges) {
    Write-Host (Format-Badge -Badge $badge -Format $OutputFormat)
}

# Update README if requested
if ($UpdateReadme) {
    Write-Host ""
    Write-Host "======================================================" -ForegroundColor Yellow
    Write-Host "  Updating README.md" -ForegroundColor Yellow
    Write-Host "======================================================" -ForegroundColor Yellow

    if (-not (Test-Path 'README.md')) {
        Write-Host "ERROR: README.md not found in current directory" -ForegroundColor Red
        exit 1
    }

    $readme = Get-Content 'README.md' -Raw

    # Create badges section
    $badgeSection = ""
    foreach ($badge in $badges) {
        $badgeSection += (Format-Badge -Badge $badge -Format $OutputFormat) + " "
    }
    $badgeSection = $badgeSection.TrimEnd()

    # Try to find and replace existing badges section
    $badgeMarkerStart = "<!-- BADGES:START -->"
    $badgeMarkerEnd = "<!-- BADGES:END -->"

    if ($readme -match [regex]::Escape($badgeMarkerStart)) {
        Write-Host "Found existing badge markers, updating badges..." -ForegroundColor Green

        $pattern = "(?s)$([regex]::Escape($badgeMarkerStart)).*?$([regex]::Escape($badgeMarkerEnd))"
        $replacement = "$badgeMarkerStart`n$badgeSection`n$badgeMarkerEnd"
        $readme = $readme -replace $pattern, $replacement

        Set-Content -Path 'README.md' -Value $readme -NoNewline
        Write-Host "SUCCESS: Badges updated in README.md" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "No badge markers found in README.md" -ForegroundColor Yellow
        Write-Host "Add these markers to your README where you want badges to appear:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  <!-- BADGES:START -->" -ForegroundColor Cyan
        Write-Host "  <!-- BADGES:END -->" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Then run this script again with -UpdateReadme" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "  Optional Badges" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "You can also add these badges manually:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Code Quality (Codacy):" -ForegroundColor Green
Write-Host "  Requires project ID from Codacy dashboard"
Write-Host "  [![Codacy Badge](https://api.codacy.com/project/badge/Grade/YOUR-PROJECT-ID)](https://www.codacy.com/gh/$GitHubUsername/$RepositoryName)"
Write-Host ""
Write-Host "Code Quality (Code Climate):" -ForegroundColor Green
Write-Host "  Requires project ID from Code Climate dashboard"
Write-Host "  [![Maintainability](https://api.codeclimate.com/v1/badges/YOUR-PROJECT-ID/maintainability)](https://codeclimate.com/github/$GitHubUsername/$RepositoryName)"
Write-Host ""
Write-Host "GitHub Sponsors:" -ForegroundColor Green
$sponsorBadge = New-DonateBadge -Service 'GitHub' -Username $GitHubUsername
Write-Host "  $(Format-Badge -Badge $sponsorBadge -Format $OutputFormat)"
Write-Host ""
Write-Host "Downloads (for package managers):" -ForegroundColor Green
if ($PackageManager -eq 'PSGallery' -and $PackageName) {
    Write-Host "  [![PowerShell Gallery Downloads](https://img.shields.io/powershellgallery/dt/$PackageName.svg)](https://www.powershellgallery.com/packages/$PackageName)"
} elseif ($PackageManager -eq 'npm' -and $PackageName) {
    Write-Host "  [![npm Downloads](https://img.shields.io/npm/dm/$PackageName.svg)](https://www.npmjs.com/package/$PackageName)"
} else {
    Write-Host "  Specify -PackageManager and -PackageName to see download badges"
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
Write-Host ""
