#!/bin/bash
# DjGuard – DMG erstellen (Universal Binary muss bereits auf dem Desktop liegen)
set -e

APP_SRC=~/Desktop/DjGuard_Universal.app
if [ ! -d "$APP_SRC" ]; then
    echo "❌ ~/Desktop/DjGuard_Universal.app nicht gefunden."
    echo "   Bitte zuerst den Universal-Build durchführen."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION=$(defaults read "$APP_SRC/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "1.0")
VOL_NAME="DjGuard-$VERSION"
DMG_FINAL=~/Desktop/$VOL_NAME.dmg
TMP_DMG="/tmp/DjGuard_build_$$.dmg"
STAGING=$(mktemp -d)
ICNS="$APP_SRC/Contents/Resources/AppIcon.icns"

echo "📦 Erstelle DMG $VERSION …"

# ── Staging ──────────────────────────────────────────────────────────────────
cp -r "$APP_SRC" "$STAGING/DjGuard.app"
python3 "$SCRIPT_DIR/make_dmg_bg.py" "$STAGING/bg.png"

# ── Altes gemountetes Volume detachen falls noch offen ───────────────────────
if [ -d "/Volumes/$VOL_NAME" ]; then
    DEV_OLD=$(hdiutil info | grep -B5 "$VOL_NAME" | grep "/dev/disk" | head -1 | awk '{print $1}')
    [ -n "$DEV_OLD" ] && diskutil unmountDisk force "$DEV_OLD" 2>/dev/null || true
fi

# ── Temporäres DMG erstellen & mounten ───────────────────────────────────────
hdiutil create -size 80m -fs HFS+ -volname "$VOL_NAME" "$TMP_DMG" -quiet
ATTACH_OUT=$(hdiutil attach "$TMP_DMG" -mountpoint "/Volumes/$VOL_NAME" 2>&1)
DEV=$(echo "$ATTACH_OUT" | grep "Apple_HFS" | awk '{print $1}' | sed 's/s1$//')
MOUNT="/Volumes/$VOL_NAME"

# ── Inhalt kopieren ───────────────────────────────────────────────────────────
cp -r "$STAGING/DjGuard.app" "$MOUNT/"
mkdir -p "$MOUNT/.background"
cp "$STAGING/bg.png" "$MOUNT/.background/bg.png"

# ── Symlink zu /Applications ─────────────────────────────────────────────────
ln -s /Applications "$MOUNT/Applications"

# ── Volume-Icon ───────────────────────────────────────────────────────────────
cp "$ICNS" "$MOUNT/.VolumeIcon.icns"
SetFile -a C "$MOUNT/"

# ── Fenster-Layout ────────────────────────────────────────────────────────────
osascript << APPLESCRIPT
tell application "Finder"
    tell disk "$VOL_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {180, 80, 780, 470}
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 96
        set background picture of theViewOptions to file ".background:bg.png"
        set position of item "DjGuard.app"   to {150, 200}
        set position of item "Applications"  to {410, 200}
        update without registering applications
        delay 1
        close
    end tell
end tell
APPLESCRIPT

# ── Unmount & finalisieren ────────────────────────────────────────────────────
sleep 2
diskutil unmountDisk force "$DEV" 2>/dev/null || true
hdiutil detach "$DEV" -force -quiet 2>/dev/null || true
sleep 1

rm -f "$DMG_FINAL"
hdiutil convert "$TMP_DMG" -format UDZO -o "$DMG_FINAL" -quiet
rm -f "$TMP_DMG"
rm -rf "$STAGING"

echo "✅ $DMG_FINAL erstellt ($(du -sh "$DMG_FINAL" | cut -f1))"
