============================================================
  BAR DISPLAY -- flytta till en ny dator
============================================================

Det här paketet innehaller allt som behovs for din bar-skarm:
  - Rainmeter-skin: Typography-klocka  (Skins\Typography)
  - Rainmeter-skin: TIDAL "spelas nu"  (Skins\TidalNowPlaying)
  - Bakgrundslasaren som hamtar TIDAL-info (poller\)
  - Bakgrundsbilden (wallpaper.jpg)
  - INSTALL.cmd / INSTALL.ps1 som satter upp allt

------------------------------------------------------------
GOR SA HAR PA DEN NYA DATORN
------------------------------------------------------------
1. Koppla in bar-skarmen forst.

2. Installera tva program (om de inte redan finns):
     - Rainmeter   ->  https://www.rainmeter.net
     - TIDAL       ->  Microsoft Store eller https://tidal.com

3. Kopiera hela mappen "BarDisplay-Migration" till den nya
   datorn (USB-minne, OneDrive, eller dela hur du vill).

4. Dubbelklicka pa  INSTALL.cmd
   (om Windows varnar: klicka "Mer info" -> "Kor anda").

   Skriptet:
     * kopierar bada skinen till Dokument\Rainmeter\Skins
     * installerar lasaren i %LOCALAPPDATA%\TidalNowPlaying
     * stter ratt sokvag automatiskt (aven om anvandarnamnet skiljer sig)
     * lagger lasaren i Autostart (startar vid inloggning)
     * stanger av aktivitetsfaltet pa skarm 2
     * satter bakgrundsbilden pa bar-skarmen
     * laddar och placerar skinen pa baren

5. Borja spela nagot i TIDAL  -> "spelas nu"-widgeten tands.

6. Logga ut/in en gang sa forsvinner aktivitetsfaltet pa skarm 2.

------------------------------------------------------------
BRA ATT VETA
------------------------------------------------------------
* Lasaren MASTE koras av Windows PowerShell 5.1 (powershell.exe) -
  det skoter .vbs-filen automatiskt. (PowerShell 7 saknar stodet.)
* Album/skivomslag kommer ofta tomt fran TIDAL:s app - darfor visas
  bara titel + artist.
* Om ett skin hamnar fel: dra det bara dit du vill pa baren.
* Kor INSTALL.cmd igen nar du installerat Rainmeter, om det inte
  fanns nar du korde forsta gangen.
* Maste du flytta klockan i sidled men den "fastnar": hogerklicka
  skinet -> Settings -> avmarkera "Keep on screen".

Klart!  /Uppsatt med hjalp av Claude
