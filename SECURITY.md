# Security Policy

## Overview

This document describes the security posture of the **LLAMA-VSCODE** project, the scope of supported versions, the process for reporting vulnerabilities, and guidance for users operating the project in security-sensitive environments.

---

## Supported Versions

Only the current revision of the `main` branch is actively maintained. There are no versioned releases at this time. Security fixes are applied directly to `main`.

| Branch / State | Supported |
|---|---|
| `main` (current) | Yes |
| Archived forks | No |
| Older local copies | Not applicable |

---

## Scope

This project consists entirely of:

- PowerShell automation scripts
- Windows batch launchers
- Markdown documentation

It does **not** distribute compiled binaries, cryptographic material, or network-facing services beyond orchestrating the startup of `llama-server.exe`.

### In Scope

Security issues relevant to this project include:

- **Script injection risks** in PowerShell or batch files (e.g., unquoted paths, unsafe use of `Invoke-Expression`, unvalidated variable interpolation)
- **Unsafe download behaviour** — missing integrity checks on downloaded files from GitHub or Hugging Face
- **Privilege escalation risks** — if any script incorrectly requests or uses elevated permissions
- **Sensitive data exposure** — accidental logging of tokens, paths, or environment variables containing credentials
- **Endpoint exposure** — server binding to `0.0.0.0` instead of `localhost`, creating unintended LAN exposure

### Out of Scope

The following are explicitly outside the scope of this project's security policy:

- Vulnerabilities in `llama.cpp` itself — report those to [ggml-org/llama.cpp](https://github.com/ggml-org/llama.cpp/security)
- Vulnerabilities in Qwen model weights or Hugging Face infrastructure
- Vulnerabilities in Visual Studio Code or the llama-vscode extension
- Issues caused by user modification of the scripts
- GPU driver or CUDA runtime vulnerabilities

---

## Reporting a Vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

If you discover a security issue within the scope defined above, please report it privately using one of the following methods:

### Option 1: GitHub Private Vulnerability Reporting

Use GitHub's built-in private security advisory feature:

1. Navigate to the repository on GitHub.
2. Click **Security** → **Advisories** → **Report a vulnerability**.
3. Fill in the advisory form with as much detail as possible.

### Option 2: Direct Contact

Contact the author directly via GitHub:

**[@psi16181918161phi](https://github.com/psi16181918161phi)**

Send a private message or use GitHub's contact mechanisms. Do not include the full vulnerability details in any public channel.

---

## What to Include in a Report

A useful vulnerability report includes:

- A clear description of the issue and the security impact
- The affected file(s) and line numbers, if known
- Steps to reproduce or a proof-of-concept (kept private)
- The environment in which you observed the issue (OS version, PowerShell version, execution context)
- Your assessment of severity (Critical / High / Medium / Low)

---

## Response Expectations

| Stage | Target Timeframe |
|---|---|
| Acknowledgement of report | Within 7 days |
| Initial assessment and triage | Within 14 days |
| Fix or documented mitigation | Depends on severity and complexity |
| Public disclosure | After fix is merged to `main`, coordinated with reporter |

This is a solo-maintained project. Response times are best-effort and may vary. Complex or disputed reports may take longer.

---

## Disclosure Policy

This project follows **coordinated disclosure**:

- The reporter and the author work together to agree on a disclosure timeline.
- The fix is merged before public disclosure.
- The reporter will be credited in the security advisory unless they prefer to remain anonymous.

---

## Operational Security Notes for Users

### Network Exposure

By default, the server binds to `127.0.0.1` (localhost only). If you modify the launcher or scripts to bind to `0.0.0.0`, be aware that:

- Any device on your local network will be able to query the inference endpoint.
- There is no authentication layer on the `llama-server` API by default.

Only bind to `0.0.0.0` on a trusted, isolated network.

### Execution Policy

The scripts use:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
```

This is scoped to the current process only and does not permanently alter your system's execution policy. Do not run the scripts with a system-wide policy bypass unless you understand the implications.

### Downloaded Artifacts

The installation script downloads:

- A `llama.cpp` binary release ZIP from `https://api.github.com/repos/ggml-org/llama.cpp/releases/latest`
- A GGUF model file from `https://huggingface.co/`

Both are fetched over HTTPS. The script validates that downloads are non-empty and that ZIPs are valid before extraction, but does **not** currently verify cryptographic signatures or checksums. Users in high-security environments should manually verify SHA-256 hashes against upstream-published values before running the server.

### Antivirus Compatibility

Some endpoint protection products flag llama.cpp binaries as potentially unwanted applications due to their ability to execute arbitrary model inference. This is a false positive. Review your security policy before adding exclusions.

---

## Known Security Limitations

| Limitation | Notes |
|---|---|
| No checksum verification of downloaded binaries | Relies on HTTPS and GitHub/HuggingFace infrastructure integrity |
| No authentication on inference endpoints | By design for local-only use; do not expose to untrusted networks |
| Credentials must not be placed in script variables | Scripts do not accept or store credentials; ensure no credentials are present in environment variables passed to the server |

---

*This security policy was last reviewed on 2026-06-12.*
