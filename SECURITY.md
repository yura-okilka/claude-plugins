# Security Policy

## What these plugins do on your machine

This marketplace currently ships one plugin, **toast-notify** — Claude Code hooks that
show native Windows toast notifications. It's worth being explicit about what it touches:

- **No network access.** Nothing phones home; the hooks make no outbound connections.
- **No elevation.** Everything runs as the current user — no admin rights, no UAC prompt.
- **Registry writes are limited to two `HKCU` keys**, created on first run:
  - `HKCU\Software\Classes\AppUserModelId\Claude.Code.Toast` — so the toast is attributed
    to "Claude Code" with its icon.
  - `HKCU\Software\Classes\claudecode` — the `claudecode:` protocol used for
    click-to-focus.

  Both are per-user (never `HKLM`), and the [README](toast-notify/README.md#uninstalling)
  documents how to remove them.
- **No files are written outside the plugin folder**, and nothing keeps running between
  notifications — the hooks execute, show the toast, and exit.
- Runs under Windows PowerShell (`powershell.exe`). On macOS/Linux the hook simply has no
  effect.

## Supported versions

Only the latest published version of each plugin is supported. Fixes ship as new versions.

## Reporting a vulnerability

Please report security issues privately rather than in a public issue:

- Use GitHub's **private vulnerability reporting** on this repository (the **Security** tab
  → **Report a vulnerability**), or
- Open a minimal public issue asking to be contacted, without disclosing details.

I'll acknowledge reports as soon as I can and aim to address valid issues promptly.
