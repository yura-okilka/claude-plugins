# Changelog

This repo ships independent Claude Code plugins. Version headings use the values from
`<plugin>/.claude-plugin/plugin.json`; they are **not** git tags. Bumping a plugin's
`version` and pushing to `main` is what delivers an update to users — see the repo
[README](README.md#updates).

Entries are newest first.

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
