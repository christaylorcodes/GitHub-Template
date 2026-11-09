# Security Policy

## Supported Versions

We actively support the following versions of this project with security updates:

| Version | Supported          |
| ------- | ------------------ |
| Latest  | :white_check_mark: |
| < 1.0   | :x:                |

> **Note:** As a template repository, security primarily concerns the automation scripts (PowerShell) and any dependencies they may have. Once you use this template for your own project, please update this section with your project's specific version support policy.

## Reporting a Vulnerability

We take the security of this template and its users seriously. If you believe you have found a security vulnerability, please report it to us as described below.

### Where to Report

**Please do NOT report security vulnerabilities through public GitHub issues.**

Instead, please report them via one of the following methods:

1. **GitHub Security Advisories** (Preferred)
   - Navigate to the repository's Security tab
   - Click "Report a vulnerability"
   - Fill out the security advisory form with details

2. **Direct Email**
   - Send an email to: **security@christaylor.codes**
   - Use the subject line: `[SECURITY] Project Name - Brief Description`

3. **Private Message on Slack**
   - Contact **@CTaylor** on [MSPGeek Slack](https://join.mspgeek.com/)
   - Clearly mark the message as security-related

### What to Include

Please include the following information in your report to help us better understand and resolve the issue:

- **Type of issue** (e.g., code injection, privilege escalation, information disclosure)
- **Full paths of source file(s)** related to the manifestation of the issue
- **Location of the affected source code** (tag/branch/commit or direct URL)
- **Step-by-step instructions to reproduce the issue**
- **Proof-of-concept or exploit code** (if possible)
- **Impact of the issue**, including how an attacker might exploit it
- **Any special configuration required** to reproduce the issue
- **Your assessment of severity** (Critical, High, Medium, Low)

### What to Expect

After you submit a vulnerability report:

1. **Acknowledgment** - We will acknowledge receipt of your vulnerability report within **48 hours**
2. **Initial Assessment** - We will provide an initial assessment of the vulnerability within **5 business days**
3. **Updates** - We will keep you informed of the progress toward a fix and full announcement
4. **Verification** - We may ask you to verify that our fix resolves the vulnerability
5. **Public Disclosure** - We will coordinate with you on the timing of public disclosure
6. **Credit** - We will credit you in the security advisory (unless you prefer to remain anonymous)

### Response Timeline

| Phase | Timeline |
|-------|----------|
| Acknowledgment | 48 hours |
| Initial Assessment | 5 business days |
| Fix Development | Varies by severity |
| Release | Coordinated with reporter |

### Severity Levels

We use the [CVSS v3.1](https://www.first.org/cvss/calculator/3.1) scoring system to assess vulnerability severity:

- **Critical (9.0-10.0)** - Fix within 24-48 hours
- **High (7.0-8.9)** - Fix within 1 week
- **Medium (4.0-6.9)** - Fix within 2-4 weeks
- **Low (0.1-3.9)** - Fix in next regular release

## Security Best Practices for Template Users

When using this template for your own project, please:

1. **Keep Dependencies Updated**
   - Regularly update PowerShell modules and any other dependencies
   - Enable Dependabot alerts in your repository settings

2. **Secure Your Secrets**
   - Never commit sensitive information (API keys, passwords, tokens)
   - Use environment variables or secure secret storage
   - Review the `.gitignore` to ensure sensitive files are excluded

3. **Code Review**
   - Review all scripts before execution, especially `Scripts\Initialize-Repository.ps1`
   - Understand what automation scripts do before running them
   - Use `-WhatIf` parameter when available

4. **PowerShell Execution Policy**
   - Be cautious when using `-ExecutionPolicy Bypass`
   - Prefer signed scripts in production environments
   - Review script signatures when available

5. **Regular Security Audits**
   - Run `./Tests/test-local.ps1` (build, PSScriptAnalyzer, Pester) before every push
   - Review and update this SECURITY.md for your project's needs
   - Monitor GitHub security advisories for dependencies

## Known Security Considerations

### PowerShell Script Execution

The template includes PowerShell scripts that modify files on your system:
- `Scripts\Initialize-Repository.ps1` - Modifies template files and deletes template-only files (run once)
- `Scripts\Test-Template.ps1` - Template-maintainer check only (removed by initialization); reads files and makes web requests when link checking is enabled
- `Scripts\New-TemplateBadges.ps1` - Template-maintainer tool (removed by initialization); can modify README.md

**Recommendations:**
- Review scripts before execution
- Run with least privilege necessary
- Test in a safe environment first
- Keep backups before running automation

### External Dependencies

This template may reference or suggest external services:
- shields.io for badges
- GitHub Actions for CI/CD
- Package managers (PowerShell Gallery, npm, etc.)

**Recommendations:**
- Verify the integrity of external resources
- Use trusted, official package sources
- Review CI/CD workflows before enabling
- Understand third-party service terms and privacy policies

## Security Update Policy

### For This Template Repository

Security updates for this template will be released as follows:

1. **Critical vulnerabilities** - Immediate patch release
2. **High severity vulnerabilities** - Patch within 1 week
3. **Medium/Low severity** - Included in next regular release

### For Your Project (Update This)

When you use this template for your own project, update this section with:
- Your project's update schedule
- Supported version policy
- How users should update
- Communication channels for security announcements

## Security Hall of Fame

We appreciate security researchers who responsibly disclose vulnerabilities. Contributors will be listed here (with permission):

<!-- When you find security researchers, list them here
- **Researcher Name** - [Brief description] - [Date]
-->

_No vulnerabilities reported yet._

## Additional Resources

- [GitHub Security Best Practices](https://docs.github.com/en/code-security)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [PowerShell Security Best Practices](https://docs.microsoft.com/en-us/powershell/scripting/security/overview)
- [National Vulnerability Database](https://nvd.nist.gov/)

## Questions?

If you have questions about this security policy or the security posture of this template, please:

1. Check the [Discussions](../../discussions) section
2. Open a general (non-security) issue
3. Contact the maintainers through community Slack channels

---

**Last Updated:** 2025-01-22
