@{
    # Script module or binary module file associated with this manifest.
    RootModule        = 'ModuleName.psm1'

    # Version number of this module.
    ModuleVersion     = '1.0.0'

    # Supported PSEditions
    CompatiblePSEditions = @('Core')

    # ID used to uniquely identify this module
    GUID              = 'd85cdf65-f84d-4f06-bbc9-c245ba799381'

    # Author of this module
    Author            = 'Your Name'

    # Company or vendor of this module
    CompanyName       = 'Your Company'

    # Copyright statement for this module
    Copyright         = '(c) 2025 Your Name. All rights reserved.'

    # Description of the functionality provided by this module
    Description       = 'Brief description of what this module does'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '7.2'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules   = @()

    # Functions to export — wildcard allows the .psm1 Export-ModuleMember call to control exports.
    # The build step can replace this with an explicit list for published modules.
    FunctionsToExport = @('*')

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport   = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData       = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @('PowerShell', 'Automation', 'Tool')

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/YOUR-USERNAME/ModuleName/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/YOUR-USERNAME/ModuleName'

            # A URL to an icon representing this module.
            IconUri      = 'https://raw.githubusercontent.com/YOUR-USERNAME/ModuleName/main/docs/media/Logo.png'

            # ReleaseNotes of this module
            ReleaseNotes = @'
## 1.0.0 - Initial Release
- Initial release of ModuleName
- Core functionality implemented
- Comprehensive tests included
'@

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    HelpInfoURI       = 'https://github.com/YOUR-USERNAME/ModuleName/blob/main/docs'
}
