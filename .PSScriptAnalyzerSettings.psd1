@{
    # Use the PowerShell Gallery rules as baseline
    # These are the recommended rules for modules published to the gallery
    # IncludeDefaultRules = $true

    # Severity levels: Error, Warning, Information
    # Only show errors and warnings by default
    Severity = @('Error', 'Warning')

    # Exclude specific rules if needed
    # ExcludeRules = @(
    #     'PSAvoidUsingWriteHost'  # Uncomment if you intentionally use Write-Host
    # )

    # Include specific rules (if not using IncludeDefaultRules)
    IncludeRules = @(
        # Code Style
        'PSAvoidDefaultValueForMandatoryParameter',
        'PSAvoidDefaultValueSwitchParameter',
        'PSAvoidGlobalVars',
        'PSAvoidUsingCmdletAliases',
        'PSAvoidUsingComputerNameHardcoded',
        'PSAvoidUsingConvertToSecureStringWithPlainText',
        'PSAvoidUsingDeprecatedManifestFields',
        'PSAvoidUsingEmptyCatchBlock',
        'PSAvoidUsingInvokeExpression',
        'PSAvoidUsingPlainTextForPassword',
        'PSAvoidUsingPositionalParameters',
        'PSAvoidUsingUsernameAndPasswordParams',
        'PSAvoidUsingWMICmdlet',
        'PSAvoidUsingWriteHost',

        # Best Practices
        'PSAlignAssignmentStatement',
        'PSAvoidAssignmentToAutomaticVariable',
        'PSAvoidLongLines',
        'PSAvoidOverwritingBuiltInCmdlets',
        'PSAvoidShouldContinueWithoutForce',
        'PSAvoidTrailingWhitespace',
        'PSAvoidUsingBrokenHashAlgorithms',
        'PSAvoidUsingDoubleQuotesForConstantString',

        # Functions
        'PSAvoidMultipleTypeAttributes',
        'PSMisleadingBacktick',
        'PSMissingModuleManifestField',
        'PSPlaceCloseBrace',
        'PSPlaceOpenBrace',
        'PSProvideCommentHelp',
        'PSReservedCmdletChar',
        'PSReservedParams',
        'PSReviewUnusedParameter',
        'PSShouldProcess',
        'PSUseApprovedVerbs',
        'PSUseBOMForUnicodeEncodedFile',
        'PSUseCmdletCorrectly',
        'PSUseCompatibleCmdlets',
        # PSUseCompatibleCommands disabled — PSSA profile catalog is often outdated
        'PSUseCompatibleSyntax',
        'PSUseCompatibleTypes',
        'PSUseConsistentIndentation',
        'PSUseConsistentWhitespace',
        'PSUseCorrectCasing',
        'PSUseDeclaredVarsMoreThanAssignments',
        'PSUseLiteralInitializerForHashtable',
        'PSUseOutputTypeCorrectly',
        'PSUsePSCredentialType',
        'PSUseProcessBlockForPipelineCommand',
        'PSUseShouldProcessForStateChangingFunctions',
        'PSUseSingularNouns',
        'PSUseSupportsShouldProcess',
        'PSUseToExportFieldsInManifest',
        'PSUseUTF8EncodingForHelpFile',
        'PSUseUsingScopeModifierInNewRunspaces'
    )

    # Rule-specific settings
    Rules = @{
        PSPlaceOpenBrace = @{
            Enable             = $true
            OnSameLine         = $true
            NewLineAfter       = $true
            IgnoreOneLineBlock = $true
        }

        PSPlaceCloseBrace = @{
            Enable             = $true
            NewLineAfter       = $false
            IgnoreOneLineBlock = $true
            NoEmptyLineBefore  = $false
        }

        PSUseConsistentIndentation = @{
            Enable              = $true
            Kind                = 'space'
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            IndentationSize     = 4
        }

        PSUseConsistentWhitespace = @{
            Enable                          = $true
            CheckInnerBrace                 = $true
            CheckOpenBrace                  = $true
            CheckOpenParen                  = $true
            CheckOperator                   = $true
            CheckPipe                       = $true
            CheckPipeForRedundantWhitespace = $false
            CheckSeparator                  = $true
            CheckParameter                  = $false
            # Allow aligned '=' in hashtables (required by PSAlignAssignmentStatement)
            IgnoreAssignmentOperatorInsideHashTable = $true
        }

        PSAlignAssignmentStatement = @{
            Enable         = $true
            CheckHashtable = $true
        }

        PSUseCorrectCasing = @{
            Enable = $true
        }

        PSAvoidLongLines = @{
            Enable            = $true
            MaximumLineLength = 120
        }

        # Syntax compatibility. NOTE: this rule only compares MAJOR versions, so any
        # 7.x target behaves the same; it catches 7-only syntax if you add '5.1',
        # it does not verify compatibility between 7.x releases.
        PSUseCompatibleSyntax = @{
            Enable         = $true
            TargetVersions = @(
                '7.6'
            )
        }

        # PSUseCompatibleCommands is disabled because the PSSA compatibility
        # profile catalog is often outdated. PSUseCompatibleSyntax above is
        # sufficient for verifying syntax across target PS versions.
        # PSUseCompatibleCommands = @{
        #     Enable         = $true
        #     TargetProfiles = @()
        # }

        PSProvideCommentHelp = @{
            Enable                  = $true
            ExportedOnly            = $true
            BlockComment            = $true
            VSCodeSnippetCorrection = $false
            Placement               = 'before'
        }
    }
}
