param([switch]$Once)
# Reads Windows System Media Transport Controls (SMTC) -> writes now-playing to a file,
# and fetches weather for the bar (Open-Meteo, no API key) into weather.txt.
# Must run under Windows PowerShell 5.1 (powershell.exe) for the built-in WinRT projection.
# Kept pure ASCII: weather glyphs and Swedish chars are built from [char] code points at
# runtime, so the file needs no BOM and 5.1 still emits correct UTF-8 into weather.txt.
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
if(-not $Once){
  $singleton = New-Object System.Threading.Mutex($false, 'TidalNowPlayingPoller_Mutex')
  if(-not $singleton.WaitOne(0)){ exit }   # another poller already running
}
$dir = Join-Path $env:LOCALAPPDATA 'TidalNowPlaying'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$np  = Join-Path $dir 'nowplaying.txt'
$wx  = Join-Path $dir 'weather.txt'
$utf8 = New-Object System.Text.UTF8Encoding($false)

Add-Type -AssemblyName System.Runtime.WindowsRuntime
$asTask = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
  $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
function Await($op,$t){ $task = $asTask.MakeGenericMethod($t).Invoke($null,@($op)); [void]$task.Wait(5000); $task.Result }

$null = [Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager,Windows.Media.Control,ContentType=WindowsRuntime]
$null = [Windows.Media.Control.GlobalSystemMediaTransportControlsSessionMediaProperties,Windows.Media.Control,ContentType=WindowsRuntime]

$mgr = Await ([Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager]::RequestAsync()) ([Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager])

function Pick-Session {
  try { foreach($s in $mgr.GetSessions()){ if($s.SourceAppUserModelId -match 'tidal'){ return $s } } } catch {}
  return $mgr.GetCurrentSession()
}

function Tick {
  $cur = Pick-Session
  if(-not $cur){ [System.IO.File]::WriteAllText($np, "STATUS=NoSession`r`nARTIST=`r`nTITLE=`r`nALBUM=`r`nAPP=", $utf8); if($Once){ Write-Output 'NO_SESSION' }; return }
  $p  = Await ($cur.TryGetMediaPropertiesAsync()) ([Windows.Media.Control.GlobalSystemMediaTransportControlsSessionMediaProperties])
  $st = $cur.GetPlaybackInfo().PlaybackStatus
  $txt = "STATUS=$st`r`nARTIST=$($p.Artist)`r`nTITLE=$($p.Title)`r`nALBUM=$($p.AlbumTitle)`r`nAPP=$($cur.SourceAppUserModelId)"
  [System.IO.File]::WriteAllText($np, $txt, $utf8)
  if($Once){ Write-Output $txt }
}

# --- weather (Open-Meteo, no API key) -----------------------------------
# Gothenburg, Sweden:
$WxLat = 57.7089
$WxLon = 11.9746
function Map-Wx([int]$c){
  switch($c){
    0          { return @{Cond='Klart';        Icon=[char]0x2600} }        # sun
    {$_ -in 1,2}{ return @{Cond='Halvklart';    Icon=[char]0x26C5} }        # sun behind cloud
    3          { return @{Cond='Mulet';         Icon=[char]0x2601} }        # cloud
    {$_ -in 45,48}    { return @{Cond='Dimma';   Icon=[char]0x2601} }
    {$_ -in 51,53,55,56,57} { return @{Cond='Duggregn'; Icon=[char]0x2614} } # umbrella w/ rain
    {$_ -in 61,63,65,66,67,80,81,82} { return @{Cond='Regn'; Icon=[char]0x2614} }
    {$_ -in 71,73,75,77,85,86} { return @{Cond=('Sn'+[char]0xF6); Icon=[char]0x2744} } # snowflake (Sno)
    {$_ -in 95,96,99} { return @{Cond=([char]0xC5+'ska'); Icon=[char]0x26C8} }          # thunder (Aska)
    default    { return @{Cond='';             Icon=''} }
  }
}
function Update-Weather {
  try {
    $u = "https://api.open-meteo.com/v1/forecast?latitude=$WxLat&longitude=$WxLon&current=temperature_2m,weather_code&timezone=auto"
    $r = Invoke-RestMethod -Uri $u -TimeoutSec 8
    $t = [math]::Round([double]$r.current.temperature_2m)
    $m = Map-Wx ([int]$r.current.weather_code)
    [System.IO.File]::WriteAllText($wx, "TEMP=$t$([char]0x00B0)`r`nCOND=$($m.Cond)`r`nICON=$($m.Icon)", $utf8)
    if($Once){ Write-Output "WX TEMP=$t COND=$($m.Cond)" }
  } catch {}
}

if($Once){ Tick; Update-Weather; exit }
$wxTick = 0
while($true){
  try { Tick } catch {}
  if($wxTick -le 0){ Update-Weather; $wxTick = 600 }   # weather every ~15 min
  $wxTick--
  Start-Sleep -Milliseconds 1500
}
