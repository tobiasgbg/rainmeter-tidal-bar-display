# rainmeter-tidal-bar-display

Rainmeter setup for an ultrawide **"bar" secondary monitor** (e.g. 1920×440):

- 🕐 A centered **Typography clock**
- 🎵 A live **TIDAL "now playing"** widget — title + artist, updated in real time

The TIDAL widget reads **Windows System Media Transport Controls (SMTC)** — the same now‑playing info shown in the Windows media popup — so it follows **TIDAL** (desktop app or browser), and in fact almost any media app.

## How it works

A tiny background reader (`poller/poll-smtc.ps1`) polls SMTC and writes the current track to
`%LOCALAPPDATA%\TidalNowPlaying\nowplaying.txt`. The Rainmeter skin **`TidalNowPlaying`** reads that file every second and renders it on the bar.

> ⚠️ The reader must run under **Windows PowerShell 5.1** (`powershell.exe`) — PowerShell 7 dropped the built‑in WinRT projection needed for SMTC. The included `launch-poller.vbs` handles that, runs it hidden, and auto‑starts it at logon.

## Install (on a new PC)

1. Connect the bar monitor.
2. Install **[Rainmeter](https://www.rainmeter.net)** and **TIDAL**.
3. Double‑click **`INSTALL.cmd`**.

The installer:

- copies both skins to `Documents\Rainmeter\Skins`
- installs the background reader to `%LOCALAPPDATA%\TidalNowPlaying` and **fixes the path for the current user**
- adds the reader to **Startup** (auto‑start at logon) and starts it now
- turns the **taskbar off on the secondary display**
- loads and **positions** the clock (centered) and the TIDAL widget on the bar
- sets a wallpaper on the bar **if** you place a `wallpaper.jpg` next to `INSTALL.cmd`

Then just play a track in TIDAL. `README.txt` has the same steps in Swedish.

## Notes

- Album name / cover art often come back empty from TIDAL's app via SMTC, so the widget shows **title + artist**.
- If a skin lands in the wrong spot, just drag it onto the bar.
- Moving the clock sideways but it "sticks"? Right‑click it → *Settings* → uncheck **Keep on screen** (its window is wider than the bar).
- No wallpaper is bundled — supply your own.

## Credits

- **Typography** clock skin by Alex Guerrieri (*klaidliadon*), Creative Commons.
- TIDAL now‑playing widget, SMTC reader and installer built with the help of Claude.
