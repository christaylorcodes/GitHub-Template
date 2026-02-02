#requires -Version 7.2

<#
.SYNOPSIS
    Fast targeted test runner for AI agent closed-loop development.

.DESCRIPTION
    Runs Pester tests for a specific function or test file without the overhead
    of the full build pipeline. Designed for rapid write-test-fix-retest cycles.

    Does NOT build the module or compute code coverage.
    For full validation, use test-local.ps1.

.PARAMETER FunctionName
    Name of the function to test. Searches Unit/Public, Unit/Private,
    and Integration directories for a matching test file.

.PARAMETER Module
    Run only module health tests (Tests/Unit/Module/).

.PARAMETER IncludeAnalyzer
    Also run PSScriptAnalyzer on the function source file.

.PARAMETER OutputFormat
    'Human' for colored console output with clear PASS/FAIL markers (default).
    'Structured' for JSON output that AI agents can parse.

.EXAMPLE
    .\Scripts\Invoke-QuickTest.ps1 -FunctionName Get-ModuleInfo
    Quick-test a single function.

.EXAMPLE
    .\Scripts\Invoke-QuickTest.ps1 -FunctionName Get-ModuleInfo -IncludeAnalyzer -OutputFormat Structured
    Quick-test with lint check, JSON output for AI parsing.

.EXAMPLE
    .\Scripts\Invoke-QuickTest.ps1 -Module
    Run only module health tests.

.EXAMPLE
    .\Scripts\Invoke-QuickTest.ps1
    Run all tests without build or coverage overhead.
#>
[CmdletBinding(DefaultParameterSetName = 'ByFunction')]
param(
    [Parameter(ParameterSetName = 'ByFunction', Position = 0)]
    [string]$FunctionName,

    [Parameter(ParameterSetName = 'ModuleOnly')]
    [switch]$Module,

    [switch]$IncludeAnalyzer,

    [ValidateSet('Human', 'Structured')]
    [string]$OutputFormat = 'Human'
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$TestsPath = Join-Path $ProjectRoot 'Tests'
$SourcePath = Join-Path $ProjectRoot 'source'

# --- Resolve test path ---

$testFilePath = $null

if ($Module) {
    $modulePath = Join-Path $TestsPath 'Unit' 'Module'
    if (Test-Path $modulePath) {
        $testFilePath = $modulePath
    }
    else {
        if ($OutputFormat -eq 'Structured') {
            @{
                success    = $false
                totalTests = 0
                passed     = 0
                failed     = 0
                skipped    = 0
                duration   = '0s'
                failedTests     = @()
                analyzerErrors  = @()
                analyzerWarnings = @()
                summary    = 'ERROR: Module test directory not found'
            } | ConvertTo-Json -Depth 5
        }
        else {
            Write-Host "ERROR: Module test directory not found at: $modulePath" -ForegroundColor Red
        }
        exit 1
    }
}
elseif ($FunctionName) {
    # Search for test file by function name
    $searchPaths = @(
        (Join-Path $TestsPath 'Unit' 'Public' "$FunctionName.Tests.ps1"),
        (Join-Path $TestsPath 'Unit' 'Private' "$FunctionName.Tests.ps1"),
        (Join-Path $TestsPath 'Integration' "$FunctionName.Tests.ps1")
    )

    foreach ($candidate in $searchPaths) {
        if (Test-Path $candidate) {
            $testFilePath = $candidate
            break
        }
    }

    if (-not $testFilePath) {
        $searched = $searchPaths | ForEach-Object {
            $_ -replace [regex]::Escape($ProjectRoot), '.'
        }
        if ($OutputFormat -eq 'Structured') {
            @{
                success    = $false
                totalTests = 0
                passed     = 0
                failed     = 0
                skipped    = 0
                duration   = '0s'
                failedTests     = @()
                analyzerErrors  = @()
                analyzerWarnings = @()
                summary    = "ERROR: No test file found for '$FunctionName'"
            } | ConvertTo-Json -Depth 5
        }
        else {
            Write-Host "ERROR: No test file found for '$FunctionName'" -ForegroundColor Red
            Write-Host "Searched:" -ForegroundColor Yellow
            foreach ($p in $searched) {
                Write-Host "  $p" -ForegroundColor Gray
            }
        }
        exit 1
    }
}
else {
    # No function specified - run all tests
    $testFilePath = $TestsPath
}

# --- Run Pester ---

$config = New-PesterConfiguration
$config.Run.Path = $testFilePath
$config.Run.PassThru = $true
$config.CodeCoverage.Enabled = $false
$config.TestResult.Enabled = $false

if ($OutputFormat -eq 'Structured') {
    $config.Output.Verbosity = 'None'
}
else {
    $config.Output.Verbosity = 'Detailed'
}

$results = Invoke-Pester -Configuration $config

# --- Optional analyzer ---

$analyzerErrors = @()
$analyzerWarnings = @()

if ($IncludeAnalyzer -and $FunctionName) {
    $settingsFile = Join-Path $ProjectRoot '.PSScriptAnalyzerSettings.psd1'

    # Find the source file
    $sourcePaths = @(
        (Join-Path $SourcePath 'Public' "$FunctionName.ps1"),
        (Join-Path $SourcePath 'Private' "$FunctionName.ps1")
    )

    $sourceFile = $null
    foreach ($candidate in $sourcePaths) {
        if (Test-Path $candidate) {
            $sourceFile = $candidate
            break
        }
    }

    if ($sourceFile) {
        $analyzeParams = @{
            Path     = $sourceFile
            Settings = $settingsFile
        }

        if (Test-Path $settingsFile) {
            $analyzeResults = Invoke-ScriptAnalyzer @analyzeParams
        }
        else {
            $analyzeResults = Invoke-ScriptAnalyzer -Path $sourceFile
        }

        if ($analyzeResults) {
            $analyzerErrors = @($analyzeResults | Where-Object Severity -eq 'Error' | ForEach-Object {
                @{
                    rule    = $_.RuleName
                    message = $_.Message
                    line    = $_.Line
                    file    = $_.ScriptName
                }
            })
            $analyzerWarnings = @($analyzeResults | Where-Object Severity -eq 'Warning' | ForEach-Object {
                @{
                    rule    = $_.RuleName
                    message = $_.Message
                    line    = $_.Line
                    file    = $_.ScriptName
                }
            })
        }
    }
}

# --- Build output ---

$failedTests = @()
if ($results.FailedCount -gt 0) {
    $failedTests = @($results.Failed | ForEach-Object {
        $relativePath = $_.ScriptBlock.File -replace [regex]::Escape($ProjectRoot + [IO.Path]::DirectorySeparatorChar), ''
        @{
            name  = $_.Name
            block = $_.Path -join ' > '
            error = $_.ErrorRecord.DisplayErrorMessage
            file  = $relativePath
            line  = $_.ScriptBlock.StartPosition.StartLine
        }
    })
}

$totalDuration = '{0:N2}s' -f $results.Duration.TotalSeconds

$success = ($results.FailedCount -eq 0) -and ($analyzerErrors.Count -eq 0)
$summaryParts = @()
if ($results.PassedCount -gt 0) { $summaryParts += "$($results.PassedCount) passed" }
if ($results.FailedCount -gt 0) { $summaryParts += "$($results.FailedCount) failed" }
if ($results.SkippedCount -gt 0) { $summaryParts += "$($results.SkippedCount) skipped" }
$summaryText = if ($success) { "PASSED ($($summaryParts -join ', '))" } else { "FAILED ($($summaryParts -join ', '))" }

# --- Output ---

if ($OutputFormat -eq 'Structured') {
    $output = @{
        success          = $success
        totalTests       = $results.TotalCount
        passed           = $results.PassedCount
        failed           = $results.FailedCount
        skipped          = $results.SkippedCount
        duration         = $totalDuration
        failedTests      = $failedTests
        analyzerErrors   = $analyzerErrors
        analyzerWarnings = $analyzerWarnings
        summary          = $summaryText
    }
    $output | ConvertTo-Json -Depth 5
}
else {
    # Human-readable output
    $label = if ($FunctionName) { $FunctionName } elseif ($Module) { 'Module Health' } else { 'All Tests' }
    Write-Host ""
    Write-Host "=== QUICK TEST: $label ===" -ForegroundColor Cyan

    # Failed test details (Pester already showed detailed output above)
    if ($results.FailedCount -gt 0) {
        Write-Host ""
        Write-Host "FAILED TESTS:" -ForegroundColor Red
        foreach ($ft in $failedTests) {
            Write-Host "  FAILED  $($ft.name)" -ForegroundColor Red
            Write-Host "    ERROR: $($ft.error)" -ForegroundColor Yellow
            Write-Host "    FILE:  $($ft.file):$($ft.line)" -ForegroundColor Gray
        }
    }

    # Analyzer results
    if ($analyzerErrors.Count -gt 0) {
        Write-Host ""
        Write-Host "ANALYZER ERRORS:" -ForegroundColor Red
        foreach ($ae in $analyzerErrors) {
            Write-Host "  [$($ae.rule)] $($ae.message)" -ForegroundColor Red
            Write-Host "    FILE: $($ae.file):$($ae.line)" -ForegroundColor Gray
        }
    }
    if ($analyzerWarnings.Count -gt 0) {
        Write-Host ""
        Write-Host "ANALYZER WARNINGS:" -ForegroundColor Yellow
        foreach ($aw in $analyzerWarnings) {
            Write-Host "  [$($aw.rule)] $($aw.message)" -ForegroundColor Yellow
            Write-Host "    FILE: $($aw.file):$($aw.line)" -ForegroundColor Gray
        }
    }

    # Summary
    Write-Host ""
    $color = if ($success) { 'Green' } else { 'Red' }
    Write-Host "=== RESULT: $summaryText ($totalDuration) ===" -ForegroundColor $color
    Write-Host ""
}

# --- Exit code ---

if (-not $success) { exit 1 }
exit 0
