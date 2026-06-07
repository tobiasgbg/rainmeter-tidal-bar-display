' Starts the TIDAL now-playing reader fully hidden (no console window).
' Portable: resolves %LOCALAPPDATA% at runtime, so it works for any user/PC.
Dim sh, p
Set sh = CreateObject("WScript.Shell")
p = sh.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\TidalNowPlaying\poll-smtc.ps1"
sh.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & p & """", 0, False
