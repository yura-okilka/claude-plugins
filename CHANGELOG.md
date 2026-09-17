# Changelog

This repo ships independent Claude Code plugins. Version headings use the values from
`plugins/<plugin>/.claude-plugin/plugin.json`; they are **not** git tags.

Entries are newest first.

## toast-notify v1.0.1 - 2026-09-17

### Bug Fixes

- Both hooks now work when Claude Code runs inside **WSL**. `${CLAUDE_PLUGIN_ROOT}` expands
  to a Linux path there, which `powershell.exe -File` cannot open, so every hook failed and
  no toast ever appeared. The hook commands now invoke the script through PowerShell's call
  operator (`-Command "& '<path>'"`) instead of `-File`: that resolves the path through the
  PowerShell provider, and because WSL interop starts the process at
  `\\wsl.localhost\<distro>\...`, the Linux path resolves correctly. Native Windows
  behavior is unchanged.

## toast-notify v1.0.0 - 2026-06-28

Initial release.

### Features

- Desktop toast when **Claude needs your input** (e.g. a permission prompt) via the
  `Notification` hook.
- "Turn complete" toast when **Claude finishes** via the `Stop` hook — suppressed when the
  triggering terminal is already focused, so you're not pinged while watching.
- **Click-to-focus**: clicking the toast brings the originating terminal window to the
  front (Windows Terminal, classic console, VS Code, JetBrains IDEs).
- Each toast shows the originating **`project · branch`** context.
- Self-contained: runs entirely through Claude Code's `Notification`/`Stop` hooks — no
  daemon, no dependencies. Windows 10/11 only; a no-op on macOS/Linux.
