#Requires -Version 5
# Claude Code "Notification" hook -> native Windows toast (Windows 10/11).
# Reads the hook JSON from stdin (fields: message, title) and pops a toast
# attributed to "Claude Code". Run with Windows PowerShell (powershell.exe),
# NOT pwsh 7 -- the WinRT type projection below relies on 5.1.

param(
    # Title is fixed; per-event messages are resolved below from the hook payload.
    # An explicit -Message still overrides everything (handy for testing).
    [string]$Title   = 'Claude Code',
    [string]$Message = '',
    # When set (used by the Stop hook), skip the toast if the triggering terminal
    # is already the foreground window -- avoids a toast on every turn while the
    # user is actively watching. The Notification hook omits this and always fires.
    [switch]$OnlyIfUnfocused
)

$ErrorActionPreference = 'Stop'

# --- Parse the hook payload (JSON on stdin) ------------------------------
# Notification events carry a "message"/"title" and hook_event_name="Notification";
# Stop events carry hook_event_name="Stop" and no message.
$event = ''
try {
    $raw = [Console]::In.ReadToEnd()
    if ($raw) {
        $data = $raw | ConvertFrom-Json
        if ($data.hook_event_name) { $event   = [string]$data.hook_event_name }
        if ($data.message)         { $Message = [string]$data.message }
        if ($data.title)           { $Title   = [string]$data.title }
    }
} catch { }

# --- Default message per event (defined here, not on the hook command) ----
# Notification text comes from the payload above; Stop has none, so supply it.
if (-not $Message) {
    switch ($event) {
        'Stop'  { $Message = 'Turn complete. Ready for your input.' }
        default { $Message = 'Claude Code needs your attention' }
    }
}

# --- Register an AppUserModelId so the toast reads "Claude Code" ----------
# (idempotent; HKCU write, no admin needed). DisplayName + IconUri drive how
# the toast is attributed in the banner and in Action Center.
$appId    = 'Claude.Code'
$regPath  = "HKCU:\Software\Classes\AppUserModelId\$appId"
$iconPath = Join-Path $PSScriptRoot 'claude.png'
if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
New-ItemProperty -Path $regPath -Name 'DisplayName' -Value 'Claude Code' -PropertyType String -Force | Out-Null
if (Test-Path $iconPath) {
    New-ItemProperty -Path $regPath -Name 'IconUri' -Value $iconPath -PropertyType String -Force | Out-Null
}

# --- Register the `claudecode:` protocol so clicking the toast focuses us --
# (idempotent HKCU write). On click, Windows ShellExecutes the launch URI,
# which runs focus-launch.vbs (hidden) -> focus-window.ps1 to bring the
# triggering terminal window back to the foreground.
$protoRoot = 'HKCU:\Software\Classes\claudecode'
$protoCmd  = "HKCU:\Software\Classes\claudecode\shell\open\command"
$wscript   = Join-Path $env:SystemRoot 'System32\wscript.exe'
$vbsPath   = Join-Path $PSScriptRoot 'focus-launch.vbs'
if (Test-Path $vbsPath) {
    New-Item -Path $protoCmd -Force | Out-Null
    New-ItemProperty -Path $protoRoot -Name '(default)'   -Value 'URL:Claude Code Focus' -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $protoRoot -Name 'URL Protocol' -Value '' -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $protoCmd  -Name '(default)'   -Value ("`"$wscript`" `"$vbsPath`" `"%1`"") -PropertyType String -Force | Out-Null
}

# --- Find the terminal window that triggered this hook --------------------
# Walk the parent process chain (the hook is a child of claude.exe, itself a
# child of the host terminal: Windows Terminal / conhost / VS Code / Rider).
# Stop at the first ancestor that owns a visible top-level window; skip
# explorer.exe so we never fall through to the desktop shell.
$launch = ''
$termHwnd = 0
try {
    $parentOf = @{}
    Get-CimInstance Win32_Process -ErrorAction Stop |
        ForEach-Object { $parentOf[[int]$_.ProcessId] = [int]$_.ParentProcessId }
    $cur  = $PID
    $seen = @{}
    for ($i = 0; $i -lt 15; $i++) {
        if (-not $parentOf.ContainsKey($cur)) { break }
        $parent = $parentOf[$cur]
        if ($parent -le 0 -or $seen.ContainsKey($parent)) { break }
        $seen[$parent] = $true
        $proc = Get-Process -Id $parent -ErrorAction SilentlyContinue
        if ($proc -and $proc.MainWindowHandle -ne 0 -and $proc.ProcessName -ne 'explorer') {
            $termHwnd = [int64]$proc.MainWindowHandle
            $launch = "claudecode:focus?hwnd=$termHwnd&pid=$parent"
            break
        }
        $cur = $parent
    }
} catch { }

# --- Stay quiet if the user is already looking at the terminal -----------
# Used by the Stop hook (-OnlyIfUnfocused): if the triggering window is the
# current foreground window, the user is watching -- skip the toast.
if ($OnlyIfUnfocused -and $termHwnd -ne 0) {
    Add-Type -Namespace Native -Name Win -MemberDefinition '[DllImport("user32.dll")] public static extern System.IntPtr GetForegroundWindow();'
    if ([int64][Native.Win]::GetForegroundWindow() -eq $termHwnd) { return }
}

# Toast attribute: only add a launch URI if we resolved a window to focus.
$launchAttr = ''
if ($launch) { $launchAttr = "launch=`"$([System.Security.SecurityElement]::Escape($launch))`"" }

# Toast logo fragment (circular crop), included only if the icon is present.
$logo = ''
if (Test-Path $iconPath) {
    $iconUri = ([Uri]$iconPath).AbsoluteUri
    $logo = "<image placement=`"appLogoOverride`" hint-crop=`"circle`" src=`"$iconUri`"/>"
}

# --- Build and show the toast --------------------------------------------
[void][Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
[void][Windows.UI.Notifications.ToastNotification,        Windows.UI.Notifications, ContentType = WindowsRuntime]
[void][Windows.Data.Xml.Dom.XmlDocument,                 Windows.Data.Xml.Dom,     ContentType = WindowsRuntime]

$xml = @"
<toast activationType="protocol" $launchAttr>
  <visual>
    <binding template="ToastGeneric">
      $logo
      <text>$([System.Security.SecurityElement]::Escape($title))</text>
      <text>$([System.Security.SecurityElement]::Escape($message))</text>
    </binding>
  </visual>
  <audio src="ms-winsoundevent:Notification.Default"/>
</toast>
"@

$doc = [Windows.Data.Xml.Dom.XmlDocument]::new()
$doc.LoadXml($xml)
$toast = [Windows.UI.Notifications.ToastNotification]::new($doc)
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)
