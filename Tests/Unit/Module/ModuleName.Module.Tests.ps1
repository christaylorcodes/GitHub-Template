BeforeAll {
    # Find and import TestHelper (works at any directory depth under Tests/)
    $testDir = $PSScriptRoot
    while ($testDir -and !(Test-Path (Join-Path $testDir 'TestHelpers/TestHelper.psm1'))) {
        $testDir = Split-Path -Parent $testDir
    }
    Import-Module (Join-Path $testDir 'TestHelpers/TestHelper.psm1') -Force
    $script:ModuleInfo = Initialize-TestModule
    $script:ProjectRoot = Get-ProjectRoot
}

Describe 'ModuleName Module' -Tag 'Unit', 'Module' {

    Context 'Module Import' {
        It 'Should import without errors' {
            $script:ModuleInfo | Should -Not -BeNullOrEmpty
        }

        It 'Should be loaded in the current session' {
            Get-Module -Name $script:ModuleInfo.Name | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Module Manifest' {
        BeforeAll {
            $script:ManifestPath = Get-ModuleManifestPath
            $script:Manifest = Test-ModuleManifest -Path $script:ManifestPath -ErrorAction Stop
        }

        It 'Should have a valid manifest' {
            $script:Manifest | Should -Not -BeNullOrEmpty
        }

        It 'Should have a version number' {
            $script:Manifest.Version | Should -Not -BeNullOrEmpty
        }

        It 'Should specify a PowerShell version requirement' {
            $script:Manifest.PowerShellVersion | Should -Not -BeNullOrEmpty
        }

        It 'Should have a description' {
            $script:Manifest.Description | Should -Not -BeNullOrEmpty
        }

        It 'Should have an author' {
            $script:Manifest.Author | Should -Not -BeNullOrEmpty
        }

        It 'Should support PSEdition Core' {
            $script:Manifest.CompatiblePSEditions | Should -Contain 'Core'
        }
    }

    Context 'Exported Functions' {
        BeforeAll {
            $publicPath = Join-Path $script:ProjectRoot 'source' 'Public'
            $script:PublicFunctions = Get-ChildItem -Path $publicPath -Filter '*.ps1' -ErrorAction SilentlyContinue
            $script:ExportedCommands = $script:ModuleInfo.ExportedCommands.Keys
        }

        It 'Should export at least one function' {
            $script:ExportedCommands.Count | Should -BeGreaterThan 0
        }

        It 'Should export a function for each Public/*.ps1 file' {
            foreach ($file in $script:PublicFunctions) {
                $script:ExportedCommands | Should -Contain $file.BaseName
            }
        }

        It 'Should not export any private functions' {
            $privatePath = Join-Path $script:ProjectRoot 'source' 'Private'
            $privateFunctions = Get-ChildItem -Path $privatePath -Filter '*.ps1' -ErrorAction SilentlyContinue
            foreach ($file in $privateFunctions) {
                $script:ExportedCommands | Should -Not -Contain $file.BaseName
            }
        }

        It 'Should have all exported functions using approved verbs' {
            $approvedVerbs = Get-Verb | Select-Object -ExpandProperty Verb
            foreach ($cmd in $script:ExportedCommands) {
                $verb = ($cmd -split '-')[0]
                $verb | Should -BeIn $approvedVerbs -Because "$cmd should use an approved verb"
            }
        }
    }
}

AfterAll {
    if ($script:ModuleInfo) {
        Remove-Module -Name $script:ModuleInfo.Name -Force -ErrorAction SilentlyContinue
    }
    Remove-Module -Name 'TestHelper' -Force -ErrorAction SilentlyContinue
}
