# Copilot Workspace Instructions

This workspace is configured for local llama.cpp with stable laptop-safe settings.

## Model policy
- Use only these local models:
  - C:\AI_Models\qwen2.5-coder-3b-instruct-q4_k_m.gguf
  - C:\AI_Models\qwen2.5-coder-0.5b-instruct-q2_k.gguf
- Do not suggest 14B model usage in this workspace.

## Runtime policy
- Prefer conservative defaults:
  - 3B: --ctx-size 3072 -ngl 16 --threads 6
  - 0.5B: --ctx-size 2048 -ngl 8 --threads 4
- Keep llama-vscode endpoints aligned:
  - tools: http://localhost:8009
  - chat: http://localhost:8011
  - completion: http://localhost:8012

## Troubleshooting policy
- First verify model file integrity and server endpoint health.
- Prefer reducing ctx-size and ngl before any other tuning.
