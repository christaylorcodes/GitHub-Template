BeforeAll {
    # Find and import TestHelper (works at any directory depth under Tests/)
    $testDir = $PSScriptRoot
    while ($testDir -and !(Test-Path (Join-Path $testDir 'TestHelpers/TestHelper.psm1'))) {
        $testDir = Split-Path -Parent $testDir
    }
    Import-Module (Join-Path $testDir 'TestHelpers/TestHelper.psm1') -Force
    $script:Module = Initialize-TestModule
}

Describe 'Verb-Noun' -Tag 'Unit', 'Public' {
    BeforeAll {
        # Setup test data that applies to all tests in this Describe block
        $testData = @{
            ValidInput   = 'TestValue'
            InvalidInput = $null
        }
    }

    Context 'Parameter Validation' {
        It 'Should have a mandatory ParameterName parameter' {
            (Get-Command Verb-Noun).Parameters['ParameterName'].Attributes.Mandatory | Should -Be $true
        }

        It 'Should throw when ParameterName is null or empty' {
            { Verb-Noun -ParameterName '' } | Should -Throw
        }

        It 'Should accept pipeline input for ParameterName' {
            (Get-Command Verb-Noun).Parameters['ParameterName'].Attributes.ValueFromPipeline | Should -Be $true
        }
    }

    Context 'Functionality' {
        BeforeEach {
            # Setup that runs before each test in this Context
            # Useful for ensuring a clean state
        }

        It 'Should return a PSCustomObject' {
            $result = Verb-Noun -ParameterName $testData.ValidInput
            $result | Should -BeOfType [PSCustomObject]
        }

        It 'Should have expected properties on output object' {
            $result = Verb-Noun -ParameterName $testData.ValidInput
            $result.PSObject.Properties.Name | Should -Contain 'Property1'
            $result.PSObject.Properties.Name | Should -Contain 'Property2'
            $result.PSObject.Properties.Name | Should -Contain 'Timestamp'
        }

        It 'Should process input correctly' {
            $result = Verb-Noun -ParameterName $testData.ValidInput
            $result.Property1 | Should -Be $testData.ValidInput
        }

        It 'Should accept pipeline input' {
            $result = $testData.ValidInput | Verb-Noun
            $result.Property1 | Should -Be $testData.ValidInput
        }

        It 'Should process multiple pipeline inputs' {
            $inputs = @('Value1', 'Value2', 'Value3')
            $results = $inputs | Verb-Noun
            $results.Count | Should -Be 3
            $results[0].Property1 | Should -Be 'Value1'
            $results[2].Property1 | Should -Be 'Value3'
        }
    }

    Context 'Error Handling' {
        It 'Should throw on invalid input' {
            { Verb-Noun -ParameterName '' } | Should -Throw
        }

        It 'Should surface failures from its dependencies as terminating errors' {
            # Mock a command the function calls so it fails. -ModuleName is required
            # so the mock replaces the command inside the module's scope.
            Mock Get-Date -ModuleName $script:Module.Name { throw 'dependency failed' }

            { Verb-Noun -ParameterName 'Value' } | Should -Throw '*dependency failed*'
            Should -Invoke Get-Date -ModuleName $script:Module.Name -Times 1 -Exactly
        }
    }

    Context 'Edge Cases' {
        It 'Should handle special characters in input' {
            $specialInput = 'Test@#$%^&*()'
            $result = Verb-Noun -ParameterName $specialInput
            $result.Property1 | Should -Be $specialInput
        }

        It 'Should handle very long input strings' {
            $longInput = 'a' * 10000
            $result = Verb-Noun -ParameterName $longInput
            $result.Property1 | Should -Be $longInput
        }
    }
}

AfterAll {
    if ($script:Module) {
        Remove-Module -Name $script:Module.Name -Force -ErrorAction SilentlyContinue
    }
    Remove-Module -Name 'TestHelper' -Force -ErrorAction SilentlyContinue
}
