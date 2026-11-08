# PowerShell Deep Review Reference

> **When to load this file**: Only during thorough code reviews, refactoring sessions, or when auditing a module for release. This is NOT needed for everyday development. For daily conventions, see `docs/PowerShell-StyleGuide.md`.

## Review Checklist

Use this as a pass/fail checklist when reviewing code for merge or release.

### Mandatory (block merge if failing)

- [ ] PSScriptAnalyzer reports zero errors
- [ ] All Pester tests pass
- [ ] No hardcoded credentials, API keys, tokens, or webhook URLs in source
- [ ] `$ErrorActionPreference = 'Stop'` is set (or `-ErrorAction Stop` on all external calls)
- [ ] Comment-based help exists on every exported function (`.SYNOPSIS`, `.PARAMETER`, `.EXAMPLE`)
- [ ] `[CmdletBinding()]` is present on all functions
- [ ] `[OutputType()]` is declared on all functions
- [ ] No use of `Write-Host` in module code
- [ ] No aliases used (`%`, `?`, `iex`, `iwr`, `sls`, etc.)
- [ ] No `Invoke-Expression` usage (PSSA enforces, but verify no suppression comments)
- [ ] TLS 1.2+ is set before any network calls in standalone scripts
- [ ] Functions use approved verbs (`Get-Verb` to check)

### Recommended (note but don't block)

- [ ] PSSA warnings are minimized (review each, suppress only with documented justification)
- [ ] Pipeline support (`ValueFromPipeline`) on functions that logically accept it
- [ ] `begin`/`process`/`end` blocks on pipeline-capable functions
- [ ] `SupportsShouldProcess` on functions that modify state
- [ ] Typed catch blocks for expected exception types
- [ ] `Write-Verbose` at function entry, key decision points, and exit
- [ ] `Write-Debug` for raw data dumps (API responses, query strings)
- [ ] Collections built with `[List[T]]` not `+=` on arrays
- [ ] Paths built with `Join-Path` not string concatenation

---

## Detailed Pattern Analysis

### Error Handling Patterns

#### Pattern: Proper Error Propagation

Functions should record context then re-throw, not swallow errors:

```powershell
# CORRECT: Add context, keep the original exception, re-throw
try {
    $response = Invoke-RestMethod -Uri $uri -Headers $headers
}
catch [System.Net.WebException] {
    $errorRecord = [System.Management.Automation.ErrorRecord]::new(
        [System.Exception]::new("API call to $uri failed", $_.Exception),
        'ApiCallFailed',
        [System.Management.Automation.ErrorCategory]::ConnectionError,
        $uri
    )
    $PSCmdlet.ThrowTerminatingError($errorRecord)
}

# WRONG: Fails to bind. -Message and -ErrorRecord are in different
# parameter sets, so this throws a ParameterBindingException instead
catch {
    Write-Error -Message "API call failed" -ErrorRecord $_
    throw
}

# WRONG: Swallows the error, caller never knows
try {
    $response = Invoke-RestMethod -Uri $uri -Headers $headers
}
catch {
    Write-Warning "Something went wrong"
    return $null
}

# WRONG: Loses the original ErrorRecord (no stack trace)
catch {
    throw "API call failed: $($_.Exception.Message)"
}
```

#### Pattern: ErrorAction on Cmdlets That Default to Continue

Some cmdlets default to `-ErrorAction Continue` even when `$ErrorActionPreference = 'Stop'`. Watch for:

- `Get-WmiObject` / `Get-CimInstance` with `-ComputerName` (remote failures don't throw)
- `Get-ADUser` and other AD cmdlets (some return non-terminating errors)
- `Invoke-Command` (remote errors are serialized differently)
- `Test-Connection` (returns `$false` instead of throwing)

Add explicit `-ErrorAction Stop` on these:

```powershell
$result = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $name -ErrorAction Stop
```

#### Anti-Pattern: Exit Codes in Module Functions

Module functions should throw on failure, not return exit codes. Exit codes are for standalone scripts:

```powershell
# WRONG in a module function
function Get-Data {
    try { ... }
    catch { return -1 }
}

# CORRECT in a module function
function Get-Data {
    [CmdletBinding()]
    param()

    try { ... }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}

# Exit codes are fine in standalone scripts
try { ... }
catch {
    Write-EventLog -LogName $LogName -Source $LogSource -EntryType Error -EventId 3000 -Message "Fatal: $($_.Exception.Message)"
    exit 1
}
```

---

### Logging Patterns (Legacy Migration)

When reviewing existing code, you will encounter four logging patterns. The goal is migration to **Windows Event Log** (default) or **PSFramework** (when advanced features are needed). Don't migrate during unrelated changes -- only when refactoring the script.

#### Pattern 1: Windows Event Log (Current Default Standard)

```powershell
$LogSource = 'MyCompany-Automation'
$LogName   = 'Application'

if (-not [System.Diagnostics.EventLog]::SourceExists($LogSource)) {
    New-EventLog -LogName $LogName -Source $LogSource
}

Write-EventLog -LogName $LogName -Source $LogSource -EntryType Information -EventId 1000 -Message 'Script started'
Write-EventLog -LogName $LogName -Source $LogSource -EntryType Warning     -EventId 2000 -Message 'Retry needed'
Write-EventLog -LogName $LogName -Source $LogSource -EntryType Error       -EventId 3000 -Message "Failed: $($_.Exception.Message)"
```

**Review points:**

- Verify `$LogSource` is registered before first `Write-EventLog` call
- Verify Event IDs follow convention: 1000s = Info, 2000s = Warning, 3000s = Error
- Check that error messages include exception details (`$_.Exception.Message`)
- Verify the source name is consistent across scripts in the same project (use a company/project prefix)
- Source registration requires elevation -- verify it's handled gracefully on non-admin runs

#### Pattern 2: PSFramework (Advanced Scenarios)

```powershell
Write-PSFMessage -Level Host -Message 'Processing started'
Write-PSFMessage -Level Verbose -Message 'Connecting to API'
Write-PSFMessage -Level Warning -Message 'Retrying after timeout'
Write-PSFMessage -Level Error -Message 'Fatal error' -ErrorRecord $_
Wait-PSFMessage  # Must call before exit
```

**Review points:**

- Verify `Wait-PSFMessage` is called in all exit paths (including `finally` blocks)
- Verify log file path uses CMTrace format for endpoint scripts
- Check that `-ErrorRecord $_` is passed on error messages (preserves stack trace)
- Confirm PSFramework is justified (needs tags/data objects, CMTrace files, multi-provider, or cross-platform)

#### Pattern 3: PSGallery `Logging` Module (Legacy -- Unmaintained Since 2022)

```powershell
Write-Log -Message 'Info'
Write-Log -Level 'WARNING' -Message 'Warning'
Write-Log -Level 'ERROR' -Message 'Error'
Wait-Logging  # Must call before exit
```

**Review points:**

- Note for migration backlog but do not mix patterns in the same script
- Verify `Wait-Logging` is called before exit (common miss)
- Check that log levels are uppercase strings (the module is case-sensitive)

---

### API Integration Patterns

#### Authentication Header Construction

```powershell
# Basic Auth (base64 encoded)
$headers = @{
    'Authorization' = "Basic $([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($apiKey):")))"
    'Content-Type'  = 'application/json'
}

# Bearer token
$headers = @{
    'Authorization' = "Bearer $accessToken"
    'Content-Type'  = 'application/json'
}
```

**Review points:**
- Verify the API key/token comes from a secure source (Key Vault, `SecretManagement`, environment variable), never hardcoded
- Verify `Content-Type` matches what the API expects
- Check for TLS 1.2 initialization before the call

#### Pagination Handling

APIs that return paged results must be fully consumed:

```powershell
# ConnectWise Manage pattern -- use -all flag
$tickets = Get-CWMTicket -condition "board/id = 22" -all

# Microsoft Graph pattern -- follow @odata.nextLink
$uri = 'https://graph.microsoft.com/v1.0/users'
$allResults = [System.Collections.Generic.List[object]]::new()
do {
    $response = Invoke-RestMethod -Uri $uri -Headers $headers
    $allResults.AddRange($response.value)
    $uri = $response.'@odata.nextLink'
} while ($uri)
```

**Review points:**
- Verify large result sets use pagination, not truncated defaults
- Check for rate limiting / retry logic on 429 responses
- Verify Graph API calls handle `@odata.nextLink` exhaustion

#### Retry Logic

```powershell
$maxRetries = 3
$retryDelay = 5
for ($attempt = 1; $attempt -le $maxRetries; $attempt++) {
    try {
        $response = Invoke-RestMethod -Uri $uri -Headers $headers -ErrorAction Stop
        break
    }
    catch {
        if ($attempt -eq $maxRetries) { throw }
        Write-PSFMessage -Level Warning -Message "Attempt $attempt failed, retrying in ${retryDelay}s"
        Start-Sleep -Seconds ($retryDelay * $attempt)  # Exponential backoff
    }
}
```

**Review points:**
- Verify retry logic exists for external API calls
- Check that the delay increases (linear or exponential backoff)
- Verify the final attempt re-throws instead of silently failing
- Check that non-retryable errors (401, 403, 404) break immediately

---

### Credential Management Patterns

#### Hierarchy (most preferred to least)

1. **Azure Key Vault** via `Az.KeyVault` -- production scripts, shared secrets
2. **`SecretManagement` module** -- local development, personal credentials
3. **Environment variables** -- CI/CD pipelines
4. **`[PSCredential]` parameter** -- interactive scripts where the caller provides credentials

#### Anti-Patterns to Flag

```powershell
# NEVER: Hardcoded credentials
$password = 'MyS3cretP@ss!'

# NEVER: Plain-text in config files
$config = Get-Content 'config.json' | ConvertFrom-Json
$apiKey = $config.apiKey  # If config.json is in source control, this is a leak

# NEVER: ConvertTo-SecureString with plain text key
$secure = ConvertTo-SecureString 'password' -AsPlainText -Force  # Acceptable only in tests with mock data

# AVOID: Remote script loading with Invoke-Expression (injection risk)
Invoke-RestMethod 'https://example.com/script.ps1' | Invoke-Expression
```

---

### Multi-Tenant Considerations

When reviewing scripts that operate across client environments:

- **Client scoping**: Every loop over clients/tenants must filter by status (active only) and handle missing data
- **Logging context**: Log messages should include client/tenant identifier for troubleshooting
- **Error isolation**: One client failure must not abort processing of remaining clients
- **Rate limiting**: Per-tenant API quotas may differ; verify the script respects them
- **Credential isolation**: Verify credentials are scoped per tenant, not shared

```powershell
# CORRECT: Isolated error handling per client
foreach ($client in $activeClients) {
    try {
        Write-PSFMessage -Level Host -Message "Processing client: $($client.Name)" -Tag 'Client'
        # Per-client work
    }
    catch {
        Write-PSFMessage -Level Error -Message "Failed on client $($client.Name)" -ErrorRecord $_ -Tag 'Client'
        # Continue to next client, don't abort
    }
}

# WRONG: One failure kills everything
foreach ($client in $activeClients) {
    # No try/catch -- first failure aborts all remaining clients
    $result = Get-ClientData -ClientId $client.Id
}
```

---

### Performance Patterns

#### Collection Building

```powershell
# CORRECT: Generic List (O(1) amortized add)
$results = [System.Collections.Generic.List[PSCustomObject]]::new()
$results.Add($item)

# WRONG: Array += (O(n) per add, creates new array each time)
$results = @()
$results += $item  # Copies entire array on every iteration
```

**Impact**: Array `+=` in a loop of 10,000 items creates 10,000 array copies. With `List[T]`, the same operation is near-instant.

#### Pipeline vs. ForEach-Object vs. foreach

```powershell
# Fastest: foreach statement (no pipeline overhead)
foreach ($item in $collection) { Process-Item $item }

# Middle: ForEach-Object (pipeline, streaming, lower memory for large sets)
$collection | ForEach-Object { Process-Item $_ }

# Slowest: ForEach-Object with script block AND pipeline input on large in-memory collections
# But necessary when you need pipeline streaming for very large data sources
```

**Guidance**: Use `foreach` for in-memory collections. Use `ForEach-Object` when streaming from a pipeline source (e.g., `Get-ChildItem | ForEach-Object`).

#### String Building

```powershell
# CORRECT for many concatenations: StringBuilder
$sb = [System.Text.StringBuilder]::new()
foreach ($line in $lines) {
    [void]$sb.AppendLine($line)
}
$result = $sb.ToString()

# Fine for simple cases: -f operator or interpolation
$message = "Processed {0} of {1} items" -f $current, $total

# WRONG for loops: repeated concatenation
$result = ''
foreach ($line in $lines) {
    $result += "$line`n"  # Creates new string object each iteration
}
```

---

### Module Architecture Review

When reviewing a module's overall structure:

#### Loading Order

The `.psm1` should auto-discover files in this order: `Classes` -> `Private` -> `Public`. Verify:

```powershell
# In .psm1 -- standard loading pattern
$classFiles   = Get-ChildItem -Path "$PSScriptRoot/Classes"  -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue
$privateFiles = Get-ChildItem -Path "$PSScriptRoot/Private"  -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue
$publicFiles  = Get-ChildItem -Path "$PSScriptRoot/Public"   -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue

foreach ($file in @($classFiles; $privateFiles; $publicFiles)) {
    . $file.FullName
}

Export-ModuleMember -Function $publicFiles.BaseName
```

**Review points:**
- Classes load first (other code may depend on them)
- Only Public functions are exported
- `-Recurse` is used (supports subdirectory organization)
- No manual registration step needed for new functions

#### Manifest (.psd1) Review

- `FunctionsToExport` should use `@('*')` only if the `.psm1` controls exports via `Export-ModuleMember`. Otherwise, list functions explicitly.
- `RequiredModules` must list all runtime dependencies
- `PowerShellVersion` matches the project's target
- `ScriptsToProcess` includes class files only if they need to be visible outside the module scope

#### Cleanup (OnRemove)

Modules that create disposable resources must register cleanup:

```powershell
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    if ($script:HttpClient) {
        $script:HttpClient.Dispose()
        $script:HttpClient = $null
    }
}
```

**Review points:**
- Check for `$script:`-scoped resources: HTTP clients, database connections, runspace pools, event subscriptions
- Verify `OnRemove` is registered at the end of the `.psm1`
- Verify `Dispose()` is called on anything implementing `IDisposable`

---

### Security Review

#### Input Validation

```powershell
# GOOD: Parameter validation attributes
[ValidateNotNullOrEmpty()]
[ValidatePattern('^[a-zA-Z0-9-]+$')]
[ValidateRange(1, 100)]
[ValidateSet('Option1', 'Option2')]
[ValidateScript({ Test-Path $_ })]
```

**Review points:**
- All parameters that accept external input have validation attributes
- SQL parameters use parameterized queries, not string interpolation
- File paths are validated before use
- Regular expressions in `ValidatePattern` don't have ReDoS vulnerabilities

#### SQL Injection

If the code builds SQL queries:

```powershell
# CORRECT: Parameterized query (if the MySQL module supports it)
$result = Invoke-MySqlQuery -Query "SELECT * FROM computers WHERE id = @id" -Parameters @{ id = $Id }

# ACCEPTABLE: Encoding function (legacy pattern)
$safeValue = sqlEncode -String $userInput
$query = "SELECT * FROM table WHERE name = '$safeValue'"

# WRONG: Direct interpolation
$query = "SELECT * FROM table WHERE name = '$userInput'"
```

**Review points:**
- Prefer parameterized queries where the driver supports them
- If using `sqlEncode`, verify it handles backslashes, single quotes, and null bytes
- Flag any unescaped string interpolation in SQL strings

#### Remote Code Execution

Flag any `Invoke-Expression` usage, especially with remote content:

```powershell
# HIGH RISK: Loading and executing remote code
Invoke-RestMethod 'https://example.com/helper.ps1' | Invoke-Expression

# If unavoidable, pin to a specific commit/version
Invoke-RestMethod 'https://raw.githubusercontent.com/user/repo/abc123def/script.ps1' | Invoke-Expression
```

---

### Test Quality Review

#### Coverage

- Every exported function has a matching `.Tests.ps1` file
- Tests cover: parameter validation, happy path, error conditions, edge cases
- External dependencies are mocked (`Mock Invoke-RestMethod`, `Mock Get-ADUser`, etc.)
- No tests rely on network access or external services

#### Mocking

```powershell
# CORRECT: Mock in the module's scope
Mock Invoke-RestMethod -ModuleName 'MyModule' -MockWith {
    return @{ status = 'ok'; data = @() }
}

# Verify the mock was called
Should -Invoke Invoke-RestMethod -ModuleName 'MyModule' -Times 1 -Exactly
```

**Review points:**
- Mocks use `-ModuleName` to target the correct scope
- Mock return values match the real API's structure
- Negative tests verify error handling (mock that throws)
- Tests don't depend on execution order

#### Private Function Testing

```powershell
It 'Should validate input format' {
    InModuleScope $script:Module.Name {
        { ConvertTo-InternalFormat -InputData $null } | Should -Throw
    }
}
```

**Review points:**
- `InModuleScope` is used (private functions aren't visible otherwise)
- The module name is referenced from `$script:Module.Name` (set in `BeforeAll`)
