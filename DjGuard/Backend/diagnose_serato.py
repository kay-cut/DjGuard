#!/usr/bin/env python3
"""
DjGuard Diagnose-Tool
Zeigt alle Dateien die Serato schreibt wenn du spielst.
Ausführen während Serato DJ läuft und einen Track abspielst.
"""
import time
from pathlib import Path

BASE = Path.home() / "Music" / "_Serato_"

def scan():
    found = {}
    for p in BASE.rglob("*"):
        if p.is_file():
            try:
                found[p] = p.stat().st_mtime
            except:
                pass
    return found

print(f"Scanne {BASE} ...")
print("Starte Serato und spiele einen Track. Drücke Ctrl+C zum Stoppen.\n")

before = scan()
try:
    while True:
        time.sleep(0.5)
        after = scan()
        for p, mt in after.items():
            if p not in before or before[p] != mt:
                print(f"GEÄNDERT: {p.relative_to(BASE)}  ({p.stat().st_size} bytes)")
        before = after
except KeyboardInterrupt:
    print("\nFertig.")
