function Get-ModuleInfo {
    <#
    .SYNOPSIS
    Gets information about the ModuleName module

    .DESCRIPTION
    Returns version, author, and other metadata about the ModuleName module.
    This is an example function to demonstrate the module structure.

    .OUTPUTS
    System.Management.Automation.PSCustomObject
    Returns an object with module information

    .NOTES
    Version:        1.0.0
    Author:         Your Name
    Creation Date:  2024-01-01
    Purpose/Change: Example function for module template

    .LINK
    https://github.com/YOUR-USERNAME/ModuleName

    .EXAMPLE
    Get-ModuleInfo

    Returns information about the ModuleName module

    .EXAMPLE
    Get-ModuleInfo | Format-List

    Displays module information as a formatted list
    #>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    param()

    begin {
        Write-Verbose -Message "Starting $($MyInvocation.MyCommand)"
    }

    process {
        try {
            # Get the loaded module object (works in both source and compiled modes)
            $LoadedModule = Get-Module -Name 'ModuleName' -ErrorAction Stop |
                Select-Object -First 1

            if (-not $LoadedModule) {
                throw 'ModuleName module is not loaded'
            }

            Write-Debug -Message "Found module: $($LoadedModule.Name) v$($LoadedModule.Version)"

            # Build output object from the loaded module
            $ModuleInfo = [PSCustomObject]@{
                PSTypeName        = 'ModuleName.ModuleInfo'
                Name              = $LoadedModule.Name
                Version           = $LoadedModule.Version.ToString()
                Author            = $LoadedModule.Author
                CompanyName       = $LoadedModule.CompanyName
                Copyright         = $LoadedModule.Copyright
                Description       = $LoadedModule.Description
                PowerShellVersion = $LoadedModule.PowerShellVersion
                RequiredModules   = $LoadedModule.RequiredModules
                FunctionsExported = $LoadedModule.ExportedFunctions.Count
                ProjectUri        = $LoadedModule.ProjectUri
                LicenseUri        = $LoadedModule.LicenseUri
            }

            Write-Verbose -Message "Retrieved module info: $($ModuleInfo.Name) v$($ModuleInfo.Version)"

            return $ModuleInfo
        } catch {
            Write-Error -Message "Failed to get module information" -ErrorRecord $_
            throw
        }
    }

    end {
        Write-Verbose -Message "Completed $($MyInvocation.MyCommand)"
    }
}
