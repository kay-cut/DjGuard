# DjGuard

**Echtzeit-Duplikaterkennung für Serato DJ Pro** · **Real-time duplicate detection for Serato DJ Pro**

> Dieses Repository enthält keinen Quellcode. Der Source ist privat.  
> This repository contains no source code. The source is private.

---

## ☕ Unterstütze DjGuard · Support DjGuard

DjGuard ist kostenlos — aber nicht umsonst entwickelt. Jede Spende hilft dabei, neue Features zu entwickeln, Bugs schneller zu fixen und die App langfristig weiterzuführen. Wenn DjGuard dir schon einmal einen peinlichen Moment auf der Bühne erspart hat, weißt du warum das zählt.

DjGuard is free — but not free to develop. Every donation helps fund new features, faster bug fixes and long-term maintenance. If DjGuard has ever saved you from an embarrassing moment on stage, you know why it matters.

[![Ko-fi](https://img.shields.io/badge/Ko--fi-Spenden%20%2F%20Donate-FF5E5B?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/guardapp)
[![Stripe](https://img.shields.io/badge/Stripe-Spenden%20%2F%20Donate-6772E5?style=for-the-badge&logo=stripe&logoColor=white)](https://donate.stripe.com/7sYfZi9decjFfOq16v0x200)

Feedback, Ideen und Bugreports sind genauso willkommen wie Spenden — öffne einfach ein [GitHub Issue](https://github.com/malagsch/DjGuard/issues).

Feedback, feature ideas and bug reports are just as welcome as donations — simply open a [GitHub Issue](https://github.com/malagsch/DjGuard/issues).

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
- **Erscheinungsbild anpassbar** — Grösse, Position und Transparenz des Overlay-Alerts sind frei konfigurierbar

### Systemanforderungen

- macOS 14 Sonoma oder neuer
- Serato DJ Pro (getestet mit Version 3.x)

### Installation

1. **DjGuard.app** in den Ordner `Programme` (Applications) ziehen
2. **`install_djguard.command`** doppelklicken — entfernt das macOS Quarantine-Attribut (einmalig nötig, da die App nicht im Mac App Store ist). Evtl. Admin-Passwort nötig.
3. DjGuard aus dem Programme-Ordner starten

> Falls macOS beim Start warnt dass der Entwickler unbekannt ist:  
> Systemeinstellungen → Datenschutz & Sicherheit → „Dennoch öffnen"

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
- **Customisable appearance** — overlay alert size, position and opacity are fully adjustable

### System Requirements

- macOS 14 Sonoma or later
- Serato DJ Pro (tested with version 3.x)

### Installation

1. Drag **DjGuard.app** into your `Applications` folder
2. Double-click **`install_djguard.command`** — removes the macOS quarantine attribute (required once since the app is not distributed via the Mac App Store). Admin password may be required.
3. Launch DjGuard from your Applications folder

> If macOS warns that the developer is unknown:  
> System Settings → Privacy & Security → "Open Anyway"

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

---

## Copyright

© 2025 malagsch. Alle Rechte vorbehalten · All rights reserved.

Die App darf kostenlos verwendet werden. Weitervertrieb, Dekompilierung oder kommerzielle Nutzung ohne ausdrückliche Genehmigung sind nicht gestattet.

The app may be used free of charge. Redistribution, decompilation or commercial use without explicit permission is not permitted.
