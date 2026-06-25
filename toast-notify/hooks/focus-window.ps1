#Requires -Version 5
# Brings a window to the foreground. Invoked by the `claudecode:` protocol when
# a Claude Code toast is clicked. The toast embeds the triggering terminal's
# window handle + PID in the launch URI, e.g.:
#   claudecode:focus?hwnd=3479258&pid=48652
# We try the HWND first (exact window captured at notify time); if that window
# is gone we re-resolve it from the PID. SetForegroundWindow alone is blocked by
# Windows' foreground lock for a freshly-spawned process, so we use the
# AttachThreadInput trick to borrow the current foreground thread's input state.

param([string]$Uri)

$ErrorActionPreference = 'SilentlyContinue'

# --- Parse hwnd / pid out of the protocol URI ----------------------------
$hwnd = 0
$procId = 0
if ($Uri -match 'hwnd=(\d+)') { $hwnd   = [int64]$Matches[1] }
if ($Uri -match 'pid=(\d+)')  { $procId = [int]  $Matches[1] }

Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class Fg {
  [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int n);
  [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr h);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, IntPtr pid);
  [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
  [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint a, uint b, bool attach);
}
"@

# Resolve the target window: trust the captured HWND, else fall back to PID.
$h = [IntPtr]$hwnd
if (-not [Fg]::IsWindow($h) -and $procId -gt 0) {
    $p = Get-Process -Id $procId -ErrorAction SilentlyContinue
    if ($p) { $h = $p.MainWindowHandle }
}

if ($h -ne [IntPtr]::Zero -and [Fg]::IsWindow($h)) {
    # Un-minimize first (SW_RESTORE = 9) so the window is actually shown.
    if ([Fg]::IsIconic($h)) { [void][Fg]::ShowWindow($h, 9) }

    # Borrow the current foreground thread's input queue to bypass the lock.
    $fgThread   = [Fg]::GetWindowThreadProcessId([Fg]::GetForegroundWindow(), [IntPtr]::Zero)
    $thisThread = [Fg]::GetCurrentThreadId()
    [void][Fg]::AttachThreadInput($thisThread, $fgThread, $true)
    [void][Fg]::BringWindowToTop($h)
    [void][Fg]::SetForegroundWindow($h)
    [void][Fg]::AttachThreadInput($thisThread, $fgThread, $false)
}
