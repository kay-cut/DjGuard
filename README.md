# DjGuard

**Echtzeit-Duplikaterkennung für Serato DJ Pro** · **Real-time duplicate detection for Serato DJ Pro**

<img width="2294" height="1432" alt="DjGuard" src="https://github.com/user-attachments/assets/4e251256-be14-44b9-a746-bc2763b0731c" />


> Dieses Repository enthält keinen Quellcode. Der Source ist privat.  
> This repository contains no source code. The source is private.

---

## ☕ Unterstütze DjGuard · Support DjGuard

DjGuard is free, but takes real time and effort to build. If it has saved you from an embarrassing moment on stage, a small donation goes a long way and helps keep the project going.

DjGuard ist kostenlos, aber nicht ohne Aufwand entwickelt. Wer schon mal dank DjGuard einen peinlichen Moment auf der Bühne vermieden hat, weiss warum Unterstützung zählt.

[![Ko-fi](https://img.shields.io/badge/Ko--fi-Spenden%20%2F%20Donate-FF5E5B?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/guardapp)
[![Stripe](https://img.shields.io/badge/Stripe-Spenden%20%2F%20Donate-6772E5?style=for-the-badge&logo=stripe&logoColor=white)](https://donate.stripe.com/7sYfZi9decjFfOq16v0x200)

Bugs or ideas? Open a [GitHub Issue](https://github.com/kay-cut/DjGuard/issues).

Bugs oder Ideen? Einfach ein [GitHub Issue](https://github.com/kay-cut/DjGuard/issues) öffnen.

---

## 🇬🇧 English

### What is DjGuard?

DjGuard is a macOS app for DJs using Serato DJ Pro. It watches your track history in real time and shows an alert the moment you load a track you have already played in the current session. Works with local tracks, Spotify and Tidal.

### Features

- **Real-time duplicate detection** - checks every loaded track against your session history instantly
- **Fuzzy matching** - catches the same song across different versions (e.g. "Thriller [Xtendz] HD Clean" is flagged as a duplicate of "Thriller")
- **Streaming support** - works with local tracks, Spotify and Tidal
- **Multi-DJ** - two DJs on the same network share their session history. Each one gets warned if they are about to play something the other already played
- **Minimum play time** - short previews do not count as played. Configurable in settings
- **New session** - one click to start fresh
- **History** - see all tracks played this session with search (⌘H)
- **Moveable overlay** - drag the alert circle anywhere on screen to reposition it

### System Requirements

- macOS 14 Sonoma or later
- Serato DJ Pro (tested with version 3.x)

### Installation

> ⚠️ **Important:** Download the DMG directly from GitHub. Do not use AirDrop — it breaks the installer.

1. Download **`DjGuard-x.x.dmg`** from [GitHub Releases](https://github.com/kay-cut/DjGuard/releases) and open it
2. Double-click **`install_djguard.command`** — macOS will block it
3. Open **System Settings → Privacy & Security**, scroll down and click **Open Anyway**
4. A confirmation popup appears — click **Open Anyway** and confirm with Touch ID or your password
5. Terminal opens and installs DjGuard automatically
6. Close the Terminal window when done

> This only happens once. DjGuard opens normally from then on.

### Multi-DJ Setup

- Both Macs need to be on the same network (club WiFi, phone hotspot, anything works)
- Menu: **Connect DJ** and enter the other Mac's IP address
- The other DJ has to accept the connection request before sync starts

### Settings

| Setting | Description |
|---|---|
| Match threshold | How similar two track names need to be to count as duplicates (default: 82 %) |
| Minimum play time | Tracks shorter than X seconds do not count as played (default: 15 s) |
| Overlay size | Size of the alert in percent |
| Overlay position | Drag the circle to move it anywhere on screen |

### FAQ

<details>
<summary>Where do I find DjGuard after launching?</summary>

Look for the icon in the top right of your screen in the menu bar:

<img width="34" height="37" alt="DjGuard menu bar icon" src="https://github.com/user-attachments/assets/6bd24c57-1fc9-4695-b793-bab523393851" />

Click it to open the menu.
</details>

<details>
<summary>How do I connect to another DJ?</summary>

Both Macs need to be on the same network. Club WiFi, a phone hotspot, any shared connection works.

1. Click the DjGuard icon in the menu bar
2. Select **Connect DJ**

<img width="232" height="35" alt="Connect DJ menu item" src="https://github.com/user-attachments/assets/d52c2961-35f2-4a95-bd21-48ef0669e426" />

3. DjGuard scans the network. Click a found DJ from the list or enter the IP address manually
4. When a DJ is found the connect button lights up. Click it to send the request:

<img width="325" height="231" alt="Connect button when DJ found" src="https://github.com/user-attachments/assets/16dc3cd8-5dba-488f-8bfb-684eed2544f8" />

5. The other DJ has to confirm before sync starts

If the connection drops, history syncs again automatically when you reconnect.
</details>

<details>
<summary>What counts as a played track?</summary>

A track counts as played once it has been playing for the minimum play time (default 15 seconds). You can change this in Settings.
</details>

<details>
<summary>The overlay has disappeared off screen</summary>

Open Settings and click the Centre button to bring it back to the middle of the screen.
</details>

---

## 🇩🇪 Deutsch

### Was ist DjGuard?

DjGuard ist eine macOS App für DJs mit Serato DJ Pro. Sie überwacht die Track-History in Echtzeit und zeigt sofort einen Alert, wenn ein Track geladen wird, der in der aktuellen Session schon gespielt wurde. Funktioniert mit lokalen Tracks, Spotify und Tidal.

### Funktionen

- **Echtzeit-Duplikaterkennung** - jeder geladene Track wird sofort gegen die Session-History geprüft
- **Fuzzy-Matching** - erkennt denselben Song in verschiedenen Versionen (z.B. "Thriller [Xtendz] HD Clean" wird als Duplikat von "Thriller" erkannt)
- **Streaming-Support** - funktioniert mit lokalen Tracks, Spotify und Tidal
- **Multi-DJ** - zwei DJs im selben Netzwerk teilen ihre Session-History. Jeder wird gewarnt wenn er etwas spielen will, was der andere schon gespielt hat
- **Mindestspieldauer** - kurze Previews zählen nicht als gespielt. Einstellbar in den Settings
- **Neue Session** - mit einem Klick frisch starten
- **History** - alle gespielten Tracks der Session mit Suche (⌘H)
- **Verschiebbarer Overlay** - den Alert-Kreis direkt auf dem Bildschirm an eine beliebige Position ziehen

### Systemanforderungen

- macOS 14 Sonoma oder neuer
- Serato DJ Pro (getestet mit Version 3.x)

### Installation

> ⚠️ **Wichtig:** Das DMG direkt von GitHub herunterladen. Per AirDrop gesendete Dateien werden von macOS blockiert.

1. **`DjGuard-x.x.dmg`** von [GitHub Releases](https://github.com/kay-cut/DjGuard/releases) herunterladen und öffnen
2. **`install_djguard.command`** doppelklicken — macOS blockiert die Datei
3. **Systemeinstellungen → Datenschutz & Sicherheit** öffnen, nach unten scrollen und auf **Trotzdem öffnen** klicken
4. Ein Bestätigungs-Popup erscheint — auf **Trotzdem öffnen** klicken und mit Touch ID oder Passwort bestätigen
5. Ein Terminal-Fenster öffnet sich und installiert DjGuard automatisch
6. Terminal-Fenster danach schliessen

> Das passiert nur einmal. Danach startet DjGuard normal.

### Multi-DJ Setup

- Beide Macs müssen im selben Netzwerk sein (Club-WLAN, Handy-Hotspot, egal)
- Menü: **Mit DJ verbinden** und die IP-Adresse des anderen Macs eingeben
- Der andere DJ muss die Verbindungsanfrage bestätigen, bevor der Sync startet

### Einstellungen

| Einstellung | Beschreibung |
|---|---|
| Duplikat-Schwelle | Wie ähnlich zwei Track-Namen sein müssen um als Duplikat zu gelten (Standard: 82 %) |
| Mindestspieldauer | Tracks kürzer als X Sekunden zählen nicht als gespielt (Standard: 15 s) |
| Overlay-Grösse | Grösse des Alerts in Prozent |
| Overlay-Position | Kreis auf dem Bildschirm ziehen um ihn zu verschieben |

### FAQ

<details>
<summary>Wo finde ich DjGuard nach dem Start?</summary>

Das Icon erscheint oben rechts in der Menüleiste:

<img width="34" height="37" alt="DjGuard Menüleisten-Icon" src="https://github.com/user-attachments/assets/6bd24c57-1fc9-4695-b793-bab523393851" />

Klick darauf öffnet das Menü.
</details>

<details>
<summary>Wie verbinde ich mich mit einem anderen DJ?</summary>

Beide Macs müssen im selben Netzwerk sein. Club-WLAN, Handy-Hotspot, alles funktioniert.

1. DjGuard-Icon in der Menüleiste anklicken
2. **Mit DJ verbinden** auswählen

<img width="232" height="35" alt="Mit DJ verbinden Menüpunkt" src="https://github.com/user-attachments/assets/d52c2961-35f2-4a95-bd21-48ef0669e426" />

3. DjGuard sucht automatisch im Netzwerk. Gefundene DJs direkt aus der Liste anklicken oder die IP-Adresse manuell eingeben
4. Wenn ein DJ gefunden wurde leuchtet der Verbinden-Button auf. Anklicken um die Anfrage zu senden:

<img width="325" height="231" alt="Verbinden-Button wenn DJ gefunden" src="https://github.com/user-attachments/assets/16dc3cd8-5dba-488f-8bfb-684eed2544f8" />

5. Der andere DJ muss bestätigen bevor der Sync startet

Wenn die Verbindung kurz abbricht, synchronisiert DjGuard beim erneuten Verbinden automatisch.
</details>

<details>
<summary>Was gilt als gespielter Track?</summary>

Ein Track zählt als gespielt sobald die Mindestspieldauer erreicht wurde (Standard: 15 Sekunden). Den Wert kann man in den Einstellungen ändern.
</details>

<details>
<summary>Der Overlay ist vom Bildschirm verschwunden</summary>

In den Einstellungen gibt es einen Zentrieren-Button, der ihn wieder in die Bildschirmmitte bringt.
</details>

---

## Platform Support · Plattform-Unterstützung

DjGuard runs on macOS only. As a side project built in free time, a Windows version was not part of the initial scope. If there is enough interest from the community, it could happen down the road. Open a [GitHub Issue](https://github.com/kay-cut/DjGuard/issues) or drop a donation if Windows support matters to you.

DjGuard läuft nur auf macOS. Als Nebenprojekt in der Freizeit entwickelt, war eine Windows-Version kein Teil des ersten Releases. Je nach Interesse aus der Community könnte das irgendwann kommen. Wer Windows-Support möchte, kann ein [GitHub Issue](https://github.com/kay-cut/DjGuard/issues) öffnen oder das Projekt mit einer Spende unterstützen.

---

## Copyright

© 2025 DJ Kay-Cut. Alle Rechte vorbehalten · All rights reserved.

Die App darf kostenlos verwendet werden. Weitervertrieb, Dekompilierung oder kommerzielle Nutzung ohne ausdrückliche Genehmigung sind nicht gestattet.

The app may be used free of charge. Redistribution, decompilation or commercial use without explicit permission is not permitted.
