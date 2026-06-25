# toast-notify

Native **Windows toast notifications** (Windows 10 and 11) for Claude Code. When Claude needs your
attention (a permission prompt, or a turn completing), you get a real Windows toast
attributed to **Claude Code** — and **clicking it brings the terminal window that
triggered it back to the foreground**.

> **Windows only.** This plugin uses `powershell.exe`, WinRT toast APIs, and an HKCU
> registry write. On macOS/Linux the hook simply errors per event (non-fatal) and does
> nothing.

## What it does

- Fires a toast on the `Notification` event (e.g. a permission prompt).
- Fires a toast on the `Stop` event (turn complete) **only when the triggering terminal
  is not already the foreground window** (`-OnlyIfUnfocused`) — so you aren't toasted on
  every turn while you're actively watching.
- On click, walks the hook's parent process chain to find the terminal window that
  launched Claude (Windows Terminal, conhost, VS Code, JetBrains Rider, …) and focuses
  it via a registered `claudecode:` protocol handler.
- Adds a small context line showing the project folder and git branch (from the hook's
  `cwd`), e.g. `my-project · main` — best-effort, omitted if `cwd` isn't a git repo.

## Install

```text
/plugin marketplace add yura-okilka/claude-plugins
/plugin install toast-notify@yura-okilka
```

Restart Claude Code (or run `/reload-plugins`) and trigger any notification to test.

## Files

| File | Purpose |
| ---- | ------- |
| `hooks/hooks.json` | Registers the `Notification` and `Stop` hooks. |
| `hooks/notify-toast.ps1` | Builds and shows the toast; registers the AppUserModelId + `claudecode:` protocol; captures the triggering window. |
| `hooks/focus-window.ps1` | Brings a window to the foreground (P/Invoke into `user32`, with the `AttachThreadInput` trick to beat the foreground lock). |
| `hooks/focus-launch.vbs` | Hidden launcher so clicking the toast causes no console flash. |
| `hooks/claude.png` | The toast icon (96×96). |

## Known limitations

- **Window, not tab.** It focuses the *window*; there is no public API to switch to a
  specific terminal tab/pane in Windows Terminal, VS Code, or Rider.
- **Multi-window single-process** hosts (some Windows Terminal configs) focus the
  process's main window, which may not be the exact one.
- **Foreground steal** is reliable in the common case; Windows' focus-stealing
  prevention may occasionally flash the taskbar instead of switching.

## Uninstall / notes

- If you previously added these hooks directly to `~/.claude/settings.json`, remove
  those `Notification`/`Stop` blocks after installing — otherwise toasts fire twice.
- The `claudecode:` protocol registration self-heals: `notify-toast.ps1` rewrites it
  (idempotently) on each run, so it always points at the current plugin version.
