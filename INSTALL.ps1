<#
  Bar-display migration installer.
  Run on the NEW PC AFTER connecting the bar monitor.
  Easiest: double-click INSTALL.cmd. (Or: right-click this file > Run with PowerShell.)
  Prerequisites: install Rainmeter (https://www.rainmeter.net) and TIDAL first.
#>
$ErrorActionPreference = 'Stop'
$pkg = $PSScriptRoot
function Say($m,$c='Gray'){ Write-Host $m -ForegroundColor $c }
Say "=== Bar display migration ===" Cyan
Say "Package folder: $pkg`n"

# 1) Rainmeter skins -> Documents\Rainmeter\Skins
$docs  = [Environment]::GetFolderPath('MyDocuments')
$skins = Join-Path $docs 'Rainmeter\Skins'
New-Item -ItemType Directory -Force -Path $skins | Out-Null
foreach($s in 'Typography','TidalNowPlaying','Weather'){
  $src = Join-Path $pkg "Skins\$s"
  if(Test-Path $src){ Copy-Item $src $skins -Recurse -Force; Say "  [skin]   $s" Green }
}

# 2) Now-playing reader -> %LOCALAPPDATA%\TidalNowPlaying
$poll = Join-Path $env:LOCALAPPDATA 'TidalNowPlaying'
New-Item -ItemType Directory -Force -Path $poll | Out-Null
Copy-Item (Join-Path $pkg 'poller\poll-smtc.ps1')    $poll -Force
Copy-Item (Join-Path $pkg 'poller\launch-poller.vbs') $poll -Force
Say "  [reader] -> $poll" Green

# 3) Point the TIDAL skin at this PC's file path (handles a different username)
$np  = Join-Path $poll 'nowplaying.txt'
$ini = Join-Path $skins 'TidalNowPlaying\TidalNowPlaying.ini'
if(Test-Path $ini){
  (Get-Content $ini) | ForEach-Object { if($_ -match '^NP='){ "NP=$np" } else { $_ } } | Set-Content $ini -Encoding UTF8
  Say "  [skin]   path set to $np" Green
}

# 3b) Point the weather skin at this PC's weather file too
$wx   = Join-Path $poll 'weather.txt'
$wini = Join-Path $skins 'Weather\Weather.ini'
if(Test-Path $wini){
  (Get-Content $wini) | ForEach-Object { if($_ -match '^WX='){ "WX=$wx" } else { $_ } } | Set-Content $wini -Encoding UTF8
  Say "  [skin]   weather path set to $wx" Green
}

# 4) Auto-start the reader at logon
$startup = [Environment]::GetFolderPath('Startup')
Copy-Item (Join-Path $pkg 'poller\launch-poller.vbs') (Join-Path $startup 'TidalNowPlaying.vbs') -Force
Say "  [startup] auto-start at logon installed" Green

# 5) Start the reader now
Start-Process "$env:WINDIR\System32\wscript.exe" -ArgumentList ('"' + (Join-Path $poll 'launch-poller.vbs') + '"')
Say "  [reader] started" Green

# 6) Turn off the taskbar on secondary displays
try {
  New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name MMTaskbarEnabled -Value 0 -PropertyType DWord -Force | Out-Null
  Say "  [taskbar] off on 2nd display (applies after next sign-in)" Green
} catch { Say "  [taskbar] skipped: $($_.Exception.Message)" Yellow }

# Make this process per-monitor DPI aware so screen/window coords match Rainmeter's
Add-Type -Namespace Dpi -Name Ctx -MemberDefinition '[System.Runtime.InteropServices.DllImport("user32.dll")] public static extern bool SetProcessDpiAwarenessContext(System.IntPtr v);'
try { [Dpi.Ctx]::SetProcessDpiAwarenessContext([System.IntPtr](-4)) | Out-Null } catch {}

# Detect the bar monitor (the non-primary screen)
Add-Type -AssemblyName System.Windows.Forms
$bar = [System.Windows.Forms.Screen]::AllScreens | Where-Object { -not $_.Primary } | Select-Object -First 1
if(-not $bar){ Say "`n  ! No second monitor detected — connect the bar, then re-run." Yellow }

# 7) Wallpaper on the bar monitor
$wall = Join-Path $pkg 'wallpaper.jpg'
if((Test-Path $wall) -and $bar){
  try {
    $code = @'
using System; using System.Runtime.InteropServices;
[StructLayout(LayoutKind.Sequential)] public struct RC { public int L,T,R,B; }
[ComImport, Guid("B92B56A9-8B55-4E14-9A89-0199BBB6F93B"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface IDW {
 void SetWallpaper([MarshalAs(UnmanagedType.LPWStr)] string m,[MarshalAs(UnmanagedType.LPWStr)] string w);
 [return: MarshalAs(UnmanagedType.LPWStr)] string GetWallpaper([MarshalAs(UnmanagedType.LPWStr)] string m);
 [return: MarshalAs(UnmanagedType.LPWStr)] string GetMonitorDevicePathAt(uint i);
 uint GetMonitorDevicePathCount(); RC GetMonitorRECT([MarshalAs(UnmanagedType.LPWStr)] string m);
 void SetBackgroundColor(uint c); uint GetBackgroundColor(); void SetPosition(int p); }
public static class WP { public static IDW New(){ return (IDW)Activator.CreateInstance(Type.GetTypeFromCLSID(new Guid("C2CF3110-460E-4FC1-B9D0-8A1C0C9CC4BD"))); } }
'@
    Add-Type -TypeDefinition $code
    $dw = [WP]::New(); $n = $dw.GetMonitorDevicePathCount(); $sec = $null
    for($i=0;$i -lt $n;$i++){ $id=$dw.GetMonitorDevicePathAt([uint32]$i); if([string]::IsNullOrEmpty($id)){continue}; try{$r=$dw.GetMonitorRECT($id)}catch{continue}; if(-not($r.L -eq 0 -and $r.T -eq 0)){ $sec=$id; break } }
    if($sec){ $dw.SetWallpaper($sec,$wall); $dw.SetPosition(2); Say "  [wallpaper] set on bar monitor" Green }
  } catch { Say "  [wallpaper] skipped: $($_.Exception.Message)" Yellow }
}

# 8) Load + position skins in Rainmeter (if installed)
$rm = @("$env:ProgramFiles\Rainmeter\Rainmeter.exe","${env:ProgramFiles(x86)}\Rainmeter\Rainmeter.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
if($rm){
  & $rm "!RefreshApp"; Start-Sleep -Seconds 2
  & $rm @("!ActivateConfig","Typography\clock","clock.ini"); Start-Sleep -Seconds 1
  & $rm @("!ActivateConfig","TidalNowPlaying","TidalNowPlaying.ini"); Start-Sleep -Seconds 2
  & $rm @("!ActivateConfig","Weather","Weather.ini"); Start-Sleep -Seconds 2
  if($bar){
    $bx=$bar.Bounds.X; $by=$bar.Bounds.Y; $bw=$bar.Bounds.Width; $bh=$bar.Bounds.Height
    # the clock window is wider than the bar, so let it overhang the left
    & $rm @("!KeepOnScreen","0","Typography\clock"); Start-Sleep -Milliseconds 600
    # measure both skin windows so positioning works at any resolution
    Add-Type @'
using System;using System.Text;using System.Runtime.InteropServices;
public class Meas {
 [DllImport("user32.dll")] static extern bool EnumWindows(EnumWindowsProc f,IntPtr l);
 [DllImport("user32.dll")] static extern int GetClassName(IntPtr h,StringBuilder s,int n);
 [DllImport("user32.dll")] static extern int GetWindowText(IntPtr h,StringBuilder s,int n);
 [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr h,out RECT r);
 delegate bool EnumWindowsProc(IntPtr h,IntPtr l);
 [StructLayout(LayoutKind.Sequential)] public struct RECT{public int L,T,R,B;}
 public static int[] Rect(string needle){ int[] res={0,0};
  EnumWindows((h,l)=>{var cn=new StringBuilder(256);GetClassName(h,cn,256);
   if(cn.ToString()=="RainmeterMeterWindow"){var tt=new StringBuilder(512);GetWindowText(h,tt,512);
    if(tt.ToString().ToLower().Contains(needle)){RECT r;GetWindowRect(h,out r);res[0]=r.R-r.L;res[1]=r.B-r.T;}}
   return true;},IntPtr.Zero); return res; }
}
'@
    $t=[Meas]::Rect("tidalnowplaying"); $c=[Meas]::Rect("typography"); $w=[Meas]::Rect("weather")
    if($t[0] -gt 0){  # now-playing: top-left corner
      & $rm @("!Move","$bx","$by","TidalNowPlaying")
    }
    if($c[0] -gt 0){  # clock: bottom-right corner (its wide window overhangs left)
      $cx=[int]($bx + $bw - $c[0] - 10); $cy=[int]($by + $bh - $c[1] - 10)
      & $rm @("!Move","$cx","$cy","Typography\clock")
    }
    if($w[0] -gt 0){  # weather: top-right corner, above the clock
      $wxp=[int]($bx + $bw - $w[0] - 10); $wyp=[int]($by + 15)
      & $rm @("!Move","$wxp","$wyp","Weather")
    }
    Say "  [rainmeter] skins loaded & positioned (now-playing top-left, weather top-right, clock bottom-right)" Green
  } else { Say "  [rainmeter] skins loaded (connect bar + drag them over)" Yellow }
} else {
  Say "`n  ! Rainmeter is not installed yet." Yellow
  Say "    Install it from https://www.rainmeter.net , then run this script again to load the skins." Yellow
}

Say "`n=== Core setup done ===" Cyan
Say "Remaining:"
Say "  - Make sure Rainmeter AND TIDAL are installed (re-run this script after installing Rainmeter)."
Say "  - Play a track in TIDAL to light up the now-playing widget."
Say "  - Sign out/in once for the 2nd-screen taskbar change to apply."
Say "  - If a skin sits in the wrong place, just drag it onto the bar."
