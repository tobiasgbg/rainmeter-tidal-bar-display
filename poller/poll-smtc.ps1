param([switch]$Once)
# Reads Windows System Media Transport Controls (SMTC) -> writes now-playing to a file.
# Album art is fetched from the iTunes Search API by artist+title, because TIDAL's SMTC
# thumbnail comes back empty (0 bytes). Must run under Windows PowerShell 5.1
# (powershell.exe) for the built-in WinRT projection.
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
if(-not $Once){
  $singleton = New-Object System.Threading.Mutex($false, 'TidalNowPlayingPoller_Mutex')
  if(-not $singleton.WaitOne(0)){ exit }   # another poller already running
}
$dir = Join-Path $env:LOCALAPPDATA 'TidalNowPlaying'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$np  = Join-Path $dir 'nowplaying.txt'
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

# --- album art via the iTunes Search API (free, no key) ------------------
$script:coverKey  = ''     # artist|title currently resolved
$script:coverPath = ''     # file path of the current cover (empty = none)
$script:coverN    = 0      # rolling suffix so the path changes -> Rainmeter reloads
function Clean-Term([string]$s){
  if(-not $s){ return '' }
  $s = $s -replace '\(.*?\)','' -replace '\[.*?\]',''      # drop "(feat ...)", "[Remix]" etc.
  $s = $s -replace '(?i)\b(feat|ft)\..*$',''
  return ($s -replace '\s+',' ').Trim()
}
function Get-Cover([string]$artist,[string]$title){
  $key = "$artist|$title"
  if($key -eq $script:coverKey){ return $script:coverPath }  # same track -> reuse, no web call
  $script:coverKey  = $key
  $script:coverPath = ''
  if(-not $title){ return '' }
  try {
    $term = ((Clean-Term $artist) + ' ' + (Clean-Term $title)).Trim()
    $url  = 'https://itunes.apple.com/search?entity=song&limit=1&term=' + [uri]::EscapeDataString($term)
    $r = Invoke-RestMethod -Uri $url -TimeoutSec 6
    if($r.resultCount -ge 1 -and $r.results[0].artworkUrl100){
      $art  = $r.results[0].artworkUrl100 -replace '100x100bb','600x600bb'
      $script:coverN = ($script:coverN + 1) % 1000
      $file = Join-Path $dir ("cover{0}.jpg" -f $script:coverN)
      Invoke-WebRequest -Uri $art -OutFile $file -TimeoutSec 8 -UseBasicParsing
      Get-ChildItem $dir -Filter 'cover*.jpg' | Where-Object { $_.FullName -ne $file } | Remove-Item -Force -ErrorAction SilentlyContinue
      $script:coverPath = $file
    }
  } catch {}
  return $script:coverPath
}

function Tick {
  $cur = Pick-Session
  if(-not $cur){ [System.IO.File]::WriteAllText($np, "STATUS=NoSession`r`nARTIST=`r`nTITLE=`r`nALBUM=`r`nAPP=`r`nCOVER=", $utf8); if($Once){ Write-Output 'NO_SESSION' }; return }
  $p  = Await ($cur.TryGetMediaPropertiesAsync()) ([Windows.Media.Control.GlobalSystemMediaTransportControlsSessionMediaProperties])
  $st = $cur.GetPlaybackInfo().PlaybackStatus
  $cover = Get-Cover $p.Artist $p.Title
  $txt = "STATUS=$st`r`nARTIST=$($p.Artist)`r`nTITLE=$($p.Title)`r`nALBUM=$($p.AlbumTitle)`r`nAPP=$($cur.SourceAppUserModelId)`r`nCOVER=$cover"
  [System.IO.File]::WriteAllText($np, $txt, $utf8)
  if($Once){ Write-Output $txt }
}

if($Once){ Tick; exit }
while($true){ try { Tick } catch {}; Start-Sleep -Milliseconds 1500 }
