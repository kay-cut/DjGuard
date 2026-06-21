# DjGuard

**Echtzeit-Duplikaterkennung für Serato DJ Pro** · **Real-time duplicate detection for Serato DJ Pro**

<img width="2294" height="1432" alt="DjGuard" src="https://github.com/user-attachments/assets/4e251256-be14-44b9-a746-bc2763b0731c" />


> Dieses Repository enthält keinen Quellcode. Der Source ist privat.  
> This repository contains no source code. The source is private.

---

## ☕ Unterstütze DjGuard · Support DjGuard

DjGuard is free — but not free to develop. Every donation helps fund new features, faster bug fixes and long-term maintenance. If DjGuard has ever saved you from an embarrassing moment on stage, you know why it matters.

DjGuard ist kostenlos — aber nicht umsonst entwickelt. Jede Spende hilft dabei, neue Features zu entwickeln, Bugs schneller zu fixen und die App langfristig weiterzuführen. Wenn DjGuard dir schon einmal einen peinlichen Moment auf der Bühne erspart hat, weißt du warum das zählt.

[![Ko-fi](https://img.shields.io/badge/Ko--fi-Spenden%20%2F%20Donate-FF5E5B?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/guardapp)
[![Stripe](https://img.shields.io/badge/Stripe-Spenden%20%2F%20Donate-6772E5?style=for-the-badge&logo=stripe&logoColor=white)](https://donate.stripe.com/7sYfZi9decjFfOq16v0x200)

Feedback, feature ideas and bug reports are just as welcome as donations — simply open a [GitHub Issue](https://github.com/kay-cut/DjGuard/issues).

Feedback, Ideen und Bugreports sind genauso willkommen wie Spenden — öffne einfach ein [GitHub Issue](https://github.com/kay-cut/DjGuard/issues).

---

## 🇬🇧 English

### What is DjGuard?

DjGuard is a macOS app for DJs using Serato DJ Pro. It monitors your track history in real time and instantly alerts you via an on-screen overlay whenever you're about to play a track that has already been played in the current session — whether from your local library, Spotify, or Tidal.

### Features

- **Real-time duplicate detection** — DjGuard tails Serato's DJ log and checks every loaded track against the current session history instantly
- **Fuzzy matching** — recognises the same song across different versions (e.g. "Thriller [Xtendz] – HD – Clean" is detected as a duplicate of "Thriller")
- **Streaming support** — works with local tracks, Spotify and Tidal equally
- **Multi-DJ / Peer detection** — two DJs on the same network connect to each other; each sees the other's history and is warned when playing something the other DJ already played
- **Minimum play time** — briefly previewed tracks only count as played after a configurable minimum duration
- **New session** — one click starts a fresh session; previous tracks no longer trigger duplicate warnings
- **History window** — shows all tracks played in the current session with duplicate markers and search (⌘H)
- **Customisable appearance** — overlay alert size, position and opacity are fully adjustable. The alert can be freely repositioned anywhere on screen by dragging the circle directly

### System Requirements

- macOS 14 Sonoma or later
- Serato DJ Pro (tested with version 3.x)

### Installation

> ⚠️ **Important:** The DMG must be downloaded directly from GitHub — **not via AirDrop**. AirDrop transfers are subject to stricter macOS restrictions that prevent installation.

1. Download **`DjGuard-x.x.dmg`** from [GitHub Releases](https://github.com/kay-cut/DjGuard/releases) and open it
2. **Right-click → Open** on **`install_djguard.command`** inside the DMG window
   > macOS will show a security warning — this is expected, as DjGuard does not have a paid Apple developer certificate. Click **"Open"** in the warning dialog to proceed.
3. A Terminal window opens, automatically copies DjGuard to `/Applications`, removes the quarantine attribute and launches the app
4. The Terminal window can be closed afterwards

### Peer Connection (Multi-DJ)

- Both Macs must be on the same network with DjGuard running
- In the menu: **Connect DJ…** → enter the other Mac's IP address
- DjGuard automatically exchanges session history and warns about cross-DJ duplicates

### Settings

| Setting | Description |
|---|---|
| Match threshold | Fuzzy match sensitivity (default: 82 %) |
| Minimum play time | Tracks under X seconds don't count as played (default: 15 s) |
| Overlay size | Size of the duplicate alert in percent |
| Overlay position | Freely positionable on screen |

### FAQ

<details>
<summary>Where do I find DjGuard after launching?</summary>

DjGuard sits in the menu bar — look for the icon in the top right of your screen:

<img width="34" height="37" alt="DjGuard menu bar icon" src="https://github.com/user-attachments/assets/6bd24c57-1fc9-4695-b793-bab523393851" />

Click it to open the menu.
</details>

<details>
<summary>How do I connect to another DJ?</summary>

Both Macs must be on the **same network** — club WiFi, phone hotspot, or any shared router all work fine.

1. Click the DjGuard icon in the menu bar
2. Select **Connect DJ…**

<img width="232" height="35" alt="Connect DJ menu item" src="https://github.com/user-attachments/assets/d52c2961-35f2-4a95-bd21-48ef0669e426" />

3. DjGuard scans the network automatically. You can either **click a found DJ directly** from the list, or **enter the IP address manually** if needed
4. Once a DJ is found, the connect button lights up — click it to send a connection request:

<img width="325" height="231" alt="Connect button when DJ found" src="https://github.com/user-attachments/assets/16dc3cd8-5dba-488f-8bfb-684eed2544f8" />

5. The **other DJ must confirm** the connection request on their end before the session sync begins

If the connection drops briefly, DjGuard syncs history automatically when you reconnect.
</details>

<details>
<summary>What counts as a played track?</summary>

A track only counts as played after the configured minimum play time (default: 15 seconds). Briefly previewed tracks are ignored automatically. You can adjust this threshold in Settings.
</details>

<details>
<summary>The overlay alert has disappeared off screen — what now?</summary>

Open **Settings** and click the **Centre** button to move the overlay back to the middle of the screen.
</details>

---

## 🇩🇪 Deutsch

### Was ist DjGuard?

DjGuard ist eine macOS App für DJs, die mit Serato DJ Pro arbeiten. Sie überwacht automatisch welche Tracks du spielst und warnt dich sofort per Overlay-Alert, wenn du einen Track laden willst, der in dieser Session bereits gespielt wurde — egal ob auf deiner eigenen Library, Spotify oder Tidal.

### Funktionen

- **Echtzeit-Duplikaterkennung** — DjGuard liest Seratos DJ-Log live mit und prüft jeden geladenen Track sofort gegen die aktuelle Session-History
- **Fuzzy-Matching** — erkennt denselben Song auch in verschiedenen Versionen (z. B. „Thriller [Xtendz] – HD – Clean" wird als Duplikat von „Thriller" erkannt)
- **Streaming-Support** — funktioniert mit lokalen Tracks, Spotify und Tidal gleichermassen
- **Multi-DJ / Peer-Erkennung** — zwei DJs im selben Netzwerk verbinden sich miteinander; jeder sieht die History des anderen und wird gewarnt wenn er etwas spielt was der andere DJ bereits gespielt hat
- **Mindestspieldauer** — kurz angespielte Tracks (Previews) zählen erst ab einer einstellbaren Mindestzeit als gespielt
- **Neue Session** — mit einem Klick startet eine frische Session; vorherige Tracks bleiben nicht im Duplikat-Check
- **History-Fenster** — zeigt alle gespielten Tracks der aktuellen Session mit Duplikat-Markierung und Suchfunktion (⌘H)
- **Erscheinungsbild anpassbar** — Grösse, Position und Transparenz des Overlay-Alerts sind frei konfigurierbar. Die Position des Alerts kann direkt auf dem Bildschirm durch Ziehen des Kreises frei verschoben werden

### Systemanforderungen

- macOS 14 Sonoma oder neuer
- Serato DJ Pro (getestet mit Version 3.x)

### Installation

> ⚠️ **Wichtig:** Das DMG muss direkt von GitHub heruntergeladen werden — **nicht per AirDrop**. AirDrop-Übertragungen werden von macOS stärker eingeschränkt und verhindern die Installation.

1. **`DjGuard-x.x.dmg`** von [GitHub Releases](https://github.com/kay-cut/DjGuard/releases) herunterladen und öffnen
2. **`install_djguard.command`** im DMG-Fenster **rechtsklicken → Öffnen**
   > macOS zeigt eine Sicherheitswarnung — das ist normal, da DjGuard kein kostenpflichtiges Apple-Entwicklerzertifikat hat. Im Warndialog auf **„Öffnen"** klicken.
3. Ein Terminal-Fenster öffnet sich, kopiert DjGuard automatisch nach `/Programme`, entfernt das Quarantine-Attribut und startet die App
4. Das Terminal-Fenster kann danach geschlossen werden

### Peer-Verbindung (Multi-DJ)

- Beide Macs müssen im selben Netzwerk sein und DjGuard laufen
- Im Menü: **Mit DJ verbinden…** → IP-Adresse des anderen Macs eingeben
- DjGuard tauscht automatisch die Session-History aus und warnt bei Duplikaten cross-DJ

### Einstellungen

| Einstellung | Beschreibung |
|---|---|
| Duplikat-Schwelle | Fuzzy-Match-Sensitivität (Standard: 82 %) |
| Mindestspieldauer | Tracks unter X Sekunden zählen nicht als gespielt (Standard: 15 s) |
| Overlay-Grösse | Grösse des Duplikat-Alerts in Prozent |
| Overlay-Position | Position auf dem Bildschirm frei wählbar |

### FAQ

<details>
<summary>Wo finde ich DjGuard nach dem Start?</summary>

DjGuard erscheint in der Menüleiste — das Symbol ist oben rechts im Bildschirm sichtbar:

<img width="34" height="37" alt="DjGuard Menüleisten-Icon" src="https://github.com/user-attachments/assets/6bd24c57-1fc9-4695-b793-bab523393851" />

Klick darauf öffnet das Menü.
</details>

<details>
<summary>Wie verbinde ich mich mit einem anderen DJ?</summary>

Beide Macs müssen im **selben Netzwerk** sein — Club-WLAN, Handy-Hotspot oder ein gemeinsamer Router funktionieren alle.

1. DjGuard-Icon in der Menüleiste anklicken
2. **Mit DJ verbinden…** auswählen

<img width="232" height="35" alt="Mit DJ verbinden Menüpunkt" src="https://github.com/user-attachments/assets/d52c2961-35f2-4a95-bd21-48ef0669e426" />

3. DjGuard sucht automatisch im Netzwerk. Gefundene DJs können **direkt aus der Liste angeklickt** werden — alternativ kann die **IP-Adresse manuell eingegeben** werden
4. Sobald ein DJ gefunden wurde, leuchtet der Verbinden-Button auf — anklicken um eine Verbindungsanfrage zu senden:

<img width="325" height="231" alt="Verbinden-Button wenn DJ gefunden" src="https://github.com/user-attachments/assets/16dc3cd8-5dba-488f-8bfb-684eed2544f8" />

5. Der **andere DJ muss die Verbindung bestätigen**, bevor die Session-Synchronisation startet

Falls die Verbindung kurz unterbrochen wird, synchronisiert DjGuard die History automatisch beim erneuten Verbinden.
</details>

<details>
<summary>Was gilt als gespielter Track?</summary>

Ein Track zählt erst als gespielt, wenn die eingestellte Mindestspieldauer erreicht wurde (Standard: 15 Sekunden). Kurz angehörte Tracks werden automatisch ignoriert. Der Wert lässt sich in den Einstellungen anpassen.
</details>

<details>
<summary>Der Overlay-Alert ist vom Bildschirm verschwunden — was tun?</summary>

In den **Einstellungen** gibt es einen **Zentrieren**-Button, der den Overlay-Alert wieder in die Bildschirmmitte verschiebt.
</details>

---

## Platform Support · Plattform-Unterstützung

DjGuard is a macOS-only application. As a volunteer project developed in spare time, a Windows version has not been pursued — but could be considered if there is enough community interest and support. If Windows matters to you, feel free to open a [GitHub Issue](https://github.com/kay-cut/DjGuard/issues) or support the project via donation.

DjGuard ist eine reine macOS-Anwendung. Als freiwilliges Projekt in der Freizeit entwickelt, wurde eine Windows-Version bisher nicht angegangen — könnte aber in Betracht gezogen werden, wenn genug Interesse und Unterstützung aus der Community kommt. Wer Windows-Support möchte, kann gerne ein [GitHub Issue](https://github.com/kay-cut/DjGuard/issues) eröffnen oder das Projekt mit einer Spende unterstützen.

---

## Copyright

© 2025 DJ Kay-Cut. Alle Rechte vorbehalten · All rights reserved.

Die App darf kostenlos verwendet werden. Weitervertrieb, Dekompilierung oder kommerzielle Nutzung ohne ausdrückliche Genehmigung sind nicht gestattet.

The app may be used free of charge. Redistribution, decompilation or commercial use without explicit permission is not permitted.
