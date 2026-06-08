param([switch]$Once)
# Reads Windows System Media Transport Controls (SMTC) -> writes now-playing to files.
# Must run under Windows PowerShell 5.1 (powershell.exe) for built-in WinRT projection.
$ErrorActionPreference = 'Stop'
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
$null = [Windows.Storage.Streams.IRandomAccessStreamWithContentType,Windows.Storage.Streams,ContentType=WindowsRuntime]
$null = [Windows.Storage.Streams.DataReader,Windows.Storage.Streams,ContentType=WindowsRuntime]

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
  try {
    if($p.Thumbnail){
      $stream = Await ($p.Thumbnail.OpenReadAsync()) ([Windows.Storage.Streams.IRandomAccessStreamWithContentType])
      $sz = [uint32]$stream.Size
      $rd = New-Object Windows.Storage.Streams.DataReader($stream.GetInputStreamAt(0))
      [void](Await ($rd.LoadAsync($sz)) ([uint32]))
      $buf = New-Object byte[] $sz
      $rd.ReadBytes($buf)
      [System.IO.File]::WriteAllBytes((Join-Path $dir 'cover.png'), $buf)
    }
  } catch {}
}

if($Once){ Tick; exit }
while($true){ try { Tick } catch {}; Start-Sleep -Milliseconds 1500 }
