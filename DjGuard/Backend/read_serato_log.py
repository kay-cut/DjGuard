#!/usr/bin/env python3
"""
Liest die Serato DJ.INFO Log-Datei und zeigt Track-Informationen.
Ausführen während Serato läuft.
"""
import re
import time
from pathlib import Path

LOG_PATHS = [
    Path.home() / "Music" / "_Serato_" / "Logs" / "DJ.INFO",
    Path.home() / "Music" / "_Serato_" / "Logs" / "DJ.LOG",
]

def find_log():
    for p in LOG_PATHS:
        if p.exists():
            return p
    # Suche nach aktuellster Log-Datei
    log_dir = Path.home() / "Music" / "_Serato_" / "Logs"
    if log_dir.exists():
        logs = sorted(log_dir.glob("*.log"), key=lambda x: x.stat().st_mtime, reverse=True)
        if logs:
            return logs[0]
    return None

log_path = find_log()
if not log_path:
    print("Keine Serato Log-Datei gefunden!")
    exit(1)

print(f"Lese: {log_path}")
print("=" * 60)

# Zeige letzten 3000 Zeichen
content = log_path.read_bytes()
text = content.decode("utf-8", errors="replace")
print("LETZTER INHALT (Ende der Datei):")
print(text[-3000:])
print("=" * 60)

# Suche nach Track-Patterns
print("\nGEFUNDENE TRACK-ZEILEN:")
patterns = [
    r"(?i)track|artist|title|now.?playing|load|cue|play",
]
for line in text.split("\n"):
    for pat in patterns:
        if re.search(pat, line):
            print(f"  {line.strip()}")
            break
