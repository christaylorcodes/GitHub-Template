#requires -Version 7.2

<#
.SYNOPSIS
    Shared test helper module for Pester tests.

.DESCRIPTION
    Provides common functions for module import, path discovery, and test setup.
    Import this module in every test file instead of duplicating path-navigation logic.

    Supports two modes:
    - Built module: imports from output/ (when running via ./build.ps1 -Tasks test)
    - Source module: imports from source/ (when running via Invoke-QuickTest.ps1)

.EXAMPLE
    # In a test file's BeforeAll block:
    $testDir = $PSScriptRoot
    while ($testDir -and !(Test-Path (Join-Path $testDir 'TestHelpers/TestHelper.psm1'))) {
        $testDir = Split-Path -Parent $testDir
    }
    Import-Module (Join-Path $testDir 'TestHelpers/TestHelper.psm1') -Force
    $null = Initialize-TestModule
#>

# Compute project root: TestHelper.psm1 is at Tests/TestHelpers/
$script:ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$script:SourcePath = Join-Path $script:ProjectRoot 'source'

# Discover module name from the manifest file in source/
$script:ModuleName = (
    Get-ChildItem -Path $script:SourcePath -Filter '*.psd1' -ErrorAction SilentlyContinue |
    Select-Object -First 1
).BaseName

if (-not $script:ModuleName) {
    $script:ModuleName = 'ModuleName'
}

# Check for built module in output/ (produced by ./build.ps1 -Tasks build)
# Falls back to source manifest when no build output exists (e.g., Invoke-QuickTest.ps1)
$builtModulePattern = Join-Path $script:ProjectRoot "output/$script:ModuleName/*/$script:ModuleName.psd1"
$script:BuiltModuleManifest = Get-ChildItem -Path $builtModulePattern -ErrorAction SilentlyContinue |
    Sort-Object { [version](Split-Path (Split-Path $_.FullName -Parent) -Leaf) } -Descending |
    Select-Object -First 1

$script:UseBuiltModule = $null -ne $script:BuiltModuleManifest

function Get-ProjectRoot {
    <#
    .SYNOPSIS
        Returns the project root directory path.
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param()

    return $script:ProjectRoot
}

function Get-ModuleManifestPath {
    <#
    .SYNOPSIS
        Returns the full path to the module manifest (.psd1) file.
        Prefers the built module in output/ if available, otherwise falls back to source/.
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param()

    if ($script:UseBuiltModule) {
        return $script:BuiltModuleManifest.FullName
    }

    $manifestPath = Join-Path $script:SourcePath "$($script:ModuleName).psd1"
    if (-not (Test-Path $manifestPath)) {
        throw "Module manifest not found at: $manifestPath"
    }
    return $manifestPath
}

function Initialize-TestModule {
    <#
    .SYNOPSIS
        Imports the module under test, removing any previously loaded copy.

    .DESCRIPTION
        Finds the module manifest (built output or source), removes the module
        if already loaded, imports it fresh, and returns the module info object.

    .OUTPUTS
        System.Management.Automation.PSModuleInfo
    #>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSModuleInfo])]
    param()

    $manifestPath = Get-ModuleManifestPath

    # Remove if already loaded
    if (Get-Module -Name $script:ModuleName) {
        Remove-Module -Name $script:ModuleName -Force
    }

    # Import globally so the module is available in the caller's scope (not just TestHelper's)
    Import-Module $manifestPath -Force -ErrorAction Stop -PassThru -Global
}

Export-ModuleMember -Function @(
    'Get-ProjectRoot'
    'Get-ModuleManifestPath'
    'Initialize-TestModule'
)
