#!/bin/bash
# DjGuard – Quarantine-Attribut entfernen
APP="/Applications/DjGuard.app"
if [ ! -d "$APP" ]; then
    APP="$(dirname "$0")/DjGuard.app"
fi
if [ ! -d "$APP" ]; then
    echo "❌ DjGuard.app nicht gefunden."
    echo "   Bitte zuerst DjGuard.app in den Programme-Ordner verschieben."
    read -p "   Drücke Enter zum Beenden…"
    exit 1
fi
echo "🔓 Entferne macOS Quarantine-Attribut für DjGuard…"
xattr -rd com.apple.quarantine "$APP"
echo "✅ Fertig! DjGuard kann jetzt normal gestartet werden."
read -p "   Drücke Enter zum Beenden…"
