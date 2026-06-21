#!/bin/bash
# Baut serato_guard Binary via PyInstaller.
# Auf M1 Mac ausführen → serato_guard_arm64
# Auf Intel Mac ausführen → serato_guard_x86_64
# Danach: lipo -create serato_guard_arm64 serato_guard_x86_64 -output DjGuard/Backend/serato_guard

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKEND_PY="$SCRIPT_DIR/DjGuard/Backend/serato_guard.py"
OUT_DIR="$SCRIPT_DIR/DjGuard/Backend"
WORK_DIR="/tmp/djguard_pyinstaller"

ARCH=$(uname -m)
OUT_NAME="serato_guard_${ARCH}"

echo "Architektur: $ARCH"
echo "Output: $OUT_DIR/$OUT_NAME"

# Python finden
PYTHON=""
for p in \
    "/opt/homebrew/opt/python@3.11/bin/python3.11" \
    "/opt/homebrew/opt/python@3.12/bin/python3.12" \
    "/opt/homebrew/bin/python3" \
    "/usr/local/opt/python@3.11/bin/python3.11" \
    "/usr/local/bin/python3" \
    "/usr/bin/python3"; do
    if [ -x "$p" ]; then
        PYTHON="$p"
        break
    fi
done

if [ -z "$PYTHON" ]; then
    echo "Fehler: Python nicht gefunden"
    exit 1
fi
echo "Python: $PYTHON ($($PYTHON --version))"

# PyInstaller + Deps installieren
echo "Installiere Abhängigkeiten..."
"$PYTHON" -m pip install --quiet pyinstaller websockets rapidfuzz --break-system-packages 2>/dev/null \
    || "$PYTHON" -m pip install --quiet pyinstaller websockets rapidfuzz

# Binary bauen
echo "Baue Binary..."
"$PYTHON" -m PyInstaller \
    --onefile \
    --name "$OUT_NAME" \
    --distpath "$OUT_DIR" \
    --workpath "$WORK_DIR/work" \
    --specpath "$WORK_DIR/spec" \
    --hidden-import websockets \
    --hidden-import websockets.legacy \
    --hidden-import websockets.legacy.server \
    --hidden-import websockets.legacy.client \
    --hidden-import rapidfuzz \
    --hidden-import rapidfuzz.fuzz \
    --collect-all websockets \
    --collect-all rapidfuzz \
    --noconfirm \
    --log-level WARN \
    "$BACKEND_PY"

chmod +x "$OUT_DIR/$OUT_NAME"
rm -rf "$WORK_DIR"

echo ""
echo "Fertig: $OUT_DIR/$OUT_NAME"

# Universal Binary erstellen wenn beide vorhanden
ARM64="$OUT_DIR/serato_guard_arm64"
X86="$OUT_DIR/serato_guard_x86_64"
UNIVERSAL="$OUT_DIR/serato_guard"

if [ -f "$ARM64" ] && [ -f "$X86" ]; then
    echo "Beide Architekturen vorhanden → Universal Binary..."
    lipo -create "$ARM64" "$X86" -output "$UNIVERSAL"
    chmod +x "$UNIVERSAL"
    echo "Universal Binary: $UNIVERSAL"
    echo "Jetzt in Xcode neu bauen und DMG erstellen."
else
    echo ""
    echo "Nächster Schritt:"
    if [ "$ARCH" = "arm64" ]; then
        echo "  → Skript auf Intel Mac ausführen, dann nochmal hier starten"
    else
        echo "  → Skript auf M1 Mac ausführen, dann nochmal hier starten"
    fi
fi
