<#
.SYNOPSIS
    Initializes a new repository from the GitHub Template.

.DESCRIPTION
    This script automates the customization of the GitHub Template repository.
    It replaces all placeholder values with your project-specific information,
    renames module files, populates the module manifest, updates documentation,
    cleans up template-specific files, and optionally initializes a new git repository.

.PARAMETER Name
    The name of your project (e.g., "MyAwesomeProject")

.PARAMETER Description
    A brief description of your project

.PARAMETER Author
    The author/maintainer name (e.g., "John Doe")

.PARAMETER GitHubUsername
    Your GitHub username (e.g., "johndoe")

.PARAMETER ModuleName
    The PowerShell module name (if applicable). Defaults to Name parameter.

.PARAMETER CompanyName
    The company or vendor name. Defaults to the Author parameter.

.PARAMETER RepositoryName
    The GitHub repository name (if different from Name). Defaults to Name parameter.

.PARAMETER License
    License type. Default: "MIT"

.PARAMETER InitializeGit
    If specified, initializes a new git repository and creates initial commit

.PARAMETER SkipDonation
    If specified, removes donation-related content from the repository

.EXAMPLE
    .\Initialize-Repository.ps1 -Name "MyProject" -Description "An awesome tool" -Author "John Doe" -GitHubUsername "johndoe"

.EXAMPLE
    .\Initialize-Repository.ps1 -Name "PowerShellModule" -Description "A PowerShell module" -Author "Jane Smith" -GitHubUsername "janesmith" -InitializeGit

.NOTES
    Author: Chris Taylor
    Date: 2025-11-04
    Version: 1.1.0
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
    [string]$GitHubUsername,

    [Parameter(Mandatory = $false)]
    [string]$ModuleName = $Name,

    [Parameter(Mandatory = $false)]
    [string]$CompanyName = $Author,

    [Parameter(Mandatory = $false)]
    [string]$RepositoryName = $Name,

    [Parameter(Mandatory = $false)]
    [string]$License = "MIT",

    [Parameter(Mandatory = $false)]
    [switch]$InitializeGit,

    [Parameter(Mandatory = $false)]
    [switch]$SkipDonation
)

# Script configuration
$ErrorActionPreference = 'Stop'
$CurrentYear = (Get-Date).Year
$ModuleGuid = [guid]::NewGuid().ToString()

# Validate module name
if ($ModuleName -notmatch '^[A-Za-z][A-Za-z0-9._-]*$') {
    throw ("Invalid module name '$ModuleName'. Must start with a letter " +
        "and contain only letters, digits, dots, underscores, and hyphens.")
}

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

# Validate we're in the template directory
Write-Step "Validating Environment"
if (-not (Test-Path ".\README.md") -or -not (Test-Path ".\.github\CONTRIBUTING.md")) {
    throw "This script must be run from the root of the GitHub-Template repository."
}
Write-Success "Template directory validated"

# Update README.md
Write-Step "Customizing README.md"
$readme = Get-Content ".\README.md" -Raw

# Replace placeholders
$readme = $readme -replace 'GitHub Template', $Name
$readme = $readme -replace 'YOUR-USERNAME', $GitHubUsername
$readme = $readme -replace 'YOUR-REPO', $RepositoryName
$readme = $readme -replace 'YOUR-PROJECT', $Name
$readme = $readme -replace 'YOUR-PACKAGE', $ModuleName
$readme = $readme -replace 'YourModuleName', $ModuleName
$readme = $readme -replace 'christaylorcodes/GitHub-Template', "$GitHubUsername/$RepositoryName"

if ($PSCmdlet.ShouldProcess('README.md', 'Replace placeholders')) {
    Set-Content -Path ".\README.md" -Value $readme -NoNewline
    Write-Success "README.md customized"
}

# Update CONTRIBUTING.md
Write-Step "Customizing CONTRIBUTING.md"
$contributing = Get-Content ".\.github\CONTRIBUTING.md" -Raw
$contributing = $contributing -replace "Chris Taylor Codes", $Name
$contributing = $contributing -replace 'christaylorcodes/GitHub-Template', "$GitHubUsername/$RepositoryName"
if ($PSCmdlet.ShouldProcess('CONTRIBUTING.md', 'Replace placeholders')) {
    Set-Content -Path ".\.github\CONTRIBUTING.md" -Value $contributing -NoNewline
    Write-Success "CONTRIBUTING.md customized"
}

# Update AGENTS.md
Write-Step "Customizing AGENTS.md"
if (Test-Path ".\AGENTS.md") {
    $agents = Get-Content ".\AGENTS.md" -Raw
    $agents = $agents -replace 'YOUR-USERNAME', $GitHubUsername
    $agents = $agents -replace 'YOUR-REPO', $RepositoryName
    $agents = $agents -replace 'ModuleName', $ModuleName
    # Strip the Template Development section (template-only content)
    $agents = $agents -replace '(?s)\r?\n## Template Development.*$', ''
    if ($PSCmdlet.ShouldProcess('AGENTS.md', 'Replace placeholders')) {
        Set-Content -Path ".\AGENTS.md" -Value $agents -NoNewline
        Write-Success "AGENTS.md customized (template section removed)"
    }
}

# Update CLAUDE.md
Write-Step "Customizing CLAUDE.md"
if (Test-Path ".\CLAUDE.md") {
    $claude = Get-Content ".\CLAUDE.md" -Raw
    $claude = $claude -replace 'YOUR-USERNAME', $GitHubUsername
    $claude = $claude -replace 'YOUR-REPO', $RepositoryName
    if ($PSCmdlet.ShouldProcess('CLAUDE.md', 'Replace placeholders')) {
        Set-Content -Path ".\CLAUDE.md" -Value $claude -NoNewline
        Write-Success "CLAUDE.md customized"
    }
}

# Update copilot-instructions.md
Write-Step "Customizing copilot-instructions.md"
$copilotFile = ".\.github\copilot-instructions.md"
if (Test-Path $copilotFile) {
    $copilot = Get-Content $copilotFile -Raw
    $copilot = $copilot -replace 'YOUR-USERNAME', $GitHubUsername
    $copilot = $copilot -replace 'YOUR-REPO', $RepositoryName
    if ($PSCmdlet.ShouldProcess('copilot-instructions.md', 'Replace placeholders')) {
        Set-Content -Path $copilotFile -Value $copilot -NoNewline
        Write-Success "copilot-instructions.md customized"
    }
}

# Update issue template config
Write-Step "Customizing Issue Template Config"
$configFile = ".\.github\ISSUE_TEMPLATE\config.yml"
if (Test-Path $configFile) {
    $config = Get-Content $configFile -Raw
    $config = $config -replace 'christaylorcodes/GitHub-Template', "$GitHubUsername/$RepositoryName"
    if ($PSCmdlet.ShouldProcess('config.yml', 'Replace placeholders')) {
        Set-Content -Path $configFile -Value $config -NoNewline
        Write-Success "Issue template config customized"
    }
}

# Update LICENSE
Write-Step "Customizing LICENSE"
$license = Get-Content ".\LICENSE" -Raw
$license = $license -replace '2021', $CurrentYear
$license = $license -replace 'Chris Taylor', $Author
if ($PSCmdlet.ShouldProcess('LICENSE', 'Replace year and author')) {
    Set-Content -Path ".\LICENSE" -Value $license -NoNewline
    Write-Success "LICENSE customized"
}

# Update CHANGELOG.md
Write-Step "Customizing CHANGELOG.md"
if (Test-Path ".\CHANGELOG.md") {
    $changelog = Get-Content ".\CHANGELOG.md" -Raw
    $changelog = $changelog -replace 'YOUR-USERNAME', $GitHubUsername
    $changelog = $changelog -replace 'YOUR-REPO', $RepositoryName
    if ($PSCmdlet.ShouldProcess('CHANGELOG.md', 'Replace placeholders')) {
        Set-Content -Path ".\CHANGELOG.md" -Value $changelog -NoNewline
        Write-Success "CHANGELOG.md customized"
    }
}

# Update SECURITY.md
Write-Step "Customizing SECURITY.md"
if (Test-Path ".\.github\SECURITY.md") {
    $security = Get-Content ".\.github\SECURITY.md" -Raw
    $security = $security -replace 'christaylorcodes/GitHub-Template', "$GitHubUsername/$RepositoryName"
    $security = $security -replace 'christaylor\.codes', "yourdomain.com"
    if ($PSCmdlet.ShouldProcess('SECURITY.md', 'Replace placeholders')) {
        Set-Content -Path ".\.github\SECURITY.md" -Value $security -NoNewline
        Write-Info "SECURITY.md updated - review contact emails"
    }
}

# Update CODE_OF_CONDUCT.md
Write-Step "Customizing CODE_OF_CONDUCT.md"
if (Test-Path ".\.github\CODE_OF_CONDUCT.md") {
    $coc = Get-Content ".\.github\CODE_OF_CONDUCT.md" -Raw
    $coc = $coc -replace 'christaylor\.codes', "yourdomain.com"
    if ($PSCmdlet.ShouldProcess('CODE_OF_CONDUCT.md', 'Replace placeholders')) {
        Set-Content -Path ".\.github\CODE_OF_CONDUCT.md" -Value $coc -NoNewline
        Write-Info "CODE_OF_CONDUCT.md updated - review contact emails"
    }
}

# Update module manifest
Write-Step "Customizing Module Source Files"
$manifestFile = ".\source\ModuleName.psd1"
if (Test-Path $manifestFile) {
    $manifest = Get-Content $manifestFile -Raw
    $guidPattern = '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'
    $manifest = $manifest -replace $guidPattern, $ModuleGuid
    $manifest = $manifest -replace 'YOUR-USERNAME', $GitHubUsername
    $manifest = $manifest -replace 'Your Name', $Author
    $manifest = $manifest -replace 'Your Company', $CompanyName
    $manifest = $manifest -replace 'Brief description of what this module does', $Description
    $manifest = $manifest -replace '\(c\) \d{4} Your Name', "(c) $CurrentYear $Author"
    $manifest = $manifest -replace 'ModuleName', $ModuleName
    # Update URIs with repository name (may differ from module name)
    $manifest = $manifest -replace "/$([regex]::Escape($ModuleName))/blob/main/", "/$RepositoryName/blob/main/"
    $manifest = $manifest -replace "/$([regex]::Escape($ModuleName))/main/docs/media/", "/$RepositoryName/main/docs/media/"
    $manifest = $manifest -replace "/$([regex]::Escape($ModuleName))'", "/$RepositoryName'"
    if ($PSCmdlet.ShouldProcess('Module manifest', 'Replace placeholders and generate GUID')) {
        Set-Content -Path $manifestFile -Value $manifest -NoNewline
        Write-Success "Module manifest customized (GUID: $ModuleGuid)"
    }
}

# Update example function
$exampleFunction = ".\source\Public\Get-ModuleInfo.ps1"
if (Test-Path $exampleFunction) {
    $content = Get-Content $exampleFunction -Raw
    $content = $content -replace 'YOUR-USERNAME', $GitHubUsername
    $content = $content -replace 'Your Name', $Author
    $content = $content -replace 'ModuleName', $ModuleName
    if ($PSCmdlet.ShouldProcess('Get-ModuleInfo.ps1', 'Replace placeholders')) {
        Set-Content -Path $exampleFunction -Value $content -NoNewline
        Write-Success "Example function customized"
    }
}

# Update root module file
$rootModule = ".\source\ModuleName.psm1"
if (Test-Path $rootModule) {
    $content = Get-Content $rootModule -Raw
    $content = $content -replace 'Your Name', $Author
    $content = $content -replace 'ModuleName', $ModuleName
    if ($PSCmdlet.ShouldProcess("$ModuleName.psm1", 'Replace placeholders')) {
        Set-Content -Path $rootModule -Value $content -NoNewline
        Write-Success "Root module file customized"
    }
}

# Update test files
$testFile = ".\Tests\Unit\Public\Get-ModuleInfo.Tests.ps1"
if (Test-Path $testFile) {
    $content = Get-Content $testFile -Raw
    $content = $content -replace 'ModuleName', $ModuleName
    if ($PSCmdlet.ShouldProcess('Get-ModuleInfo.Tests.ps1', 'Replace placeholders')) {
        Set-Content -Path $testFile -Value $content -NoNewline
        Write-Success "Test file customized"
    }
}

# Update TestHelper module
$testHelper = ".\Tests\TestHelpers\TestHelper.psm1"
if (Test-Path $testHelper) {
    $content = Get-Content $testHelper -Raw
    $content = $content -replace 'ModuleName', $ModuleName
    if ($PSCmdlet.ShouldProcess('TestHelper.psm1', 'Replace placeholders')) {
        Set-Content -Path $testHelper -Value $content -NoNewline
        Write-Success "TestHelper.psm1 customized"
    }
}

# Update module health tests
$moduleTest = ".\Tests\Unit\Module\ModuleName.Module.Tests.ps1"
if (Test-Path $moduleTest) {
    $content = Get-Content $moduleTest -Raw
    $content = $content -replace 'ModuleName', $ModuleName
    if ($PSCmdlet.ShouldProcess('Module health tests', 'Replace placeholders and rename')) {
        Set-Content -Path $moduleTest -Value $content -NoNewline
        $newModuleTestName = "$ModuleName.Module.Tests.ps1"
        if ("ModuleName.Module.Tests.ps1" -ne $newModuleTestName) {
            Rename-Item -Path $moduleTest -NewName $newModuleTestName
        }
        Write-Success "Module health tests customized"
    }
}

# Update templates
Write-Step "Customizing Templates"
$templateFiles = @(
    ".\Templates\Function.ps1"
    ".\Templates\PrivateFunction.ps1"
    ".\Templates\Test.Tests.ps1"
    ".\Templates\PrivateTest.Tests.ps1"
    ".\Templates\IntegrationTest.Tests.ps1"
)
foreach ($templateFile in $templateFiles) {
    if (Test-Path $templateFile) {
        $content = Get-Content $templateFile -Raw
        $content = $content -replace 'YOUR-USERNAME', $GitHubUsername
        $content = $content -replace 'YOUR-REPO', $RepositoryName
        $content = $content -replace 'Your Name', $Author
        $content = $content -replace 'yourusername', $GitHubUsername
        $content = $content -replace 'ModuleName', $ModuleName
        $leafName = Split-Path -Leaf $templateFile
        if ($PSCmdlet.ShouldProcess($leafName, 'Replace placeholders')) {
            Set-Content -Path $templateFile -Value $content -NoNewline
            Write-Success "$leafName customized"
        }
    }
}

# Update about topic
$aboutTopic = ".\docs\en-US\about_ModuleName.help.txt"
if (Test-Path $aboutTopic) {
    $content = Get-Content $aboutTopic -Raw
    $content = $content -replace 'YOUR-USERNAME', $GitHubUsername
    $content = $content -replace 'ModuleName', $ModuleName
    if ($PSCmdlet.ShouldProcess('about_ModuleName.help.txt', 'Replace placeholders and rename')) {
        Set-Content -Path $aboutTopic -Value $content -NoNewline
        $newAboutName = "about_$ModuleName.help.txt"
        if ("about_ModuleName.help.txt" -ne $newAboutName) {
            Rename-Item -Path $aboutTopic -NewName $newAboutName
        }
        Write-Success "About topic customized"
    }
}

# Update additional documentation files
Write-Step "Customizing Documentation Files"
$additionalDocs = @(
    ".\docs\PUBLISHING.md"
    ".\docs\examples\Example-BasicUsage.ps1"
)
foreach ($docFile in $additionalDocs) {
    if (Test-Path $docFile) {
        $content = Get-Content $docFile -Raw
        $content = $content -replace 'YOUR-USERNAME', $GitHubUsername
        $content = $content -replace 'Your Name', $Author
        $content = $content -replace 'Your Company', $CompanyName
        $content = $content -replace 'yourusername', $GitHubUsername
        $content = $content -replace 'ModuleName', $ModuleName
        $leafName = Split-Path -Leaf $docFile
        if ($PSCmdlet.ShouldProcess($leafName, 'Replace placeholders')) {
            Set-Content -Path $docFile -Value $content -NoNewline
            Write-Success "$leafName customized"
        }
    }
}

# Update New-Function.ps1 helper script
$newFuncScript = ".\Scripts\New-Function.ps1"
if (Test-Path $newFuncScript) {
    $content = Get-Content $newFuncScript -Raw
    $content = $content -replace 'Your Name', $Author
    $content = $content -replace 'yourusername', $GitHubUsername
    if ($PSCmdlet.ShouldProcess('New-Function.ps1', 'Replace placeholders')) {
        Set-Content -Path $newFuncScript -Value $content -NoNewline
        Write-Success "New-Function.ps1 customized"
    }
}

# Update USAGE.md
$usageDoc = ".\docs\USAGE.md"
if (Test-Path $usageDoc) {
    $content = Get-Content $usageDoc -Raw
    $content = $content -replace 'YOUR-USERNAME', $GitHubUsername
    $content = $content -replace 'yourusername', $GitHubUsername
    $content = $content -replace 'ModuleName', $ModuleName
    if ($PSCmdlet.ShouldProcess('USAGE.md', 'Replace placeholders')) {
        Set-Content -Path $usageDoc -Value $content -NoNewline
        Write-Success "USAGE.md customized"
    }
}

# Rename module files
Write-Step "Renaming Module Files"
$fileRenames = @(
    @{ Source = ".\source\ModuleName.psd1"; Target = "$ModuleName.psd1" }
    @{ Source = ".\source\ModuleName.psm1"; Target = "$ModuleName.psm1" }
)
foreach ($rename in $fileRenames) {
    $sourceName = Split-Path -Leaf $rename.Source
    if ((Test-Path $rename.Source) -and ($sourceName -ne $rename.Target)) {
        if ($PSCmdlet.ShouldProcess($sourceName, "Rename to $($rename.Target)")) {
            Rename-Item -Path $rename.Source -NewName $rename.Target
            Write-Success "Renamed $sourceName -> $($rename.Target)"
        }
    }
}

# Handle donation files
if ($SkipDonation) {
    Write-Step "Removing Donation Content"
    if ($PSCmdlet.ShouldProcess('Donation files', 'Remove')) {
        if (Test-Path ".\docs\DONATE.md") {
            Remove-Item ".\docs\DONATE.md" -Force
        }
        foreach ($donationFile in @('.\docs\media\BTC.png', '.\docs\media\BTC.txt',
                '.\docs\media\ETH.png', '.\docs\media\ETH.txt')) {
            if (Test-Path $donationFile) {
                Remove-Item $donationFile -Force
            }
        }
        Write-Success "Donation files removed"

        # Remove donation badge from README
        $readme = Get-Content ".\README.md" -Raw
        $donatePattern = '\[\!\[Donate\].*?\]\(.*?DONATE\.md\)\r?\n?'
        $readme = $readme -replace $donatePattern, ''
        Set-Content -Path ".\README.md" -Value $readme -NoNewline
        Write-Success "Donation badge removed from README"
    }
} else {
    Write-Step "Customizing DONATE.md"
    if (Test-Path ".\docs\DONATE.md") {
        $donate = Get-Content ".\docs\DONATE.md" -Raw
        $donate = $donate -replace 'christaylorcodes', $GitHubUsername
        if ($PSCmdlet.ShouldProcess('DONATE.md', 'Replace placeholders')) {
            Set-Content -Path ".\docs\DONATE.md" -Value $donate -NoNewline
            Write-Success "DONATE.md customized"
        }
        Write-Caution "Remember to update donation wallet addresses and QR codes in .\docs\media\"
    }
}

# Clean up template-specific files
Write-Step "Cleaning Template Files"
$filesToRemove = @(
    ".\Scripts\Test-Template.ps1"
    ".\Scripts\New-TemplateBadges.ps1"
    ".\docs\TEMPLATE_USAGE.md"
    ".\docs\TEMPLATE_DEVELOPMENT.md"
    $MyInvocation.MyCommand.Definition
)

foreach ($file in $filesToRemove) {
    if (Test-Path $file) {
        if ($PSCmdlet.ShouldProcess($file, 'Remove template file')) {
            Remove-Item -Path $file -Force
            Write-Success "Removed $file"
        }
    }
}

# Rename AI_SETUP_GUIDE.md to CUSTOMIZATION_GUIDE.md (keep as post-init reference)
$setupGuide = ".\docs\AI_SETUP_GUIDE.md"
if (Test-Path $setupGuide) {
    if ($PSCmdlet.ShouldProcess('AI_SETUP_GUIDE.md', 'Rename to CUSTOMIZATION_GUIDE.md')) {
        Rename-Item -Path $setupGuide -NewName "CUSTOMIZATION_GUIDE.md"
        Write-Success "AI_SETUP_GUIDE.md renamed to CUSTOMIZATION_GUIDE.md"
    }
}

# Set up .claude/ directory for AI agent sessions
if (-not (Test-Path ".\.claude")) {
    New-Item -ItemType Directory -Path ".\.claude" | Out-Null
}
# Remove template-specific .claude/ content
if (Test-Path ".\.claude\plans") {
    if ($PSCmdlet.ShouldProcess('.claude/plans/', 'Remove template plans')) {
        Remove-Item ".\.claude\plans" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Success "Template plans removed"
    }
}
foreach ($cmd in @('plan.md', 'interview.md', 'brainstorm.md')) {
    $cmdPath = ".\.claude\commands\$cmd"
    if (Test-Path $cmdPath) {
        if ($PSCmdlet.ShouldProcess($cmdPath, 'Remove template command')) {
            Remove-Item $cmdPath -Force
        }
    }
}

# Initialize Git repository
if ($InitializeGit) {
    Write-Step "Initializing Git Repository"

    # Check if .git already exists
    if (Test-Path ".\.git") {
        Write-Warning "Git repository already exists. Skipping git initialization."
        Write-Info "If you want to start fresh, delete the .git directory manually first."
    } elseif ($PSCmdlet.ShouldProcess('Repository', 'Initialize git and create initial commit')) {
        # Initialize new repo
        git init
        Write-Success "Git repository initialized"

        # Add all files
        git add .
        Write-Success "Files staged for commit"

        # Create initial commit
        $commitMessage = @"
Initial commit - $Name

Project: $Name
Module: $ModuleName
Description: $Description
Author: $Author

Generated from GitHub-Template
https://github.com/christaylorcodes/GitHub-Template
"@
        git commit -m $commitMessage
        Write-Success "Initial commit created"

        Write-Info "To push to GitHub, create a repository and run:"
        $remoteUrl = "https://github.com/$GitHubUsername/$RepositoryName.git"
        Write-Host "  git remote add origin $remoteUrl" -ForegroundColor White
        Write-Host "  git branch -M main" -ForegroundColor White
        Write-Host "  git push -u origin main" -ForegroundColor White
    }
}

# Summary
Write-Step "Initialization Complete!"
Write-Host ""
Write-Success "Repository customized successfully!"
Write-Host ""
Write-Host "Project Details:" -ForegroundColor Yellow
Write-Host "  Name:        $Name"
Write-Host "  Module:      $ModuleName"
Write-Host "  Description: $Description"
Write-Host "  Author:      $Author"
Write-Host "  Company:     $CompanyName"
Write-Host "  GUID:        $ModuleGuid"
Write-Host "  GitHub:      https://github.com/$GitHubUsername/$RepositoryName"
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
$stepNum = 1
Write-Host "  $stepNum. Verify module loads: Import-Module ./source/$ModuleName.psd1 -Force"
$stepNum++
Write-Host "  $stepNum. Run build: ./build.ps1 -ResolveDependency -Tasks build"
$stepNum++
Write-Host "  $stepNum. Run tests: ./Tests/test-local.ps1"
$stepNum++
Write-Host "  $stepNum. Review and update .\README.md"
$stepNum++
Write-Host "  $stepNum. Replace .\docs\media\Logo.png with your project logo"
$stepNum++
Write-Host "  $stepNum. Replace .\docs\media\Demo.gif with your project demo"
$stepNum++
Write-Host "  $stepNum. Update badge URLs in README.md"
$stepNum++
if (-not $SkipDonation) {
    Write-Host "  $stepNum. Update donation wallet addresses in .\docs\media\"
    $stepNum++
}
Write-Host "  $stepNum. Update contact emails in .github/SECURITY.md and .github/CODE_OF_CONDUCT.md"
$stepNum++
Write-Host "  $stepNum. Review AGENTS.md and CLAUDE.md for your project"
$stepNum++
Write-Host "  $stepNum. Run .\Scripts\Initialize-Labels.ps1 to create AI workflow labels (optional)"
Write-Host ""
Write-Info "Use 'git checkout -- .' to undo changes (if repo was cloned)"
Write-Info "Run /customize in Claude Code for guided project setup"
Write-Host ""
Write-Success "Happy coding!"
