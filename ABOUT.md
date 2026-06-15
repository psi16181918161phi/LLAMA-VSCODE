# About LLAMA-VSCODE

## What This Project Is

**LLAMA-VSCODE** is a professional Windows deployment toolkit for running a local [llama.cpp](https://github.com/ggml-org/llama.cpp) inference server and integrating it with Visual Studio Code as a native code-completion and AI chat backend — without relying on any external cloud service.

The project targets developers who want a fully local, private, and reproducible AI coding assistant running on consumer-grade Windows hardware with an NVIDIA GPU. It is designed to be simple to deploy, conservative by default, and easy to adapt.

---

## Motivation

Cloud-hosted AI assistants have real limitations: they require internet access, they expose code to remote servers, and they incur per-token costs or subscription fees. For environments where data privacy matters, where internet access is unreliable or restricted, or where operational cost is a constraint, a local inference stack is the right architectural choice.

This project exists to eliminate the manual steps typically required to stand up that stack on Windows: finding the correct llama.cpp binary, resolving the right model file from Hugging Face, configuring VS Code endpoints, and keeping everything consistent across restarts.

---

## Design Philosophy

- **Conservative defaults.** Hardware profiles, GPU layer counts, and context window sizes are set conservatively to avoid crashes on mid-range laptops. The project explicitly targets machines that cannot safely run 14B+ parameter models.
- **Profile-driven extensibility.** Any supported GGUF model can be onboarded through validated profile JSON, instead of hardcoding values in scripts.
- **Automation without magic.** Every step the script performs is transparent and documented. There are no hidden registry writes, no unsigned executable installs, and no telemetry.
- **Idempotency.** Re-running any script or launcher produces the same result as the first run.
- **Minimal footprint.** The project writes only to a small set of well-documented paths (`C:\llama_cpp`, `C:\AI_Models`, `%APPDATA%\Code\User`) and does not modify system-wide settings.
- **Offline-first after setup.** Once the model and binaries are downloaded, the server runs entirely offline. No API keys, no network dependencies.

---

## What It Is Not

- It is not a model training or fine-tuning toolkit.
- It is not a replacement for Copilot's cloud features — it is a complement or substitute for users who prefer local inference.
- It does not distribute model weights or llama.cpp binaries. Those are fetched at runtime from their respective upstream sources under their own licenses.
- It does not support Linux, macOS, or WSL natively. All scripts target the Windows PowerShell environment.

---

## Target Hardware

| Specification | Minimum | Recommended |
|---|---|---|
| GPU | NVIDIA GTX 1650 (4 GB VRAM) | NVIDIA RTX 3060 (8 GB VRAM) or better |
| CUDA | 11.x | 12.x |
| RAM | 8 GB | 16 GB |
| Storage | 8 GB free | 20 GB free (for multiple models) |
| OS | Windows 10 (64-bit) | Windows 11 (64-bit) |

---

## Supported Models

| Model | Size | Use Case |
|---|---|---|
| `qwen2.5-coder-3b-instruct-q4_k_m.gguf` | ~2.0 GB | Primary — code completion, inline chat |
| `qwen2.5-coder-0.5b-instruct-q2_k.gguf` | ~300 MB | Fallback — very low VRAM systems |

The repository ships with two starter profiles sourced from [Qwen](https://huggingface.co/Qwen). Additional models can be installed from any Hugging Face GGUF repository using `-HfRepo` and `-HfFile`, then persisted as validated profiles in `models/`.

---

## Endpoints

The deployment configures three dedicated endpoints:

| Endpoint | Port | Purpose |
|---|---|---|
| Tools | `8009` | Primary llama-vscode tools endpoint |
| Chat | `8011` | Chat completions |
| Completion | `8012` | FIM / inline completion |

These are the default port assignments expected by the [llama-vscode](https://github.com/ggml-org/llama.cpp/tree/master/tools/llama-vscode) VS Code extension.

---

## Author

**Hadrian**  
GitHub: [@psi16181918161phi](https://github.com/psi16181918161phi)

This project is a personal engineering effort. Contributions, bug reports, and forks are welcome under the terms described in [LICENSE.md](LICENSE.md).

---

## License Summary

This project is released under the **Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License (CC BY-NC-SA 4.0)** with additional restrictions.  
See [LICENSE.md](LICENSE.md) for the full terms.
