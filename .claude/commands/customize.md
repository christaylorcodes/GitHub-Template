---
description: Guided project customization after template initialization
allowed-tools: Read, Edit, Write, Glob, Grep, Bash, AskUserQuestion
---

You are helping the user customize their project after it was created from the GitHub Template. Read `docs/CUSTOMIZATION_GUIDE.md` (may still be named `docs/AI_SETUP_GUIDE.md` if the init script hasn't run yet) for the full reference.

## Step 1: Check initialization status

Check whether `Scripts/Initialize-Repository.ps1` still exists.

- **If it exists:** The template hasn't been initialized yet. Gather the required information from the user (module name, description, author, GitHub username) and run the script first. Use `-WhatIf` to preview, then run for real. See section 1 of the customization guide for the full parameter list.
- **If it doesn't exist:** Initialization is done. Proceed to customization.

## Step 2: Assess current state

Read these files to understand what still needs customization:

- `README.md` -- does the prose still describe the template?
- `SECURITY.md` and `CODE_OF_CONDUCT.md` -- do they still say `yourdomain.com`?
- `CONTRIBUTING.md` -- does the title still reference the template?
- `CHANGELOG.md` -- does it still have template version history?
- `README.md` badge URLs -- do they point to real CI/CD or placeholder URLs?

Tell the user what you found and what needs updating.

## Step 3: Customize interactively

Work through each item that needs attention. Ask the user for input where needed:

1. **README.md** -- Rewrite the description, tagline, and getting-started sections for the actual project. Keep the structure but replace template marketing copy.
2. **CONTRIBUTING.md** -- Update or remove Slack links. Ensure the title reflects this project.
3. **Contact emails** -- Ask for real email addresses to replace `yourdomain.com` in SECURITY.md and CODE_OF_CONDUCT.md.
4. **Badges** -- Update badge URLs once the user confirms their CI/CD setup.
5. **CHANGELOG.md** -- Write a meaningful first entry for this project.

## Step 4: Adapt existing code (if applicable)

Ask the user if they have existing PowerShell code to bring into this project. If yes:

1. Help them identify which functions are public vs private
2. Copy functions into `source/Public/` and `source/Private/` (one per file)
3. Create matching test files using the templates in `Templates/`
4. Update the module manifest (`RequiredModules`, `Tags`, etc.)
5. Run `Import-Module ./source/<ModuleName>.psd1 -Force` to verify it loads

## Step 5: Validate

Run these checks and report results:

```powershell
# Check for leftover placeholders
git grep "YOUR-USERNAME"
git grep "YOUR-REPO"
git grep "yourdomain.com"
git grep "christaylorcodes"

# Verify module loads
Import-Module "./source/<ModuleName>.psd1" -Force

# Run tests
./Tests/test-local.ps1
```

## Step 6: Report remaining manual steps

Tell the user what they still need to do by hand:

- Replace `docs/media/Logo.png` with their project logo
- Replace `docs/media/Demo.gif` with a project demo
- Set up `PSGALLERY_API_KEY` repository secret (for publishing)
- Run `Scripts/Initialize-Labels.ps1` for AI workflow labels (optional)
- Configure GitHub repo settings (branch protection, topics)
