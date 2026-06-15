# Contributing to LLAMA-VSCODE

Thank you for your interest in contributing. This document describes the standards, workflow, and expectations for contributions to this project.

> **Before contributing**, please read the [LICENSE.md](LICENSE.md). By submitting any contribution, you confirm that you have read and agree to its terms, including the NonCommercial and ShareAlike clauses of the CC BY-NC-SA 4.0 license.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [What Contributions Are Welcome](#what-contributions-are-welcome)
- [What to Avoid](#what-to-avoid)
- [Getting Started](#getting-started)
- [Branch and Commit Conventions](#branch-and-commit-conventions)
- [Pull Request Process](#pull-request-process)
- [Reporting Bugs](#reporting-bugs)
- [Suggesting Enhancements](#suggesting-enhancements)
- [Style Guidelines](#style-guidelines)
- [Attribution Policy](#attribution-policy)

---

## Code of Conduct

This project operates under a minimal but firm code of conduct. Contributors are expected to:

- Communicate respectfully in issues, pull requests, and discussions.
- Provide clear and substantive technical reasoning when proposing changes.
- Avoid off-topic commentary, political content, and personal disputes in project spaces.

Contributions that violate these expectations will be closed without engagement.

---

## What Contributions Are Welcome

The following types of contributions are actively welcomed:

- **Bug fixes** — corrections to script logic, path handling, error messages, or launcher generation
- **Compatibility improvements** — support for additional PowerShell versions, CUDA builds, or Windows editions
- **Documentation improvements** — corrections, clarifications, improved examples, and accuracy fixes in any `.md` file
- **Hardware profile additions** — conservative, tested runtime profiles for specific GPU/RAM configurations
- **Model support** — adding support for additional GGUF-compatible Qwen models (or other models of similar scale), documented with validation results
- **Validation and testing** — additional checks in `Validate-InlineChatFeatures.ps1` or equivalent test scripts
- **Endpoint alignment** — updates to port assignments or server flag handling that improve llama-vscode compatibility

---

## What to Avoid

The following will not be accepted:

- **Adding large model support (14B+).** This project explicitly targets conservative hardware. Do not add profiles that require more than 16 GPU layers or exceed the VRAM envelope of the primary supported hardware.
- **Cloud service integration.** This project is intentionally offline-first. Pull requests that introduce cloud API calls, telemetry, or external authentication will be rejected.
- **Changing the licensing terms.** Do not submit changes to `LICENSE.md` that weaken attribution, remove NonCommercial restrictions, or alter the ShareAlike requirement without discussion with the author first.
- **Vendored binaries.** Do not commit compiled executables, GGUF model weights, or third-party binary files.
- **Breaking changes to documented endpoint assignments.** The port layout (`8009`, `8011`, `8012`) is fixed by design. Changes require a documented justification and backward-compatibility handling.

---

## Getting Started

1. **Fork the repository** on GitHub.
2. **Clone your fork** locally:
   ```powershell
   git clone https://github.com/<your-handle>/LLAMA-VSCODE.git
   cd LLAMA-VSCODE
   ```
3. **Create a feature branch** (see naming conventions below).
4. Make your changes.
5. **Test your changes** against the validation script:
   ```powershell
   .\scripts\Validate-InlineChatFeatures.ps1 -Verbose
   ```
6. **Validate model profiles**:
   ```powershell
   . .\scripts\Validate-ModelProfile.ps1
   Get-ChildItem .\models -Filter *.json |
     Where-Object { $_.Name -ne 'model-profile.schema.json' } |
     ForEach-Object { Test-ModelProfileFile -ProfilePath $_.FullName -SchemaPath .\models\model-profile.schema.json }
   ```
7. **Run Pester tests**:
   ```powershell
   Invoke-Pester -Path .\tests
   ```
8. Commit, push, and open a pull request.

---

## Branch and Commit Conventions

### Branch Names

Use the format `<type>/<short-description>`:

| Type | Use |
|---|---|
| `fix/` | Bug fix |
| `feat/` | New feature or model support |
| `docs/` | Documentation-only change |
| `refactor/` | Code restructuring without behaviour change |
| `test/` | Validation or test improvements |

Examples:
- `fix/zip-extraction-path`
- `docs/improve-quickstart`
- `feat/add-0.5b-cuda-profile`

### Commit Messages

Follow the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) format:

```
<type>(<scope>): <short summary>

[optional body]

[optional footer]
```

Examples:
```
fix(launcher): correct model path check for 0.5B batch file
docs(readme): add troubleshooting note for CUDA 12 builds
feat(watcher): support LLAMA_PORT_CHAT environment variable override
```

Commits must be atomic: one logical change per commit.

---

## Pull Request Process

1. **Open a draft PR early** if you want early feedback on direction.
2. Fill in the PR description with:
   - A summary of what changed and why
   - How you tested the change
   - Any known limitations or follow-up work
3. Ensure the validation script passes:
   ```powershell
   .\scripts\Validate-InlineChatFeatures.ps1
   ```
4. Ensure tests pass:
   ```powershell
   Invoke-Pester -Path .\tests
   ```
5. Address all review feedback before requesting a final review.
6. **Do not force-push** to a PR branch after review has started.
7. The project maintainer reserves the right to merge, close, or request changes on any PR without a time commitment.

---

## Reporting Bugs

Open an issue on GitHub with the following information:

- **Operating system and version** (e.g., Windows 11 23H2)
- **PowerShell version** (`$PSVersionTable`)
- **CUDA version and GPU model**
- **llama.cpp version in use** (if known)
- **Steps to reproduce** — exact commands run
- **Observed behaviour** — what actually happened
- **Expected behaviour** — what you expected to happen
- **Relevant log output** — from `$env:TEMP\llama-server-watcher.log` or the terminal

Do not open issues for upstream `llama.cpp` bugs or Hugging Face model availability issues unless you have confirmed they are caused by this project's automation code.

---

## Suggesting Enhancements

Open an issue with the label `enhancement` and include:

- A clear description of the problem you are solving or capability you want to add
- Why this fits within the project's scope (see [ABOUT.md](ABOUT.md))
- Any relevant references (documentation, upstream issues, benchmarks)

Enhancement requests that contradict the design philosophy documented in [ABOUT.md](ABOUT.md) will be closed with a brief explanation.

---

## Style Guidelines

### PowerShell

- Use `PascalCase` for functions and `camelCase` for local variables.
- Prefer full cmdlet names over aliases (`Get-ChildItem`, not `ls` or `dir`).
- Include `[CmdletBinding()]` on all functions that accept parameters.
- Use `Write-Host` only for user-facing output; use `Write-Verbose` for diagnostic messages.
- Avoid `Invoke-Expression`. Use structured argument arrays with the call operator `&` instead.
- Wrap external executable calls in error-checking (`$LASTEXITCODE` or `try/catch`).

### Batch Files (`.bat`)

- Keep launchers minimal. Complex logic belongs in PowerShell scripts, not batch files.
- Document every environment variable the launcher reads at the top of the file.
- Verify prerequisites (`llama-server.exe`, model file) before starting the server.

### Documentation (`.md`)

- Use ATX-style headings (`#`, `##`, `###`).
- Use fenced code blocks with a language specifier for all code samples.
- Tables should be used for structured comparisons; avoid prose lists when a table is clearer.
- Keep line length under 120 characters where possible.

---

## Attribution Policy

All contributors who have a pull request merged will be acknowledged in the project's contributor list. The project author retains the copyright on the original work. Derivative contributions are subject to CC BY-NC-SA 4.0.

If your contribution includes substantial original code or documentation, you may add your name to the file header or contributor section in the pull request.

---

## Questions

For questions not covered here, open a GitHub Discussion or contact the author directly at:

**[@psi16181918161phi](https://github.com/psi16181918161phi)**
