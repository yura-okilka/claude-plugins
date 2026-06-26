# toast-notify

Desktop notifications for Claude Code on Windows — so you can look away while Claude
works and get pinged the moment it needs you or finishes. **Click the notification to
jump straight back to the terminal that sent it.**

> **Works on Windows 10 and 11.** On macOS/Linux it simply has no effect (the hook can't
> run, and Claude Code ignores that) — safe to leave installed in a shared config.

## What you get

- A notification when **Claude needs your input** — like a permission prompt.
- A "turn complete" notification when **Claude finishes** — but only if you've clicked
  away, so you're not pinged while you're already watching.
- **Click it and the right terminal window comes to the front.** Works with Windows
  Terminal, the classic console, VS Code, and JetBrains IDEs.
- Each notification shows **which project and git branch** it came from (e.g.
  `my-project · main`), so you can tell sessions apart at a glance.

## Install

```text
/plugin marketplace add yura-okilka/claude-plugins
/plugin install toast-notify@yura-okilka
```

Then restart Claude Code (or run `/reload-plugins`) and trigger any notification to try it.

## Good to know

- It focuses the **window**, not a specific tab — Windows has no way to switch to a
  particular terminal tab, so if Claude's session is in a background tab you'll land on
  the window and may need to click over to the tab.
- Bringing the window forward works in everyday use; once in a while Windows' focus rules
  flash the taskbar button instead of switching.

## How it works (for the curious)

Everything runs through Claude Code's `Notification` and `Stop` hooks — no daemon, no
dependencies, nothing running between notifications. Each hook pipes its JSON payload to a
Windows PowerShell script on stdin.

**The toast.** `notify-toast.ps1` builds a native Windows toast via the WinRT
`ToastNotificationManager` (that's why it runs under `powershell.exe` 5.1, not pwsh 7). On
first run it registers an AppUserModelId under `HKCU\Software\Classes\AppUserModelId` so
the toast is attributed to **Claude Code** with the bundled icon. The `Stop` hook passes
`-OnlyIfUnfocused`, which suppresses the toast when the triggering terminal is already the
foreground window.

**Click-to-focus.** The toast is built with `activationType="protocol"` and a `launch`
URI like `claudecode:focus?hwnd=…&pid=…`, carrying the handle of the terminal that fired
the hook (found by walking the hook's parent process chain up to the first window-owning
ancestor). Clicking it invokes a `claudecode:` protocol handler registered in `HKCU`,
which runs `focus-launch.vbs` (a hidden launcher, so no console flash) →
`focus-window.ps1`. That script brings the window forward with `user32` P/Invoke —
`SetForegroundWindow` plus the `AttachThreadInput` trick to get past Windows' foreground
lock — restoring it first if it was minimized.

**Context line.** The `project · branch` line comes from the hook payload's `cwd` (leaf
folder) and `git rev-parse --abbrev-ref HEAD` — best-effort, omitted if it isn't a repo.

| File | What it does |
| ---- | ------------ |
| `hooks/hooks.json` | Registers the `Notification` and `Stop` hooks |
| `hooks/notify-toast.ps1` | Builds/shows the toast; registers the AppUserModelId + `claudecode:` protocol; finds the triggering window |
| `hooks/focus-window.ps1` | Brings a window to the foreground (`user32` P/Invoke + `AttachThreadInput` to beat the foreground lock) |
| `hooks/focus-launch.vbs` | Hidden launcher so clicking the toast causes no console flash |
| `hooks/claude.png` | The toast icon (96×96, circular) |
