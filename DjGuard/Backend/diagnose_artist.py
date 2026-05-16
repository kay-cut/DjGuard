#!/usr/bin/env python3
"""
DjGuard Diagnose: Serato DB Struktur
python3 diagnose_artist.py
"""
import sqlite3, sys
from pathlib import Path

DB = Path.home() / "Library" / "Application Support" / "Serato" / "Library" / "root.sqlite"
print(f"DB: {DB}\nExists: {DB.exists()}\n")
if not DB.exists():
    print("❌ DB nicht gefunden"); sys.exit(1)

conn = sqlite3.connect(f"file:{DB}?mode=ro", uri=True)
conn.row_factory = sqlite3.Row

# Alle Tabellen
tables = [r[0] for r in conn.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall()]
print(f"Tabellen: {tables}\n")

# Spalten der relevanten Tabellen
for tbl in ["asset", "dj_asset_metadata", "dj_container_metadata"]:
    if tbl in tables:
        cols = [r[1] for r in conn.execute(f"PRAGMA table_info({tbl})").fetchall()]
        print(f"=== {tbl} Spalten ===")
        print(", ".join(cols))
        # Beispielzeile
        row = conn.execute(f"SELECT * FROM {tbl} LIMIT 1").fetchone()
        if row:
            print("Beispiel:")
            for k in row.keys():
                v = row[k]
                if v:
                    print(f"  {k} = {v!r}")
        print()

# Suche nach 5 Minutes in allen Tabellen
print("=== Suche '5 Minutes' in asset ===")
try:
    rows = conn.execute(
        "SELECT * FROM asset WHERE uri LIKE '%5 Minutes%' OR uri LIKE '%5_Minutes%' LIMIT 3"
    ).fetchall()
    for row in rows:
        print({k: row[k] for k in row.keys() if row[k]})
except Exception as e:
    print(f"Error: {e}")

print("\n=== Suche '5 Minutes' in dj_asset_metadata ===")
try:
    rows = conn.execute(
        """SELECT m.*, a.uri FROM dj_asset_metadata m
           JOIN asset a ON a.id = m.asset_id
           WHERE a.uri LIKE '%5 Minutes%' LIMIT 3"""
    ).fetchall()
    for row in rows:
        print({k: row[k] for k in row.keys() if row[k]})
except Exception as e:
    print(f"Error: {e}")

print("\n=== Erste 3 Zeilen dj_asset_metadata mit asset URI ===")
try:
    rows = conn.execute(
        """SELECT m.*, a.uri FROM dj_asset_metadata m
           JOIN asset a ON a.id = m.asset_id
           LIMIT 3"""
    ).fetchall()
    for row in rows:
        print({k: row[k] for k in row.keys() if row[k]})
except Exception as e:
    print(f"Error: {e}")

conn.close()
