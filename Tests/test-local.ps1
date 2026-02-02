# Local test script - run this before pushing to catch issues early
param(
    [switch]$SkipBuild,
    [switch]$SkipTests,
    [switch]$SkipAnalyze,

    [string]$FunctionName,

    [switch]$Quick
)

# Quick mode: skip build and delegate to Invoke-QuickTest.ps1
if ($Quick) {
    $SkipBuild = $true

    if ($FunctionName) {
        Write-Host "`n[QUICK] Running targeted test for: $FunctionName" -ForegroundColor Yellow
        & ".\Scripts\Invoke-QuickTest.ps1" -FunctionName $FunctionName -IncludeAnalyzer:(-not $SkipAnalyze)
        exit $LASTEXITCODE
    }

    # Quick without function name: run all tests directly (no build, no coverage)
    Write-Host "`n[QUICK] Running all tests (no build, no coverage)..." -ForegroundColor Yellow
    & ".\Scripts\Invoke-QuickTest.ps1" -IncludeAnalyzer:(-not $SkipAnalyze)
    exit $LASTEXITCODE
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "LOCAL PRE-PUSH VALIDATION" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$ErrorActionPreference = 'Stop'

# 1. BUILD
if (-not $SkipBuild) {
    Write-Host "[1/3] Building module..." -ForegroundColor Yellow
    & ./build.ps1 -Tasks build
    if ($LASTEXITCODE -ne 0) {
        Write-Host "BUILD FAILED" -ForegroundColor Red
        exit 1
    }
    Write-Host "BUILD PASSED`n" -ForegroundColor Green
}

# 2. PSScriptAnalyzer
if (-not $SkipAnalyze) {
    Write-Host "[2/3] Running PSScriptAnalyzer..." -ForegroundColor Yellow
    Import-Module PSScriptAnalyzer

    $results = Invoke-ScriptAnalyzer -Path ./source -Recurse -Settings ./.PSScriptAnalyzerSettings.psd1

    if ($results) {
        $results | Format-Table -AutoSize
        $errors = $results | Where-Object Severity -eq 'Error'

        if ($errors) {
            Write-Host "PSScriptAnalyzer found $($errors.Count) error(s)" -ForegroundColor Red
            exit 1
        }
        else {
            Write-Host "PSScriptAnalyzer warnings found (but no errors)`n" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "PSScriptAnalyzer PASSED - no issues found`n" -ForegroundColor Green
    }
}

# 3. TESTS
if (-not $SkipTests) {
    Write-Host "[3/3] Running Pester tests..." -ForegroundColor Yellow

    if ($FunctionName) {
        Write-Host "Targeted test for: $FunctionName" -ForegroundColor Cyan
        & ".\Scripts\Invoke-QuickTest.ps1" -FunctionName $FunctionName
        if ($LASTEXITCODE -ne 0) {
            Write-Host "TESTS FAILED" -ForegroundColor Red
            exit 1
        }
    }
    else {
        & ./build.ps1 -Tasks test
        if ($LASTEXITCODE -ne 0) {
            Write-Host "TESTS FAILED" -ForegroundColor Red
            exit 1
        }
    }
    Write-Host "TESTS PASSED`n" -ForegroundColor Green
}

Write-Host "========================================" -ForegroundColor Green
Write-Host "ALL LOCAL CHECKS PASSED!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green
Write-Host "Ready to push to GitHub`n"
