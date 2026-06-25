' Hidden launcher for the claudecode: protocol. Runs focus-window.ps1 with the
' clicked toast's URI in a fully hidden window (style 0) so there is no console
' flash when a notification is clicked.
' Usage (from the registered protocol handler): wscript focus-launch.vbs "%1"
Option Explicit
Dim uri, scriptDir, cmd, fso
uri = ""
If WScript.Arguments.Count > 0 Then uri = WScript.Arguments(0)
Set fso = CreateObject("Scripting.FileSystemObject")
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
cmd = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File """ _
    & scriptDir & "\focus-window.ps1"" """ & uri & """"
CreateObject("WScript.Shell").Run cmd, 0, False
