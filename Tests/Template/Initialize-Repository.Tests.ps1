#requires -Version 7.2

<#
    Guards the template's own initialization tooling end to end.

    Copies the template into $TestDrive, runs Scripts/Initialize-Repository.ps1 with
    deliberately awkward input (a dotted module name, an apostrophe, regex and
    PowerShell special characters), scaffolds functions with New-Function.ps1, and
    then runs the initialized project's own quick tests.

    Initialize-Repository.ps1 deletes this folder, so new projects never carry it.
#>

BeforeDiscovery {
    $script:SkipReason = $null
    if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
        $script:SkipReason = 'pwsh is not on PATH'
    }
}

Describe 'Initialize-Repository.ps1' -Tag 'Template' -Skip:([bool]$script:SkipReason) {
    BeforeAll {
        $script:TemplateRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        $script:Work = Join-Path $TestDrive 'repo'
        $null = New-Item -ItemType Directory -Path $script:Work

        # Copy the template without git metadata or build output
        $exclude = @('.git', 'output')
        Get-ChildItem -LiteralPath $script:TemplateRoot -Force |
            Where-Object { $_.Name -notin $exclude } |
            Copy-Item -Destination $script:Work -Recurse -Force

        $script:ModuleName = 'My.Module'
        $script:Author = "O'Brien"
        $script:Description = 'Saves $5 & "quotes" (a.k.a. [regex] stuff)'

        function Invoke-ChildPwsh {
            param([string]$File, [string[]]$Arguments)
            $output = & pwsh -NoProfile -NonInteractive -WorkingDirectory $script:Work -File $File @Arguments 2>&1
            [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = ($output | Out-String) }
        }

        $script:Init = Invoke-ChildPwsh -File (Join-Path $script:Work 'Scripts/Initialize-Repository.ps1') -Arguments @(
            '-Name', 'MyProject'
            '-ModuleName', $script:ModuleName
            '-Description', $script:Description
            '-Author', $script:Author
            '-GitHubUsername', 'octocat'
            '-RepositoryName', 'my-project'
        )

        $newFunction = Join-Path $script:Work 'Scripts/New-Function.ps1'
        $script:NewPublic = Invoke-ChildPwsh -File $newFunction -Arguments @(
            '-FunctionName', 'Get-Widget', '-Type', 'Public', '-Author', 'Tester', '-Force')
        $script:NewPrivate = Invoke-ChildPwsh -File $newFunction -Arguments @(
            '-FunctionName', 'ConvertTo-Widget', '-Type', 'Private', '-Author', 'Tester', '-Force')

        $script:ManifestPath = Join-Path $script:Work "source/$($script:ModuleName).psd1"
    }

    Context 'Initialization' {
        It 'Completes without error' {
            $script:Init.ExitCode | Should -Be 0 -Because $script:Init.Output
        }

        It 'Renames module, about topic and module test files' {
            $script:ManifestPath | Should -Exist
            Join-Path $script:Work "source/$($script:ModuleName).psm1" | Should -Exist
            Join-Path $script:Work "source/en-US/about_$($script:ModuleName).help.txt" | Should -Exist
            Join-Path $script:Work "Tests/Unit/Module/$($script:ModuleName).Module.Tests.ps1" | Should -Exist
        }

        It 'Produces a manifest that loads with the exact author and description' {
            $manifest = Test-ModuleManifest -Path $script:ManifestPath -ErrorAction Stop
            $manifest.Author | Should -BeExactly $script:Author
            $manifest.Description | Should -BeExactly $script:Description
            $manifest.Copyright | Should -BeExactly "(c) $((Get-Date).Year) $($script:Author). All rights reserved."
            $manifest.Guid | Should -Not -Be 'd85cdf65-f84d-4f06-bbc9-c245ba799381'
        }

        It 'Keeps the Prerelease key that CI relies on' {
            $data = Import-PowerShellDataFile -Path $script:ManifestPath
            $data.PrivateData.PSData.ContainsKey('Prerelease') | Should -BeTrue
        }

        It 'Points manifest URIs at the repository, not the module name' {
            $data = Import-PowerShellDataFile -Path $script:ManifestPath
            $data.PrivateData.PSData.ProjectUri | Should -Be 'https://github.com/octocat/my-project'
        }

        It 'Sets MODULE_NAME in both workflows' {
            foreach ($workflow in 'ci.yml', 'pr-validation.yml') {
                Get-Content (Join-Path $script:Work ".github/workflows/$workflow") -Raw |
                    Should -Match "MODULE_NAME: $([regex]::Escape($script:ModuleName))\r?\n"
            }
        }

        It 'Sets the release identity in build.yaml' {
            $buildYaml = Get-Content (Join-Path $script:Work 'build.yaml') -Raw
            $buildYaml | Should -Match 'GitHubConfigUserName: octocat'
            $buildYaml | Should -Match 'GitHubConfigUserEmail: octocat@users\.noreply\.github\.com'
        }

        It 'Leaves Pester -ModuleName parameters intact in templates' {
            Get-Content (Join-Path $script:Work 'Templates/Test.Tests.ps1') -Raw |
                Should -Match 'Mock Get-Date -ModuleName \$script:Module\.Name'
        }

        It 'Resets CHANGELOG to an [Unreleased] stub' {
            $changelog = Get-Content (Join-Path $script:Work 'CHANGELOG.md') -Raw
            $changelog | Should -Match '## \[Unreleased\]'
            $changelog | Should -Not -Match '## \[1\.1\.0\]'
        }

        It 'Removes template-only files: <_>' -ForEach @(
            'Scripts/Initialize-Repository.ps1'
            'Scripts/Test-Template.ps1'
            'Scripts/New-TemplateBadges.ps1'
            'Scripts/Initialize-Roadmap.ps1'
            'docs/TEMPLATE_USAGE.md'
            'docs/TEMPLATE_DEVELOPMENT.md'
            'Tests/Template'
            'DONATE.md'
            'Media'
        ) {
            Join-Path $script:Work $_ | Should -Not -Exist
        }

        It 'Leaves no placeholders in code, tests, workflows or build config' {
            $tokenPattern = '(?<![-$:A-Za-z0-9])ModuleName(?![A-Za-z0-9])|YOUR-USERNAME|YOUR-REPO|your@email\.com'
            $scanRoots = 'source', 'Tests', 'Templates', '.github/workflows', 'docs/examples'
            $files = @($scanRoots | ForEach-Object {
                    Get-ChildItem -Path (Join-Path $script:Work $_) -Recurse -File
                }) + @(Get-Item (Join-Path $script:Work 'build.yaml'), (Join-Path $script:Work 'docs/USAGE.md'))

            # TestHelper keeps a literal 'ModuleName' fallback by design (it auto-discovers the name)
            $hits = $files |
                Where-Object Name -NE 'TestHelper.psm1' |
                Select-String -Pattern $tokenPattern -CaseSensitive |
                ForEach-Object { '{0}:{1}: {2}' -f $_.Path.Replace($script:Work, ''), $_.LineNumber, $_.Line.Trim() }

            $hits | Should -BeNullOrEmpty
        }

        It 'Leaves every PowerShell file parseable' {
            $errors = Get-ChildItem -Path $script:Work -Include '*.ps1', '*.psm1', '*.psd1' -Recurse -File |
                ForEach-Object {
                    $parseErrors = $null
                    $null = [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$parseErrors)
                    $parseErrors | ForEach-Object { "$($_.Extent.File):$($_.Extent.StartLineNumber): $($_.Message)" }
                }
            $errors | Should -BeNullOrEmpty
        }
    }

    Context 'Scaffolding with New-Function.ps1' {
        It 'Creates a public function and test' {
            $script:NewPublic.ExitCode | Should -Be 0 -Because $script:NewPublic.Output
            Join-Path $script:Work 'source/Public/Get-Widget.ps1' | Should -Exist
            Join-Path $script:Work 'Tests/Unit/Public/Get-Widget.Tests.ps1' | Should -Exist
        }

        It 'Creates a private function and test' {
            $script:NewPrivate.ExitCode | Should -Be 0 -Because $script:NewPrivate.Output
            Join-Path $script:Work 'source/Private/ConvertTo-Widget.ps1' | Should -Exist
            Join-Path $script:Work 'Tests/Unit/Private/ConvertTo-Widget.Tests.ps1' | Should -Exist
        }

        It 'Writes UTF-8 with BOM' {
            $bytes = [IO.File]::ReadAllBytes((Join-Path $script:Work 'source/Public/Get-Widget.ps1'))
            $bytes[0..2] | Should -Be @(0xEF, 0xBB, 0xBF)
        }
    }

    Context 'Initialized project' {
        It 'Passes its own quick tests (source module, generated functions included)' {
            $quickTest = Join-Path $script:Work 'Scripts/Invoke-QuickTest.ps1'
            $output = & pwsh -NoProfile -NonInteractive -WorkingDirectory $script:Work -File $quickTest -OutputFormat Structured 2>&1
            $exitCode = $LASTEXITCODE
            $json = ($output | Out-String)
            $exitCode | Should -Be 0 -Because $json

            $result = $json | ConvertFrom-Json
            $result.success | Should -BeTrue
            $result.totalTests | Should -BeGreaterThan 0
        }
    }
}
