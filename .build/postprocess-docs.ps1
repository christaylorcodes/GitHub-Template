# Custom build tasks for the 'docs' workflow (loaded automatically by build.ps1
# from the .build/ folder, after Sampler's tasks).

# build.yaml keys are NOT automatically InvokeBuild properties: Sampler's PlatyPS tasks
# read $HelpSourceFolder via 'property', which only sees variables and environment
# variables. Map the build.yaml value here (an env var still wins) so it is honored.
if ($BuildInfo.HelpSourceFolder -and -not $env:HelpSourceFolder) {
    $HelpSourceFolder = $BuildInfo.HelpSourceFolder
}

# Synopsis: Cleans up PlatyPS placeholders in the generated markdown help.
task Postprocess_PlatyPS_docs {
    $docsScript = Join-Path -Path $BuildRoot -ChildPath 'Scripts/Update-PlatyPSDocs.ps1'

    if (-not (Test-Path $docsScript)) {
        Write-Build Yellow "  Skipping: '$docsScript' not found."
        return
    }

    $helpFolder = Get-SamplerAbsolutePath -Path $HelpSourceFolder -RelativeTo $BuildRoot
    $localeFolder = Join-Path -Path $helpFolder -ChildPath 'en-US'

    Write-Build White "  Running post-processing on PlatyPS docs in '$localeFolder'..."
    & $docsScript -DocsPath $localeFolder
}

# Synopsis: Fails the build if MAML help was not produced. Sampler runs PlatyPS
# in a child process and does not check its exit code, so without this a broken
# docs build still reports success.
task Assert_MAML_help_generated {
    . Set-SamplerTaskVariable

    $helpPath = Join-Path $builtModuleBase 'en-US'
    $mamlFiles = @(Get-ChildItem -Path $helpPath -Filter '*-help.xml' -File -ErrorAction SilentlyContinue)

    if ($mamlFiles.Count -eq 0) {
        throw "No MAML help (*-help.xml) found under '$helpPath'. Check the PlatyPS output above for errors."
    }

    foreach ($file in $mamlFiles) {
        Write-Build Green "  Found MAML help: $($file.Name)"
    }
}
