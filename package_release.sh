#!/bin/bash
# DjGuard Release-ZIP erstellen
# Voraussetzung: DjGuard.app in /Applications vorhanden (frisch aus Xcode gebaut)

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_SRC="/Applications/DjGuard.app"
VERSION=$(defaults read "$APP_SRC/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "1.0")
RELEASE_DIR="$SCRIPT_DIR/release/DjGuard-$VERSION"
ZIP_NAME="DjGuard-$VERSION.zip"

if [ ! -d "$APP_SRC" ]; then
    echo "❌ /Applications/DjGuard.app nicht gefunden."
    echo "   Bitte zuerst in Xcode bauen und in Applications installieren."
    exit 1
fi

echo "📦 Erstelle Release $VERSION …"
rm -rf "$SCRIPT_DIR/release"
mkdir -p "$RELEASE_DIR"

# App kopieren
cp -R "$APP_SRC" "$RELEASE_DIR/"

# Install-Script kopieren und ausführbar machen
cp "$SCRIPT_DIR/install_djguard.command" "$RELEASE_DIR/"
chmod +x "$RELEASE_DIR/install_djguard.command"

# Installations-Anleitung als Textdatei (für den ZIP-Inhalt)
cat > "$RELEASE_DIR/INSTALLATION.txt" << 'EOF'
DjGuard – Installation
═══════════════════════════════════════════

  ┌─────────────────┐       ┌──────────────────────┐
  │  DjGuard.app    │  ───▶  │  Programme /          │
  │                 │        │  Applications         │
  └─────────────────┘        └──────────────────────┘

1. DjGuard.app in den Ordner "Programme" (Applications) ziehen
2. "install_djguard.command" doppelklicken
   → Entfernt das Quarantine-Attribut (evtl. Admin-Passwort nötig)
3. DjGuard starten

DjGuard – Installation (English)
═══════════════════════════════════════════
1. Drag DjGuard.app into your Applications folder
2. Double-click "install_djguard.command"
   → Removes the quarantine attribute (admin password may be required)
3. Launch DjGuard
EOF

# ZIP erstellen (aus dem release-Ordner heraus → saubere Pfade)
cd "$SCRIPT_DIR/release"
zip -r --symlinks "$SCRIPT_DIR/$ZIP_NAME" "DjGuard-$VERSION/"
cd "$SCRIPT_DIR"

echo "✅ $ZIP_NAME erstellt ($(du -sh "$ZIP_NAME" | cut -f1))"
echo "   Inhalt:"
unzip -l "$ZIP_NAME" | tail -n +4 | head -20
