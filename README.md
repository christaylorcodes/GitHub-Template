<h1 align="center">
  <br>
  <img src="./docs/media/Logo.png" alt="logo" height = 300 ></a>
  <br>
  GitHub Template
  <br>
</h1>

<h4 align="center">

A production-ready PowerShell module template with built-in CI/CD, testing, and AI-assisted development.

</h4>

<div align="center">

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen?logo=github)](https://github.com/YOUR-USERNAME/YOUR-REPO/actions)
[![Code Quality](https://img.shields.io/badge/code%20quality-A-brightgreen?logo=codacy)](https://www.codacy.com/YOUR-PROJECT)
[![Version](https://img.shields.io/badge/version-1.0.0-blue?logo=powershell&logoColor=white)](https://www.powershellgallery.com/packages/YOUR-PACKAGE)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Security](https://app.aikido.dev/assets/badges/label-only-dark-theme.svg)](https://app.aikido.dev/audit-report/external/WbAGYSkx7t09VOUAKIlmHeVh/request)

</div>

<p align="center">
    <a href="#whats-included">What's Included</a> •
    <a href="#getting-started">Getting Started</a> •
    <a href="#documentation">Documentation</a> •
    <a href="#ai-agents">AI Agents</a> •
    <a href="#project-structure">Project Structure</a> •
    <a href="#contributing">Contributing</a>
</p>

---

This template gives you everything needed to publish a professional PowerShell module — build pipeline, Pester tests, PSScriptAnalyzer, GitHub Actions CI/CD, and PowerShell Gallery publishing — all wired together and ready to go. It's the standard base for all [Chris Taylor Codes](https://github.com/christaylorcodes) projects, and other repos reference back here for shared conventions and tooling.

<p align="center">
  <img src="./docs/media/Demo.gif" alt="Demo" width = 70% ></a>
</p>

## What's Included

| Category | What You Get | Details |
| -------- | ------------ | ------- |
| **Build System** | Sampler/ModuleBuilder pipeline with Clean, Build, Test, and Publish tasks | [AGENTS.md — Build System](AGENTS.md#build-system) |
| **Testing** | Pester 5.6+ with code coverage (JaCoCo) and NUnit results | [AGENTS.md — Test Framework](AGENTS.md#test-framework) |
| **Code Quality** | PSScriptAnalyzer with tuned rule set and editor integration | [.PSScriptAnalyzerSettings.psd1](.PSScriptAnalyzerSettings.psd1) |
| **CI/CD Workflows** | GitHub Actions for testing, analysis, and PSGallery publishing | [AGENTS.md — CI/CD](AGENTS.md#cicd) |
| **Module Structure** | Auto-discovering `source/` layout with Classes, Private, and Public folders | [AGENTS.md — Architecture](AGENTS.md#architecture) |
| **Documentation** | Comment-based help, platyPS markdown docs, usage guides | [docs/](docs/) |
| **Templates** | Boilerplate for new functions, classes, and Pester tests | [Templates/](Templates/) |
| **Automation Scripts** | Repository initialization, validation, badge generation, label setup | [Scripts/](Scripts/) |
| **Community Files** | Contributing guide, code of conduct, security policy, issue/PR templates | [CONTRIBUTING.md](.github/CONTRIBUTING.md) |
| **AI Agent Support** | AGENTS.md, CLAUDE.md, AI issue labels, structured task templates | [AI Agents](#ai-agents) |

## Getting Started

### 1. Create your repo from the template

Click **"Use this template"** at the top of this repository, name your new repo, and clone it locally.

### 2. Let the agent set it up

Open the project in your AI coding tool (Claude Code, GitHub Copilot, Cursor, etc.) and tell it:

> Help me initialize this as a new PowerShell module. Read AGENTS.md for project context.

The agent will walk you through naming your module, running the initialization script, updating placeholders, and validating the result — no checklist required.

### 3. Or run the script directly

```powershell
.\Scripts\Initialize-Repository.ps1 -Name "MyModule" `
                                     -Description "What it does" `
                                     -Author "Your Name" `
                                     -GitHubUsername "your-username" `
                                     -InitializeGit
```

This renames module files, populates the manifest, replaces all placeholders, and initializes git.

> For manual step-by-step setup, badge generation, validation, and troubleshooting, see the [Template Usage Guide](docs/TEMPLATE_USAGE.md).

## Documentation

| Document | Audience | Description |
| -------- | -------- | ----------- |
| [AGENTS.md](AGENTS.md) | AI agents and developers | Architecture, build commands, code conventions, and contribution workflow |
| [Template Usage Guide](docs/TEMPLATE_USAGE.md) | Template users | Detailed setup walkthrough, customization checklist, and common issues |
| [Module Usage](docs/USAGE.md) | Module consumers | Installation, quick start, and function reference |
| [Publishing Guide](docs/PUBLISHING.md) | Maintainers | Publishing to PowerShell Gallery with CI/CD |
| [Contributing](.github/CONTRIBUTING.md) | Contributors | How to report bugs, request features, and submit PRs |
| [Changelog](CHANGELOG.md) | Everyone | Version history and release notes |
| [Security Policy](.github/SECURITY.md) | Security researchers | Supported versions, reporting vulnerabilities, response timelines |
| [Code of Conduct](.github/CODE_OF_CONDUCT.md) | Community | Behavioral expectations and enforcement |

## AI Agents

This repository is designed for AI-assisted development from the ground up. Whether you're using Claude Code, GitHub Copilot, Cursor, Windsurf, or another AI coding tool, the agents have everything they need to contribute effectively.

**For agents working in this repo:**

- [AGENTS.md](AGENTS.md) — Full project context: architecture, build commands, conventions, and workflow
- [CLAUDE.md](CLAUDE.md) — Claude Code session workflow and planning system

**For agents working in other repos that use this template:**

- Link back to this repo's [AGENTS.md](AGENTS.md) for shared conventions
- The same build system, test framework, and code style apply across all projects

**AI workflow features:**

- Issue templates structured for AI consumption (`ai-task`, `ai-ready` labels)
- PR template with AI contribution checkbox
- [Initialize-Labels.ps1](Scripts/Initialize-Labels.ps1) sets up AI workflow labels on your repo

## Project Structure

```text
your-module/
  build.ps1                      # Sampler bootstrap and task runner
  build.yaml                     # Build pipeline configuration
  RequiredModules.psd1           # Build dependency specifications
  source/
    ModuleName.psd1              # Module manifest
    ModuleName.psm1              # Root module (auto-loads subdirectories)
    Classes/                     # PowerShell class definitions
    Private/                     # Internal helper functions
    Public/                      # Exported functions (one per file)
  Tests/
    Unit/Public/                 # Tests for exported functions
    Unit/Private/                # Tests for internal functions
    Integration/                 # Integration tests
  Templates/                     # Boilerplate for new functions and tests
  Scripts/                       # Automation (init, validate, badges, labels)
  docs/                          # Guides, help files, examples
    media/                       # Logo, demo GIF, media assets
```

See [AGENTS.md — Architecture](AGENTS.md#architecture) for the full layout, module loading order, and build system details.

## Contributing

If you find this template useful, give it a star so others can find it too. For bugs, features, and PRs, see the [contributing guide](.github/CONTRIBUTING.md). Contributions of all kinds are welcome — you don't need to write code to help.

## [Support](docs/DONATE.md)

If this template saves you time, consider [buying me a beer](docs/DONATE.md).
