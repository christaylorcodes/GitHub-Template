#requires -Version 7.2

<#
.SYNOPSIS
Scaffolds a new PowerShell function from template

.DESCRIPTION
Creates a new function file in the Public or Private folder using the appropriate template.
Also creates a corresponding Pester test file.

.PARAMETER FunctionName
The name of the function to create (must follow Verb-Noun format)

.PARAMETER Type
Whether to create a Public (exported) or Private (internal) function

.PARAMETER Author
The author name to include in the function header

.EXAMPLE
.\Scripts\New-Function.ps1 -FunctionName Get-MyData -Type Public -Author "John Doe"

Creates a new public function Get-MyData.ps1 with corresponding test file

.EXAMPLE
.\Scripts\New-Function.ps1 -FunctionName ConvertTo-InternalFormat -Type Private

Creates a new private helper function
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Z][a-z]+-[A-Z]')]
    [string]$FunctionName,

    [Parameter(Mandatory = $true)]
    [ValidateSet('Public', 'Private')]
    [string]$Type,

    [Parameter(Mandatory = $false)]
    [string]$Author = ($env:USERNAME ?? $env:USER ?? 'Unknown'),

    [Parameter(Mandatory = $false)]
    [string]$ModuleName,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Replace the 'ModuleName' placeholder as a whole token only, so Pester's
# -ModuleName parameter and $ModuleName variables are not rewritten
function Set-ModuleNameToken([string]$Content, [string]$Name) {
    [regex]::Replace($Content, '(?<![-$:A-Za-z0-9])ModuleName(?![A-Za-z0-9])',
        [System.Text.RegularExpressions.MatchEvaluator] { param($m) $Name })
}

# Get project root
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$TemplatesPath = Join-Path $ProjectRoot 'Templates'
$SourcePath = Join-Path $ProjectRoot 'source'
$TestsPath = Join-Path $ProjectRoot 'Tests'

# Determine module name if not specified
if (-not $ModuleName) {
    $ManifestFile = Get-ChildItem -Path $SourcePath -Filter '*.psd1' | Select-Object -First 1
    if ($ManifestFile) {
        $ModuleName = $ManifestFile.BaseName
    }
    else {
        $ModuleName = 'ModuleName'
    }
}

# Validate function name follows approved verbs
$Verb = ($FunctionName -split '-')[0]
$ApprovedVerbs = Get-Verb | Select-Object -ExpandProperty Verb
if ($Verb -notin $ApprovedVerbs) {
    Write-Warning "The verb '$Verb' is not in the approved verb list."
    Write-Host "Approved verbs can be found with: Get-Verb"
    if (-not $Force) {
        $Continue = Read-Host "Do you want to continue anyway? (y/n)"
        if ($Continue -ne 'y') {
            return
        }
    }
    else {
        Write-Host "Continuing due to -Force parameter." -ForegroundColor Yellow
    }
}

# Determine paths
$FunctionPath = Join-Path $SourcePath $Type
$FunctionFile = Join-Path $FunctionPath "$FunctionName.ps1"

# Check if function already exists
if (Test-Path $FunctionFile) {
    Write-Error "Function already exists at: $FunctionFile"
    return
}

# Select template
$TemplateFile = if ($Type -eq 'Public') {
    Join-Path $TemplatesPath 'Function.ps1'
}
else {
    Join-Path $TemplatesPath 'PrivateFunction.ps1'
}

if (-not (Test-Path $TemplateFile)) {
    Write-Error "Template file not found: $TemplateFile"
    return
}

# Read template
$TemplateContent = Get-Content $TemplateFile -Raw

# Replace placeholders
$FunctionContent = $TemplateContent.Replace('Verb-Noun', $FunctionName)
$FunctionContent = $FunctionContent.Replace('ConvertTo-InternalFormat', $FunctionName)
$FunctionContent = $FunctionContent.Replace('Your Name', $Author)
$FunctionContent = $FunctionContent.Replace('YYYY-MM-DD', (Get-Date -Format 'yyyy-MM-dd'))
$FunctionContent = Set-ModuleNameToken $FunctionContent $ModuleName

# Create function file (UTF-8 with BOM, per project convention)
Write-Host "Creating function file: $FunctionFile" -ForegroundColor Green
$FunctionContent | Out-File -FilePath $FunctionFile -Encoding utf8BOM -NoNewline

# Create test file
$TestSubfolder = if ($Type -eq 'Public') { 'Public' } else { 'Private' }
$TestPath = Join-Path $TestsPath 'Unit' $TestSubfolder
$TestFile = Join-Path $TestPath "$FunctionName.Tests.ps1"

if (-not (Test-Path $TestPath)) {
    $null = New-Item -Path $TestPath -ItemType Directory -Force
}

if (-not (Test-Path $TestFile)) {
    $TestTemplateName = if ($Type -eq 'Public') { 'Test.Tests.ps1' } else { 'PrivateTest.Tests.ps1' }
    $TestTemplate = Join-Path $TemplatesPath $TestTemplateName
    if (Test-Path $TestTemplate) {
        $TestContent = Get-Content $TestTemplate -Raw
        $TestContent = $TestContent.Replace('Verb-Noun', $FunctionName)
        $TestContent = $TestContent.Replace('ConvertTo-InternalFormat', $FunctionName)
        $TestContent = Set-ModuleNameToken $TestContent $ModuleName

        Write-Host "Creating test file: $TestFile" -ForegroundColor Green
        $TestContent | Out-File -FilePath $TestFile -Encoding utf8BOM -NoNewline
    }
}

Write-Host ""
Write-Host "Successfully created function: $FunctionName" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Edit the function: $FunctionFile"
Write-Host "2. Implement the function logic"
Write-Host "3. Update the test file: $TestFile"
Write-Host "4. Quick test: .\Scripts\Invoke-QuickTest.ps1 -FunctionName $FunctionName -IncludeAnalyzer"
Write-Host "5. Full validation: .\Tests\test-local.ps1"
Write-Host ""
