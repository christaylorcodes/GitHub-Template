#requires -Version 7.0

<#
.SYNOPSIS
Root module file for ModuleName

.DESCRIPTION
This module file loads all public, private, and class files for the ModuleName module.
It automatically discovers and imports all functions from the Public, Private, and Classes folders.

.NOTES
Version:        1.0.0
Author:         Your Name
Module Name:    ModuleName
#>

# Get module root path
$ModuleRoot = $PSScriptRoot

# Initialize module
Write-Verbose "Initializing module: ModuleName"
Write-Verbose "Module root: $ModuleRoot"

#region Load Classes
# Load classes first (they may be used by functions)
$ClassPath = Join-Path $ModuleRoot 'Classes'
$ClassFiles = Get-ChildItem -Path $ClassPath -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue

foreach ($ClassFile in $ClassFiles) {
    try {
        Write-Verbose "Loading class: $($ClassFile.BaseName)"
        . $ClassFile.FullName
    } catch {
        Write-Error "Failed to load class file: $($ClassFile.FullName) - $_"
        throw
    }
}

Write-Verbose "Loaded $($ClassFiles.Count) class file(s)"
#endregion Load Classes

#region Load Private Functions
# Load private functions (internal helpers)
$PrivatePath = Join-Path $ModuleRoot 'Private'
$PrivateFunctions = Get-ChildItem -Path $PrivatePath -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue

foreach ($PrivateFunction in $PrivateFunctions) {
    try {
        Write-Verbose "Loading private function: $($PrivateFunction.BaseName)"
        . $PrivateFunction.FullName
    } catch {
        Write-Error "Failed to load private function: $($PrivateFunction.FullName) - $_"
        throw
    }
}

Write-Verbose "Loaded $($PrivateFunctions.Count) private function(s)"
#endregion Load Private Functions

#region Load Public Functions
# Load public functions (exported to users)
$PublicPath = Join-Path $ModuleRoot 'Public'
$PublicFunctions = Get-ChildItem -Path $PublicPath -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue

foreach ($PublicFunction in $PublicFunctions) {
    try {
        Write-Verbose "Loading public function: $($PublicFunction.BaseName)"
        . $PublicFunction.FullName
    } catch {
        Write-Error "Failed to load public function: $($PublicFunction.FullName) - $_"
        throw
    }
}

Write-Verbose "Loaded $($PublicFunctions.Count) public function(s)"
#endregion Load Public Functions

#region Export Functions
# Export public functions
# This makes them available to users who import the module
if ($PublicFunctions) {
    $FunctionsToExport = $PublicFunctions.BaseName
    Export-ModuleMember -Function $FunctionsToExport

    Write-Verbose "Exported functions: $($FunctionsToExport -join ', ')"
} else {
    Write-Warning "No public functions found to export"
}
#endregion Export Functions

# Module initialization complete
Write-Verbose "Module initialization complete: ModuleName"
