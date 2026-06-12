# rainmeter-tidal-bar-display

![TIDAL now-playing widget and clock on an ultrawide bar monitor](docs/screenshot.png)

Rainmeter setup for an ultrawide **"bar" secondary monitor** (e.g. 1920×440):

- 🕐 A **Typography clock** (Swedish weekday/date)
- 🌤️ A tiny **weather** readout above the clock (temperature + condition, from Open-Meteo — no API key)
- 🎵 A live **TIDAL "now playing"** widget — title + artist, updated in real time, with long titles **scrolling sideways (marquee)**

The TIDAL widget reads **Windows System Media Transport Controls (SMTC)** — the same now-playing info shown in the Windows media popup — so it follows **TIDAL** (desktop app or browser), and in fact almost any media app.

## How it works

A tiny background reader (`poller/poll-smtc.ps1`) polls SMTC and writes the current track to
`%LOCALAPPDATA%\TidalNowPlaying\nowplaying.txt`. The Rainmeter skin **`TidalNowPlaying`** reads that file every second and renders it on the bar. The same reader also fetches the weather every ~15 min (Open-Meteo, no API key) into `weather.txt`, which the **`Weather`** skin shows above the clock.

> ⚠️ The reader must run under **Windows PowerShell 5.1** (`powershell.exe`) — PowerShell 7 dropped the built-in WinRT projection needed for SMTC. The included `launch-poller.vbs` handles that, runs it hidden, and auto-starts it at logon.

## Install (on a new PC)

1. Connect the bar monitor.
2. Install **[Rainmeter](https://www.rainmeter.net)** and **TIDAL**.
3. Double-click **`INSTALL.cmd`**.

The installer:

- copies the skins to `Documents\Rainmeter\Skins`
- installs the background reader to `%LOCALAPPDATA%\TidalNowPlaying` and **fixes the path for the current user**
- adds the reader to **Startup** (auto-start at logon) and starts it now
- turns the **taskbar off on the secondary display**
- loads and **positions** the now-playing (top-left), the weather (top-right) and the clock (bottom-right) on the bar
- sets a wallpaper on the bar **if** you place a `wallpaper.jpg` next to `INSTALL.cmd`

Then just play a track in TIDAL. `README.txt` has the same steps in Swedish.

## Customization

Edit `Skins\TidalNowPlaying\TidalNowPlaying.ini` (or right-click the skin → *Edit skin*):

- **Colours / fonts / size** — the `[Variables]` block and each meter's `FontSize`.
- **Scroll speed** — long titles scroll via `marquee.lua`; raise `UpdateDivider` on `[MeasureScroll]` to slow it down, or change `#Window#` (number of visible characters).
- **Auto-hide** — the widget shows only while something is **playing** and hides when paused/stopped/closed (the `IfMatch=^Playing$` on `[mStatus]`). To also keep it visible while paused, change that to `IfMatch=^(Playing|Paused)$`; to always show it, remove the `IfMatch*` lines.
- **Position** — drag the skin on the bar, or right-click → *Settings*.
- **Weather location** — edit `$WxLat` / `$WxLon` near the top of `poller/poll-smtc.ps1` (defaults to Gothenburg). The weather skin itself is `Skins\Weather\Weather.ini`.

## Troubleshooting

**Widget is blank**

- The widget **auto-hides unless something is playing** — start playback in TIDAL and it appears. (See *Auto-hide* under Customization to change that.)
- Check the reader is running:
  ```powershell
  Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
    Where-Object { $_.CommandLine -like '*poll-smtc.ps1*' }
  ```
- Restart it by running `%LOCALAPPDATA%\TidalNowPlaying\launch-poller.vbs` (or just sign out and back in — it auto-starts).
- See what it's writing: open `%LOCALAPPDATA%\TidalNowPlaying\nowplaying.txt`.

**Nothing updates / wrong text**

- The reader must run under **Windows PowerShell 5.1** (the `.vbs` ensures this). PowerShell 7 can't read SMTC.
- Right-click the skin → *Refresh skin*.

## Uninstall

1. Right-click the skin → *Unload skin*.
2. Delete `%LOCALAPPDATA%\TidalNowPlaying`.
3. Remove auto-start: open `shell:startup` and delete `TidalNowPlaying.vbs`.
4. *(Optional)* delete the skins from `Documents\Rainmeter\Skins`.

## Notes

- **Works with more than TIDAL:** because it reads SMTC, it also shows **Spotify, Windows Media Player, browsers** and most media apps. `poll-smtc.ps1` prefers a TIDAL session and otherwise falls back to whatever is currently playing.
- Album name / cover art often come back empty from TIDAL's app via SMTC, so the widget shows **title + artist**.
- Long titles **scroll sideways (marquee)** so the whole title can be read; short titles stay still.
- If a skin lands in the wrong spot, just drag it onto the bar.
- Moving the clock sideways but it "sticks"? Right-click it → *Settings* → uncheck **Keep on screen** (its window is wider than the bar).
- No wallpaper is bundled — supply your own.

## Credits & license

- This project's own code (TIDAL widget, SMTC reader, installer) is released under the **MIT License** — see [LICENSE](LICENSE).
- The bundled **Typography** clock skin is by Alex Guerrieri (*klaidliadon*) under a **Creative Commons** license and remains under its own terms.
- Built with the help of Claude.
