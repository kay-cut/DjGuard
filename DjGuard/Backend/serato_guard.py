#!/usr/bin/env python3
"""
SeratoDJGuard – Backend Engine v2
Liest Serato DJ History, matched Tracks via Fuzzy-Logic,
speichert 7 Tage lokal in SQLite, synced mit anderen DJ-Instanzen via WebSocket.
"""

import asyncio
import json
import logging
import os
import re
import signal
import socket
import sqlite3
import struct
import time
import uuid
from contextlib import contextmanager
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

import http
import websockets
from websockets import ServerConnection as WebSocketServerProtocol
from rapidfuzz import fuzz

# ── Logging ───────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger("serato_guard")

# ── Pfade & Konstanten ────────────────────────────────────────────────────────
APP_SUPPORT   = Path.home() / "Library" / "Application Support" / "SeratoDJGuard"
DB_PATH       = APP_SUPPORT / "history.db"
SETTINGS_PATH = APP_SUPPORT / "settings.json"
SERATO_PATH   = Path(os.environ.get(
    "SERATO_PATH",
    str(Path.home() / "Music" / "_Serato_" / "History")
))

WS_HOST            = "0.0.0.0"   # IPv4-only — verhindert ::ffff: Loopback-Leaks auf M1
WS_PORT            = int(os.environ.get("SERATO_GUARD_PORT", "8765"))
POLL_INTERVAL      = 0.5
DB_RETENTION_DAYS  = 7
HEARTBEAT_INTERVAL = 20
CLIENT_TIMEOUT     = 50

APP_SUPPORT.mkdir(parents=True, exist_ok=True)


# ── Settings ──────────────────────────────────────────────────────────────────
class Settings:
    def __init__(self):
        self.match_threshold: int   = 82
        self.window_mode:     str   = "session"
        self.window_hours:    float = 6.0
        self.min_play_seconds: int  = 15  # Mindest-Spieldauer in Sekunden
        self.venue_id:        str   = self._default_venue_id()
        self.venue_name:      str   = "Standard"
        self.node_name:       str   = socket.gethostname().split(".")[0]
        self._load()

    @staticmethod
    def _default_venue_id() -> str:
        return f"{time.strftime('%Y-%m-%d')}_{socket.gethostname().split('.')[0]}"

    def _load(self):
        try:
            if SETTINGS_PATH.exists():
                raw = json.loads(SETTINGS_PATH.read_text(encoding="utf-8"))
                self.match_threshold = int(raw.get("matchThreshold", self.match_threshold))
                self.window_mode     = str(raw.get("windowMode", self.window_mode))
                self.window_hours     = float(raw.get("windowHours", self.window_hours))
                self.min_play_seconds = int(raw.get("minPlaySeconds", self.min_play_seconds))
                self.venue_id        = str(raw.get("venueId", self.venue_id))
                self.venue_name      = str(raw.get("venueName", self.venue_name))
                self.node_name       = str(raw.get("nodeName", self.node_name))
        except Exception as e:
            log.warning(f"Settings load failed (using defaults): {e}")

    def reload(self):
        self._load()


# ── SQLite Persistenz ─────────────────────────────────────────────────────────
class TrackDatabase:
    def __init__(self, path: Path):
        self.path = path
        self._init_schema()

    @contextmanager
    def _conn(self):
        conn = sqlite3.connect(self.path, check_same_thread=False)
        conn.row_factory = sqlite3.Row
        try:
            yield conn
            conn.commit()
        finally:
            conn.close()

    def _init_schema(self):
        with self._conn() as conn:
            conn.executescript("""
                CREATE TABLE IF NOT EXISTS tracks (
                    id          TEXT PRIMARY KEY,
                    venue_id    TEXT NOT NULL,
                    artist      TEXT NOT NULL,
                    title       TEXT NOT NULL,
                    album       TEXT NOT NULL DEFAULT '',
                    played_at   REAL NOT NULL,
                    source_node TEXT NOT NULL DEFAULT 'local'
                );
                CREATE INDEX IF NOT EXISTS idx_venue_time
                    ON tracks(venue_id, played_at);

                -- Geladene Tracks (Stage 1): für sofortige Duplikat-Erkennung
                -- Wird nicht gesynct zu anderen DJs
                CREATE TABLE IF NOT EXISTS loaded (
                    id          TEXT PRIMARY KEY,
                    venue_id    TEXT NOT NULL,
                    artist      TEXT NOT NULL,
                    title       TEXT NOT NULL,
                    loaded_at   REAL NOT NULL
                );
                CREATE INDEX IF NOT EXISTS idx_loaded_venue
                    ON loaded(venue_id, loaded_at);

                CREATE TABLE IF NOT EXISTS peers (
                    node_id   TEXT PRIMARY KEY,
                    ip        TEXT NOT NULL,
                    port      INTEGER NOT NULL,
                    last_seen REAL NOT NULL,
                    venue_id  TEXT NOT NULL DEFAULT ''
                );
            """)
        self._purge_old()

    def _purge_old(self):
        cutoff = time.time() - DB_RETENTION_DAYS * 86400
        with self._conn() as conn:
            deleted = conn.execute(
                "DELETE FROM tracks WHERE played_at < ?",
                (cutoff,)
            ).rowcount
        if deleted:
            log.info(f"Purged {deleted} tracks older than {DB_RETENTION_DAYS} days")

    def insert_loaded(self, track: "Track", venue_id: str) -> None:
        """Speichert einen geladenen Track in der loaded-Tabelle (Stage 1)."""
        with self._conn() as conn:
            conn.execute(
                """INSERT OR REPLACE INTO loaded (id, venue_id, artist, title, loaded_at)
                   VALUES (?, ?, ?, ?, ?)""",
                (str(uuid.uuid4()), venue_id, track.artist, track.title, time.time())
            )
        # Alte loaded-Einträge bereinigen (>24h)
        with self._conn() as conn:
            conn.execute(
                "DELETE FROM loaded WHERE loaded_at < ?",
                (time.time() - 86400,)
            )

    def insert_track(self, track: "Track", venue_id: str, source_node: str = "local") -> bool:
        with self._conn() as conn:
            existing = conn.execute(
                """SELECT id FROM tracks
                   WHERE venue_id = ? AND artist = ? AND title = ?
                   AND ABS(played_at - ?) < 5""",
                (venue_id, track.artist, track.title, track.played_at)
            ).fetchone()
            if existing:
                return False

            conn.execute(
                """INSERT INTO tracks
                   (id, venue_id, artist, title, album, played_at, source_node)
                   VALUES (?, ?, ?, ?, ?, ?, ?)""",
                (
                    str(uuid.uuid4()),
                    venue_id,
                    track.artist,
                    track.title,
                    track.album,
                    track.played_at,
                    source_node,
                )
            )
        return True

    def get_tracks(self, venue_id: str, since_ts: Optional[float] = None) -> list["Track"]:
        cutoff = since_ts if since_ts is not None else (time.time() - DB_RETENTION_DAYS * 86400)
        with self._conn() as conn:
            rows = conn.execute(
                """SELECT artist, title, album, played_at
                   FROM tracks
                   WHERE venue_id = ? AND played_at >= ?
                   ORDER BY played_at ASC""",
                (venue_id, cutoff)
            ).fetchall()
        return [Track(r["artist"], r["title"], r["album"], r["played_at"]) for r in rows]

    def get_all_tracks_for_sync(self, venue_id: str) -> list[dict]:
        with self._conn() as conn:
            rows = conn.execute(
                """SELECT artist, title, album, played_at
                   FROM tracks
                   WHERE venue_id = ?
                   ORDER BY played_at ASC""",
                (venue_id,)
            ).fetchall()
        return [
            {
                "artist": r["artist"],
                "title": r["title"],
                "album": r["album"],
                "played_at": r["played_at"],
            }
            for r in rows
        ]

    def upsert_peer(self, node_id: str, ip: str, port: int, venue_id: str):
        with self._conn() as conn:
            conn.execute(
                """INSERT INTO peers (node_id, ip, port, last_seen, venue_id)
                   VALUES (?, ?, ?, ?, ?)
                   ON CONFLICT(node_id) DO UPDATE SET
                       ip = excluded.ip,
                       port = excluded.port,
                       last_seen = excluded.last_seen,
                       venue_id = excluded.venue_id""",
                (node_id, ip, port, time.time(), venue_id)
            )

    def get_recent_peers(self) -> list[dict]:
        cutoff = time.time() - DB_RETENTION_DAYS * 86400
        with self._conn() as conn:
            rows = conn.execute(
                "SELECT * FROM peers WHERE last_seen > ?",
                (cutoff,)
            ).fetchall()
        return [dict(r) for r in rows]


# ── Datenmodelle ──────────────────────────────────────────────────────────────
@dataclass
class Track:
    artist: str
    title: str
    album: str
    played_at: float

    @property
    def key(self) -> str:
        import unicodedata
        raw = f"{self.artist} {self.title}"
        normalized = unicodedata.normalize("NFC", raw)
        return re.sub(r"[^\w\s]", "", normalized, flags=re.UNICODE).lower().strip()

    @property
    def display(self) -> str:
        if self.artist and self.title:
            return f"{self.artist} – {self.title}"
        return self.artist or self.title or "Unknown"

    def to_dict(self) -> dict:
        return {
            "artist": self.artist,
            "title": self.title,
            "album": self.album,
            "display": self.display,
            "played_at": self.played_at,
        }


@dataclass
class ConnectedClient:
    ws: WebSocketServerProtocol
    client_id: str = field(default_factory=lambda: str(uuid.uuid4())[:8])
    name: str = "Unbekannt"
    device: str = ""
    ip: str = ""
    is_peer: bool = False
    peer_node_id: str = ""
    venue_id: str = ""
    connected_at: float = field(default_factory=time.time)
    last_seen: float = field(default_factory=time.time)

    def touch(self):
        self.last_seen = time.time()

    @property
    def connected_since_str(self) -> str:
        d = int(time.time() - self.connected_at)
        if d < 60:
            return f"{d}s"
        if d < 3600:
            return f"{d // 60}min"
        return f"{d // 3600}h {(d % 3600) // 60}min"

    def to_dict(self) -> dict:
        return {
            "client_id": self.client_id,
            "name": self.name,
            "device": self.device,
            "ip": self.ip,
            "is_peer": self.is_peer,
            "venue_id": self.venue_id,
            "connected_since": self.connected_since_str,
        }


# ── Fuzzy Matcher ─────────────────────────────────────────────────────────────
class TrackMatcher:
    """
    Token-Intersection Matching optimiert für DJ-Libraries.

    Kern-Idee: Extrahiere den "echten" Songtitel (ohne BPM-Prefix, DJ-Service-Tags,
    Video-Labels, Quality-Suffixe) und vergleiche dann bedeutungsvolle Tokens.

    Wenn ≥1 Artist-Token UND ≥1 Titel-Token übereinstimmen → Duplikat.
    Wenn Artist leer/nur-BPM → nur Titel-Tokens vergleichen.
    """

    # Tokens die beim Vergleich ignoriert werden
    STOPWORDS = {
        'ft', 'feat', 'featuring', 'and', 'the', 'n', 'x', 'vs', 'with',
        'a', 'an', 'in', 'of', 'on', 'at', 'to', 'for', 'is', 'it',
        'de', 'la', 'remix', 'edit', 'version', 'mix', 'extended', 'original',
        'intro', 'clean', 'dirty', 'explicit', 'single', 'hd', 'hq', 'vip',
        'xtendz', 'b4', 'u', 'dms', 'club', 'ultimix', 'funkymix', 'snipz',
    }

    # BPM/Key-Präfixe die DJs in Dateinamen stecken:
    # "2-130 128 – 130 -", "264-128 –", "130 -", "7A -", "128bpm -"
    BPM_PREFIX = re.compile(
        r'^(?:'
        r'\d[\d\-\.]*\s+\d+\s*[-\u2013]+\s*\d*\s*[-\u2013]?\s*'  # "2-130 128 – 130 -"
        r'|\d{3,}[-\u2013]\d{2,3}\s*[-\u2013]+\s*'                  # "264-128 –"
        r'|\d{2,3}\s*[-\u2013]\s*(?=\D)'                            # "130 - " before non-digit
        r'|\d{2,3}bpm\s*[-\u2013]?\s*'                              # "130bpm"
        r'|[0-9]{1,2}[AB]\s*[-\u2013]?\s*'                         # "7A -" (Camelot)
        r')',
        re.IGNORECASE
    )

    # Track-Nummern am Anfang: "01 ", "02 "
    TRACK_NUM = re.compile(r'^\d{1,2}\s+')

    # DJ-Service-Tags in eckigen Klammern
    # [Xtendz] [Single] [Club] [DMS] [Funkymix] [Intro] [Remix] [Ultimix] etc.
    NOISE_BRACKETS = re.compile(r'\s*\[[^\]]*\]')

    # Video/Quality-Labels und Standard-DJ-Suffixe in runden Klammern
    NOISE_PARENS = re.compile(
        r'\s*\('
        r'(?:Clean|Dirty|Explicit|HD|HQ|4K|1080p?|720p?|360p?[^)]*|H\.264[^)]*|'
        r'Extended(?:\s*Mix)?|Original(?:\s*Mix)?|Single|Acapella|Instrumental|'
        r'Radio\s*Edit|Quick\s*Hitter|X-Mix|XXX|Unofficial|'
        r'DJcity\s*Intro(?:\s*-\s*(?:Dirty|Clean))?|'
        r'Lyric\s*Video|Official\s*(?:Music\s*)?Video|Music\s*Video|'
        r'Dance\s*Video|Visualizer|Clip\s*Officiel)'
        r'[^)]*\)',
        re.IGNORECASE
    )

    # Trailing-Suffixe: "- HD - Dirty", "- Clean 1", "- HD"
    TRAILING_NOISE = re.compile(
        r'\s*[-\u2013]\s*(?:HD|HQ|Dirty|Clean|Explicit|Extended|Original|'
        r'Radio\s*Edit)(?:\s+\d+)?\s*$',
        re.IGNORECASE
    )

    def __init__(self, threshold: int = 82):
        self.threshold = threshold

    def _tokens(self, text: str) -> set:
        """Bedeutungsvolle Tokens: >1 Zeichen, kein Stopword, keine reine Zahl."""
        words = re.sub(r'[^\w\s]', ' ', text.lower()).split()
        return {w for w in words
                if w not in self.STOPWORDS and len(w) > 1 and not w.isdigit()}

    def _core(self, title: str) -> str:
        """
        Extrahiert den Kern-Songtitel.
        Entfernt: BPM-Prefix, Tracknummer, DJ-Service-Tags, Video-Labels, Quality-Suffixe.

        Beispiele:
          "2-130 128 – 130 - Thriller B4 U Make It"     → "Thriller B4 U Make It"
          "My Way Remix [Xtendz] - HD - Dirty"           → "My Way Remix"
          "California Love (Clean) (Extended)"            → "California Love"
          "ROSES (Imanbek Remix) (Lyric Video) [Xtendz]" → "ROSES (Imanbek Remix)"
          "Tick Tock (Joel Corry Remix) [Club] - HD"     → "Tick Tock (Joel Corry Remix)"
          "Billie Jean [Xtendz] - Clean 1"               → "Billie Jean"
        """
        c = title
        # BPM/Key-Prefix und Tracknummer entfernen
        c = self.BPM_PREFIX.sub('', c).strip()
        c = self.TRACK_NUM.sub('', c).strip()
        # Iterativ Rauschen entfernen bis stabil
        for _ in range(6):
            prev = c
            c = self.NOISE_BRACKETS.sub('', c)
            c = self.NOISE_PARENS.sub('', c)
            c = self.TRAILING_NOISE.sub('', c)
            c = c.strip(' -\u2013').strip()
            if c == prev:
                break
        return c.strip() or title.strip()

    def score(self, a: Track, b: Track) -> int:
        core_a = self._core(a.title)
        core_b = self._core(b.title)

        art_tok_a = self._tokens(a.artist)
        art_tok_b = self._tokens(b.artist)
        ttl_tok_a = self._tokens(core_a)
        ttl_tok_b = self._tokens(core_b)

        common_art = art_tok_a & art_tok_b
        common_ttl = ttl_tok_a & ttl_tok_b

        # ── Token-Intersection: Artist UND Titel gemeinsam ──────────────────
        if common_art and common_ttl:
            art_ratio = len(common_art) / max(len(art_tok_a), len(art_tok_b), 1)
            ttl_ratio = len(common_ttl) / max(len(ttl_tok_a), len(ttl_tok_b), 1)
            return min(int((art_ratio * 0.4 + ttl_ratio * 0.6) * 100 + 50), 100)

        # ── Kein/leerer Artist oder Artist nur BPM/Zahlen → nur Titel ───────
        if (not a.artist or not b.artist or not art_tok_a or not art_tok_b) and common_ttl:
            ttl_ratio = len(common_ttl) / max(len(ttl_tok_a), len(ttl_tok_b), 1)
            return int(50 + ttl_ratio * 50)

        # ── Fuzzy Fallback ───────────────────────────────────────────────────
        # Alle Fuzzy-Scores müssen ≥75% sein um Grenzfälle ("Thriller"/"Filler") zu vermeiden
        # Token-Intersection ist der primäre Weg — Fuzzy ist nur Safety-Net
        fuzzy_scores = []
        key_s = fuzz.token_sort_ratio(a.key, b.key)
        if key_s >= 75:
            fuzzy_scores.append(key_s)
        if core_a and core_b:
            core_s = fuzz.token_sort_ratio(core_a.lower(), core_b.lower())
            if core_s >= 75:
                fuzzy_scores.append(core_s)
        if a.artist and b.artist:
            art_s = fuzz.token_sort_ratio(a.artist.lower(), b.artist.lower())
            if art_s > 85 and core_a and core_b:
                combined = int(art_s * 0.35 + fuzz.partial_ratio(
                    core_a.lower(), core_b.lower()) * 0.65)
                fuzzy_scores.append(combined)
        return max(fuzzy_scores) if fuzzy_scores else 0

    def check(self, candidate: Track, history: list) -> dict:
        """
        Vergleicht candidate gegen alle Tracks in history.
        Gibt zurück: {is_duplicate, is_exact, score, matched, similar, similar_tracks}
        """
        best_score = 0
        best_match = None
        similar    = []

        for h in history:
            s = self.score(candidate, h)
            if s == 100:
                return {"is_duplicate": True, "is_exact": True,
                        "score": 100, "matched": h,
                        "similar": [], "similar_tracks": []}
            if s >= self.threshold:
                if s > best_score:
                    if best_match:
                        similar.append((best_match, best_score))
                    best_score = s
                    best_match = h
                else:
                    similar.append((h, s))

        if best_match:
            sim_sorted = sorted(similar, key=lambda x: -x[1])[:3]
            return {"is_duplicate": True, "is_exact": False,
                    "score": best_score, "matched": best_match,
                    "similar": [s[0] for s in sim_sorted],
                    "similar_tracks": sim_sorted}

        return {"is_duplicate": False, "is_exact": False,
                "score": 0, "matched": None,
                "similar": [], "similar_tracks": []}

class SeratoLibraryReader:
    DB_PATH = (
        Path.home() / "Library" / "Application Support" / "Serato" / "Library" / "root.sqlite"
    )

    def __init__(self):
        self._cache: dict[str, tuple[str, str]] = {}  # (artist, title), album not stored

    def lookup(self, filepath: str) -> tuple[str, str, str]:
        """Returns (artist, title, ""). Album always empty."""
        if filepath in self._cache:
            a, t = self._cache[filepath]
            return (a, t, "")

        # Try DB first
        artist, title = self._db_lookup(filepath)

        # Fallback: filename + folder
        if not title:
            artist, title = self._from_filename(filepath)
            if not artist:
                artist = self._folder_artist(filepath)

        self._cache[filepath] = (artist, title)
        return (artist, title, "")

    def _db_lookup(self, filepath: str) -> tuple[str, str]:
        if not self.DB_PATH.exists():
            return ("", "")
        try:
            home     = str(Path.home())
            # portable_id in Serato DB hat KEINEN führenden /
            # Beispiel: 'Users/kaycut/Music/...' (ohne führendes /)
            rel_path = filepath.lstrip("/")  # absoluten Pfad → ohne führendes /
            fname    = Path(filepath).name
            conn = sqlite3.connect(
                f"file:{self.DB_PATH}?mode=ro", uri=True, check_same_thread=False
            )
            conn.row_factory = sqlite3.Row
            # Serato speichert in 'asset' Tabelle:
            # portable_id = relativer Pfad (ohne führenden /)
            # artist = Artist, name = Titel, album = Album
            for p in [rel_path, fname]:
                row = conn.execute(
                    """SELECT artist, name FROM asset
                       WHERE portable_id = ? OR portable_id LIKE ? OR file_name = ?
                       LIMIT 1""",
                    (p, f"%{fname}", fname),
                ).fetchone()
                if row and row["name"]:
                    a = (row["artist"] or "").strip()
                    t = (row["name"]   or "").strip()
                    conn.close()
                    # Tracknummer als Titel ablehnen
                    if re.match(r"^\d{1,3}\s", t):
                        return ("", "")
                    return (a, t)
            conn.close()
        except Exception as e:
            log.debug(f"SQLite: {e}")
        return ("", "")

    _GENRE_FOLDERS = {
        "hiphop", "hip hop", "hip-hop", "rnb", "r&b", "pop", "rock", "edm",
        "house", "techno", "latin", "afro", "dancehall", "reggaeton", "trap",
        "boom clack", "boom clack st", "boom", "ladies", "easy", "ladies easy",
        "sets", "-sets", "videoserato", "music", "tracks", "songs", "videos",
        "mashup", "mashups", "remix", "remixes", "edit", "edits", "clean",
    }

    def _folder_artist(self, filepath: str) -> str:
        try:
            folder = Path(filepath).parent.name.strip(" -_")
        except Exception:
            return ""
        if not folder or len(folder) < 3 or len(folder) > 50:
            return ""
        if folder.lower() in self._GENRE_FOLDERS:
            return ""
        if folder.startswith(("-", "_")):
            return ""
        if re.search(r"\b(19|20)\d{2}\b", folder):
            return ""
        return folder

    def _from_filename(self, filepath: str) -> tuple[str, str]:
        try:
            stem = Path(filepath).stem
        except Exception:
            return ("", "")
        c = stem
        c = re.sub(r"\s*-\s*(?:HD\s*-\s*)?(?:Dirty|Clean|Explicit|Instrumental|Acapella)\s*$",
                   "", c, flags=re.IGNORECASE).strip()
        c = re.sub(r"\s*-\s*HD\s*$", "", c, flags=re.IGNORECASE).strip()
        for _ in range(4):
            prev = c
            c = re.sub(r"\s*\[[^\]]*\]", "", c)
            c = re.sub(r"\s*\([^\)]*\)", "", c)
            if c == prev:
                break
        c = re.sub(r"\s*-\s*(?:HD|Dirty|Clean|Explicit|Radio\s*Edit|Extended|Original)\s*$",
                   "", c, flags=re.IGNORECASE).strip(" -").strip()
        if not c:
            c = stem
        m = re.match(r"^(.{2,}?)\s+-\s+(.{2,})$", c)
        if m:
            return (m.group(1).strip(), m.group(2).strip())
        return ("", c)

_library_reader = SeratoLibraryReader()

# ── Serato History Parser ─────────────────────────────────────────────────────
class SeratoHistoryParser:
    INTEGER_FIELDS = {2, 17}
    ADAT_ARTIST, ADAT_TITLE = 6, 7
    ADAT_ALBUM, ADAT_PLAYED = 8, 17

    def parse_file(self, path: Path) -> list[Track]:
        try:
            data = path.read_bytes()
        except (OSError, PermissionError) as e:
            log.warning(f"Cannot read {path}: {e}")
            return []

        if len(data) < 8:
            return []

        offset = 0
        if data[:4] == b"vrsn":
            offset = 8 + struct.unpack_from(">I", data, 4)[0]

        tracks = []
        while offset < len(data) - 8:
            try:
                tag = data[offset:offset + 4]
                length = struct.unpack_from(">I", data, offset + 4)[0]
                payload = data[offset + 8:offset + 8 + length]
                offset += 8 + length
            except struct.error:
                break

            if tag == b"oent":
                t = self._parse_oent(payload)
                if t:
                    tracks.append(t)

        return tracks

    def _parse_oent(self, data: bytes) -> Optional[Track]:
        fields: dict[int, bytes] = {}
        offset = 0

        while offset < len(data) - 8:
            try:
                tag = data[offset:offset + 4]
                length = struct.unpack_from(">I", data, offset + 4)[0]
                payload = data[offset + 8:offset + 8 + length]
                offset += 8 + length
            except struct.error:
                break

            if tag != b"adat":
                continue

            adat_off = 0
            while adat_off < len(payload):
                field_id = payload[adat_off]
                adat_off += 1

                if field_id in self.INTEGER_FIELDS:
                    if adat_off + 8 > len(payload):
                        break
                    field_data = payload[adat_off:adat_off + 4]
                    adat_off += 8
                else:
                    boundary = payload.find(b"\x00\x00\x00\x00", adat_off)
                    if boundary == -1:
                        field_data = payload[adat_off:]
                        adat_off = len(payload)
                    else:
                        field_data = payload[adat_off:boundary]
                        adat_off = boundary + 4

                if field_id in (self.ADAT_ARTIST, self.ADAT_TITLE, self.ADAT_ALBUM, self.ADAT_PLAYED):
                    fields[field_id] = field_data

        played_raw = fields.get(self.ADAT_PLAYED, b"")
        if len(played_raw) >= 4 and struct.unpack_from(">I", played_raw)[0] == 0:
            return None

        def dec(b: bytes) -> str:
            try:
                return b.decode("utf-16-be").rstrip("\x00").strip()
            except Exception:
                return ""

        artist = dec(fields.get(self.ADAT_ARTIST, b""))
        title = dec(fields.get(self.ADAT_TITLE, b""))
        album = dec(fields.get(self.ADAT_ALBUM, b""))

        if not artist and not title:
            return None

        return Track(artist, title, album, time.time())


# ── Serato Log Poller ─────────────────────────────────────────────────────────
class SessionPoller:
    RE_STEMS = re.compile(r'\[Audio\] Attempting to create a temporary stems file for (.+?)$')
    RE_DECK    = re.compile(r'cache:///(.+?):(deck_\d+)_instrumental')
    RE_VIEW    = re.compile(r'\[View\] The cache `(/Users/[^`]+\.(mp3|aac|flac|wav|aiff|m4a|mp4|ogg))`')
    RE_HISTORY = re.compile(r'\[Library\] Adding entry to history session')
    RE_PLAYED  = re.compile(r'\[Library\] Updating entry with id')

    def __init__(self):
        self._log_path      : Optional[Path]  = None
        self._log_size      : int             = 0
        self._session_start : float           = time.time()
        self._pending_file  : Optional[str]   = None
        self._pending_deck  : str             = "deck_0"
        self._staged        : Optional[Track] = None
        self._staged_at     : float           = 0.0
        self._staged_alerted: bool            = False  # ob beim Laden schon Alert gesendet
        # Callback: wird aufgerufen wenn Track geladen wird (Stage 1) → sofortige Prüfung
        self.on_loaded: Optional[callable]    = None

    @property
    def session_start(self) -> float:
        return self._session_start

    on_existing_tracks: Optional[callable] = None

    def poll(self) -> list[Track]:
        log_path = self._find_log()
        if not log_path:
            return []

        if log_path != self._log_path:
            log.info(f"Serato Log erkannt: {log_path.name}")
            self._log_path = log_path
            self._session_start = time.time()
            self._pending_file = None

            existing = self._read_existing_tracks(log_path)
            if existing:
                log.info(f"Bestehende Session-Tracks geladen: {len(existing)}")
                if self.on_existing_tracks:
                    self.on_existing_tracks(existing)

            self._log_size = log_path.stat().st_size
            return []

        try:
            current_size = log_path.stat().st_size
        except OSError:
            return []

        if current_size == self._log_size:
            return []

        # Log-Datei wurde neu erstellt (z.B. Serato neu gestartet, neuer Tag)
        # current_size < _log_size = Datei ist kleiner als bekannt → Reset
        if current_size < self._log_size:
            log.info(f"Log-Datei wurde zurückgesetzt (neu erstellt): {log_path.name}")
            self._log_size  = 0
            self._staged    = None
            self._staged_at = 0.0

        new_tracks = []
        try:
            with open(log_path, "rb") as f:
                f.seek(self._log_size)
                new_bytes = f.read(current_size - self._log_size)
            self._log_size = current_size
        except (OSError, IOError) as e:
            log.warning(f"Log read error: {e}")
            return []

        new_text = new_bytes.decode("utf-8", errors="replace")
        for line in new_text.split("\n"):
            track = self._process_line(line.rstrip())
            if track:
                new_tracks.append(track)

        return new_tracks

    def _process_line(self, line: str) -> Optional[Track]:
        """
        Two-Stage Erkennung:
        Stage 1 — 'Adding entry': Track auf Deck geladen → staged (noch nicht ausgeben)
        Stage 2 — 'Updating entry': vorheriger Track wirklich gespielt → staged ausgeben

        Timeout: _poll_loop gibt staged Track nach 5s aus falls kein 'Updating entry' kommt
        (letzter Track der Session, oder kurze Previews die nie abgelöst werden).
        """
        m_deck = self.RE_DECK.search(line)
        if m_deck:
            self._pending_deck = m_deck.group(2)

        m_stems = self.RE_STEMS.search(line)
        if m_stems:
            self._pending_file = m_stems.group(1).strip()
            return None

        m_view = self.RE_VIEW.search(line)
        if m_view and not self._pending_file:
            self._pending_file = m_view.group(1).strip()
            return None

        # Stage 1: Track geladen → staged, noch NICHT ausgeben
        if self.RE_HISTORY.search(line) and self._pending_file:
            filepath           = self._pending_file
            deck               = self._pending_deck
            self._pending_file = None
            candidate = self._parse_filename(filepath, deck)
            if candidate:
                self._staged    = candidate
                self._staged_at = time.time()
                log.debug(f"Staged (loaded): {candidate.display}")
                # Sofortiger Callback für Duplikat-Check beim Laden
                if self.on_loaded:
                    self.on_loaded(candidate)
            return None

        # Stage 2: 'Updating entry' → staged Track war wirklich gespielt
        if self.RE_PLAYED.search(line) and self._staged:
            track               = self._staged
            alerted             = self._staged_alerted
            self._staged        = None
            self._staged_at     = 0.0
            self._staged_alerted = False
            track.played_at     = time.time()
            track._was_alerted  = alerted  # für _poll_loop/Engine
            log.info(f"▶ [played] {track.display}")
            return track

        return None

    def _parse_filename(self, filepath: str, deck: str) -> Optional[Track]:
        if not filepath:
            return None

        artist, title, _ = _library_reader.lookup(filepath)
        if title:
            log.debug(f"Library [{deck}]: {artist!r} – {title!r}")
            return Track(artist, title, "", time.time())

        try:
            stem = Path(filepath).stem
        except Exception:
            return None

        if not stem:
            return None

        cleaned = stem
        cleaned = re.sub(
            r"\s*-\s*(?:HD\s*-\s*)?(?:Dirty|Clean|Explicit|Instrumental|Acapella)\s*$",
            "",
            cleaned,
            flags=re.IGNORECASE,
        ).strip()
        cleaned = re.sub(r"\s*-\s*HD\s*$", "", cleaned, flags=re.IGNORECASE).strip()

        for _ in range(4):
            prev = cleaned
            cleaned = re.sub(r"\s*\[[^\]]*\]", "", cleaned)
            cleaned = re.sub(r"\s*\([^\)]*\)", "", cleaned)
            if cleaned == prev:
                break

        cleaned = re.sub(
            r"\s*-\s*(?:HD|Dirty|Clean|Explicit|Radio\s*Edit|Extended|Original)\s*$",
            "",
            cleaned,
            flags=re.IGNORECASE,
        )
        cleaned = cleaned.strip(" -").strip()

        if not cleaned:
            cleaned = stem

        m = re.match(r"^(.{2,}?)\s+-\s+(.{2,})$", cleaned)
        if m:
            return Track(m.group(1).strip(), m.group(2).strip(), "", time.time())

        return Track("", cleaned, "", time.time())

    def _read_existing_tracks(self, log_path: Path) -> list[Track]:
        try:
            content = log_path.read_bytes().decode("utf-8", errors="replace")
        except OSError:
            return []

        tracks = []
        pending = None

        for line in content.split("\n"):
            line = line.rstrip()

            m_stems = self.RE_STEMS.search(line)
            if m_stems:
                pending = m_stems.group(1).strip()
                continue

            m_view = self.RE_VIEW.search(line)
            if m_view and not pending:
                pending = m_view.group(1).strip()
                continue

            if self.RE_HISTORY.search(line) and pending:
                t = self._parse_filename(pending, "deck_0")
                if t:
                    tracks.append(t)
                pending = None

        return tracks

    def _find_log(self) -> Optional[Path]:
        log_dir = SERATO_PATH.parent / "Logs"
        if not log_dir.exists():
            return None
        try:
            info_log = log_dir / "DJ.INFO"
            if info_log.exists():
                return info_log
            logs = sorted(log_dir.glob("20*.log"), key=lambda p: p.stat().st_mtime, reverse=True)
            return logs[0] if logs else None
        except (OSError, FileNotFoundError):
            return None


# ── WebSocket Hub ─────────────────────────────────────────────────────────────
class WebSocketHub:
    def __init__(self):
        self._clients: dict[str, ConnectedClient] = {}
        self._lock = asyncio.Lock()

    async def register(self, ws: WebSocketServerProtocol, hello: dict) -> ConnectedClient:
        ip = ws.remote_address[0] if ws.remote_address else "?"
        client = ConnectedClient(
            ws=ws,
            name=hello.get("name", "Unbekannt"),
            device=hello.get("device", ""),
            ip=ip,
            is_peer=bool(hello.get("is_peer", False)),
            peer_node_id=hello.get("node_id", ""),
            venue_id=hello.get("venue_id", ""),
        )
        async with self._lock:
            self._clients[client.client_id] = client
        log.info(f"+ {client.name} ({client.ip}) {'[PEER]' if client.is_peer else '[client]'}")
        return client

    async def unregister(self, client_id: str):
        async with self._lock:
            client = self._clients.pop(client_id, None)
        if client:
            log.info(f"- {client.name} ({client.ip}) disconnected")

    async def broadcast(self, msg: dict, exclude_id: Optional[str] = None, venue_id: Optional[str] = None):
        payload = json.dumps(msg, ensure_ascii=False)
        dead: set[str] = set()

        async with self._lock:
            snapshot = dict(self._clients)

        for cid, client in snapshot.items():
            if cid == exclude_id:
                continue
            # Venue-Filter: Peers (andere DJs) bekommen IMMER alle track_events
            # damit sie ihre History aktuell halten können
            msg_type = msg.get("type", "")
            if venue_id and client.venue_id and client.venue_id != venue_id:
                if not (client.is_peer and msg_type == "track_event"):
                    continue
            try:
                await client.ws.send(payload)
            except websockets.ConnectionClosed:
                dead.add(cid)

        for cid in dead:
            await self.unregister(cid)

    async def send_to(self, client_id: str, msg: dict):
        async with self._lock:
            client = self._clients.get(client_id)

        if client:
            try:
                await client.ws.send(json.dumps(msg, ensure_ascii=False))
            except websockets.ConnectionClosed:
                await self.unregister(client_id)

    @staticmethod
    def _is_loopback(ip: str) -> bool:
        """Erkennt alle Loopback-Varianten: IPv4, IPv6, IPv4-mapped IPv6 (M1/ARM)."""
        return (
            ip in ("127.0.0.1", "::1", "localhost", "")
            or ip.startswith("127.")
            or ip.startswith("::ffff:127.")
        )

    def get_client_list(self) -> list[dict]:
        # Lokalen Client aus der Liste ausschliessen —
        # der eigene Mac soll nicht als "verbundener DJ" angezeigt werden.
        # Filtert alle Loopback-Varianten (IPv4, IPv6, IPv4-mapped auf M1/ARM).
        return [c.to_dict() for c in self._clients.values()
                if not self._is_loopback(c.ip)]

    async def ping_all(self):
        now = time.time()
        dead: set[str] = set()

        async with self._lock:
            snapshot = dict(self._clients)

        for cid, client in snapshot.items():
            if now - client.last_seen > CLIENT_TIMEOUT:
                dead.add(cid)
                continue
            try:
                await client.ws.ping()
                client.touch()
            except Exception:
                dead.add(cid)

        for cid in dead:
            await self.unregister(cid)


# ── Haupt-Engine ──────────────────────────────────────────────────────────────
class SeratoGuardEngine:
    def __init__(self):
        self.settings = Settings()
        self.db = TrackDatabase(DB_PATH)
        self.poller = SessionPoller()
        # Stage 1 Callback: Track geladen → sofort prüfen ob Duplikat
        self.poller.on_loaded = lambda track: asyncio.run_coroutine_threadsafe(
            self._on_track_loaded(track), self._loop
        )
        self.poller.on_existing_tracks = lambda tracks: [
            self.db.insert_track(t, self.settings.venue_id, source_node="local")
            for t in tracks
        ]
        self.hub = WebSocketHub()
        self.matcher = TrackMatcher(self.settings.match_threshold)
        self.node_id = str(uuid.uuid4())[:12]
        self._running = False

    def _local_ip(self) -> str:
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
                s.connect(("8.8.8.8", 80))
                return s.getsockname()[0]
        except Exception:
            return "127.0.0.1"

    def _get_matching_history(self) -> list[Track]:
        self.settings.reload()
        self.matcher.threshold = self.settings.match_threshold
        venue = self.settings.venue_id
        if self.settings.window_mode == "hours":
            since = time.time() - self.settings.window_hours * 3600
        else:
            since = self.poller.session_start
        return self.db.get_tracks(venue, since_ts=since)

    async def start(self):
        self._running = True
        self._loop = asyncio.get_event_loop()
        log.info(f"SeratoGuard v2 | node={self.node_id}")
        log.info(f"WebSocket: ws://{self._local_ip()}:{WS_PORT}")
        log.info(f"Venue: {self.settings.venue_id}")
        log.info(f"DB: {DB_PATH}")
        log.info(f"Serato History Pfad: {SERATO_PATH}")
        self._log_serato_files()

        async def health_check(connection, request):
            """Antwortet auf HTTP GET /health mit 200 OK — für Swift readiness check."""
            if request.path == "/health":
                return connection.respond(200, "ok\n")
            return None

        async def ws_handler_silent(connection):
            """Wrapper der ConnectionClosedError von HTTP-Requests unterdrückt."""
            try:
                await self._ws_handler(connection)
            except Exception as e:
                err = str(e)
                if "no close frame" not in err and "opening handshake" not in err:
                    raise

        # websockets-internen Logger für harmlose HTTP-Probe-Fehler stumm schalten
        import logging
        logging.getLogger("websockets.server").setLevel(logging.CRITICAL)

        async with websockets.serve(
            ws_handler_silent,
            WS_HOST,
            WS_PORT,
            ping_interval=None,
            max_size=10_485_760,
            process_request=health_check,
        ):
            await asyncio.gather(
                self._poll_loop(),
                self._heartbeat_loop(),
                self._announce_loop(),
            )

    def _log_serato_files(self):
        log_dir = SERATO_PATH.parent / "Logs"
        info_log = log_dir / "DJ.INFO"
        if info_log.exists():
            size = info_log.stat().st_size
            age = int(time.time() - info_log.stat().st_mtime)
            log.info(f"  Serato Log: {info_log} ({size}B, vor {age}s geändert)")
            log.info("  Warte auf neue Tracks in DJ.INFO...")
        else:
            log.warning(
                f"KEIN Serato Log gefunden in {log_dir}\n"
                f"  → Serato DJ Pro starten, dann erscheint DJ.INFO automatisch"
            )

    async def _ws_handler(self, ws: WebSocketServerProtocol):
        client = None
        try:
            raw = await asyncio.wait_for(ws.recv(), timeout=10.0)
            hello = json.loads(raw)

            if hello.get("action") != "hello":
                await ws.close(1002, "Expected hello")
                return

            client = await self.hub.register(ws, hello)

            if not client.is_peer:
                client.venue_id = self.settings.venue_id

            if client.is_peer:
                await self._sync_with_peer(client)

            await self._send_welcome(client)

            async for raw_msg in ws:
                try:
                    msg = json.loads(raw_msg)
                    await self._handle_message(client, msg)
                    client.touch()
                except (json.JSONDecodeError, KeyError):
                    pass

        except asyncio.TimeoutError:
            log.warning(f"Hello-Timeout von {ws.remote_address}")
        except websockets.ConnectionClosed:
            pass
        except Exception as e:
            log.error(f"WS handler error: {e}", exc_info=True)
        finally:
            if client:
                await self.hub.unregister(client.client_id)
                await self._broadcast_client_list()

    async def _send_welcome(self, client: ConnectedClient):
        history = self._get_matching_history()
        await self.hub.send_to(client.client_id, {
            "type": "welcome",
            "node_id": self.node_id,
            "venue_id": self.settings.venue_id,
            "venue_name": self.settings.venue_name,
            "history": [t.to_dict() for t in history[-200:]],
            "clients": self.hub.get_client_list(),
            "window_mode": self.settings.window_mode,
            "window_hours": self.settings.window_hours,
            "min_play_seconds": self.settings.min_play_seconds,
        })

    async def _sync_with_peer(self, client: ConnectedClient):
        venue = self.settings.venue_id
        our_tracks = self.db.get_all_tracks_for_sync(venue)
        await self.hub.send_to(client.client_id, {
            "type": "history_sync",
            "venue_id": venue,
            "tracks": our_tracks,
            "node_id": self.node_id,
        })
        log.info(f"Sent {len(our_tracks)} tracks to peer {client.name}")
        self.db.upsert_peer(
            client.peer_node_id or client.client_id,
            client.ip,
            WS_PORT,
            venue,
        )

    async def _handle_message(self, client: ConnectedClient, msg: dict):
        action = msg.get("action") or msg.get("type")

        if action == "hello":
            client.name = msg.get("name", client.name)
            client.device = msg.get("device", client.device)
            client.is_peer = bool(msg.get("is_peer", client.is_peer))
            client.peer_node_id = msg.get("node_id", client.peer_node_id)
            client.venue_id = msg.get("venue_id", self.settings.venue_id) or self.settings.venue_id
            client.touch()

            log.info(f"hello update -> {client.name} venue={client.venue_id} peer={client.is_peer}")

            await self.hub.send_to(client.client_id, {
                "type": "client_list",
                "clients": self.hub.get_client_list(),
            })
            return

        if action == "ping":
            await self.hub.send_to(client.client_id, {"action": "pong"})

        elif action == "history_sync":
            venue_id = msg.get("venue_id", self.settings.venue_id)
            tracks = msg.get("tracks", [])
            added = 0

            for td in tracks:
                t = Track(
                    td["artist"],
                    td["title"],
                    td.get("album", ""),
                    float(td["played_at"])
                )
                if self.db.insert_track(t, venue_id, source_node=msg.get("node_id", "peer")):
                    added += 1

            log.info(f"Peer sync von {client.name}: {added}/{len(tracks)} Tracks")

        elif action == "track_event":
            # Anderer DJ hat einen Track gespielt → in unsere History aufnehmen
            # und prüfen ob wir den gleichen Track schon gespielt haben
            td = msg.get("track", {})
            if not td:
                return
            peer_sync = msg.get("peer_sync", False)
            t = Track(
                td.get("artist", ""),
                td.get("title", ""),
                td.get("album", ""),
                float(td.get("played_at", time.time()))
            )
            venue_id = msg.get("venue_id", self.settings.venue_id)
            added = self.db.insert_track(t, venue_id, source_node=client.client_id)
            if added:
                log.info(f"Peer track von {client.name}: {t.display}")
                # Unsere History gegen diesen Peer-Track prüfen
                # Damit wir wissen ob WIR diesen Song auch gespielt haben
                history = self._get_matching_history()
                result = self.matcher.check(t, history)
                if result["is_duplicate"] and not peer_sync:
                    matched = result["matched"]
                    tag = "exact" if result["is_exact"] else f"{result['score']}%"
                    log.warning(f"PEER DUPLICATE [{tag}]: {client.name} spielt {t.display} ← {matched.display if matched else '?'}")
                    # Alert an lokalen Swift-Client senden
                    await self.hub.broadcast({
                        "type":          "track_event",
                        "track":         matched.to_dict() if matched else t.to_dict(),
                        "loaded_track":  t.to_dict(),
                        "is_duplicate":  True,
                        "is_exact":      result["is_exact"],
                        "score":         result["score"],
                        "matched":       matched.to_dict() if matched else None,
                        "similar":       [],
                        "peer_name":     client.name,  # welcher DJ spielt es
                        "is_loaded":     True,
                        "history_count": len(history),
                        "timestamp":     time.time(),
                        "venue_id":      self.settings.venue_id,
                    }, venue_id=self.settings.venue_id)

        elif action == "get_history":
            history = self._get_matching_history()
            await self.hub.send_to(client.client_id, {
                "type": "history_update",
                "history": [t.to_dict() for t in history],
            })

        elif action == "get_clients":
            await self.hub.send_to(client.client_id, {
                "type": "client_list",
                "clients": self.hub.get_client_list(),
            })

        elif action == "reset_history":
            self.poller._session_start = time.time()
            await self.hub.broadcast({"type": "history_reset"})
            log.info("Session-History zurückgesetzt")

        elif action == "update_settings":
            data = msg.get("data", {})

            if "matchThreshold" in data:
                v = int(data["matchThreshold"])
                self.matcher.threshold = v
                self.settings.match_threshold = v

            if "venueId" in data:
                self.settings.venue_id = data["venueId"]

            if "windowMode" in data:
                self.settings.window_mode = data["windowMode"]

            if "windowHours" in data:
                self.settings.window_hours = float(data["windowHours"])

            if "minPlaySeconds" in data:
                self.settings.min_play_seconds = int(data["minPlaySeconds"])

            client.venue_id = self.settings.venue_id
            client.touch()
            log.info(f"update_settings -> server venue now {self.settings.venue_id}")

        elif action == "register_peer":
            self.db.upsert_peer(
                msg.get("node_id", client.client_id),
                client.ip,
                WS_PORT,
                msg.get("venue_id", "")
            )

    async def _on_track_loaded(self, track: Track):
        """Stage 1: Track geladen → sofort gegen played-History prüfen → Alert wenn Duplikat."""
        venue = self.settings.venue_id
        self.db.insert_loaded(track, venue)
        history = self._get_matching_history()
        result  = self.matcher.check(track, history)
        # Merken ob Alert schon gesendet → _process_track sendet dann keinen zweiten
        self.poller._staged_alerted = result["is_duplicate"]
        if result["is_duplicate"]:
            matched = result["matched"]
            tag = "exact" if result["is_exact"] else f"{result['score']}%"
            log.warning(f"LOADED DUPLICATE [{tag}]: {track.display} ← {matched.display if matched else '?'}")
            # Track im Payload = der geladene, matched = der schon gespielte
            # Swift zeigt matched im Kreis (damit DJ weiss WAS schon gespielt wurde)
            await self.hub.broadcast({
                "type":         "track_event",
                "track":        matched.to_dict() if matched else track.to_dict(),  # gespielter Track
                "loaded_track": track.to_dict(),    # geladener Track (Kontext)
                "is_duplicate": True,
                "is_exact":     result["is_exact"],
                "score":        result["score"],
                "matched":      matched.to_dict() if matched else None,
                "similar":      [],
                "is_loaded":    True,
                "history_count": len(history),
                "timestamp":    time.time(),
                "venue_id":     venue,
            }, venue_id=venue)

    async def _poll_loop(self):
        while self._running:
            try:
                new_tracks = self.poller.poll()
                for track in new_tracks:
                    alerted = getattr(track, '_was_alerted', False)
                    await self._process_track(track, suppress_broadcast=alerted)

                # Staged-Track Timeout: nach minPlaySeconds gilt Track als gespielt
                if (self.poller._staged and
                        self.poller._staged_at > 0 and
                        time.time() - self.poller._staged_at > self.settings.min_play_seconds):
                    track = self.poller._staged
                    alerted = getattr(self.poller, '_staged_alerted', False)
                    self.poller._staged         = None
                    self.poller._staged_at      = 0.0
                    self.poller._staged_alerted = False
                    track.played_at = time.time()
                    log.info(f"▶ [timeout] {track.display}")
                    # Wenn beim Laden schon ein Alert gesendet wurde: nur in DB speichern
                    await self._process_track(track, suppress_broadcast=alerted)

            except Exception as e:
                log.error(f"Poll error: {e}", exc_info=True)
            await asyncio.sleep(POLL_INTERVAL)

    async def _process_track(self, track: Track, suppress_broadcast: bool = False):
        venue = self.settings.venue_id
        history = self._get_matching_history()
        result = self.matcher.check(track, history)
        self.db.insert_track(track, venue, source_node="local")

        if suppress_broadcast:
            # Beim Laden schon gemeldet — nur in DB speichern
            # ABER: Peers (andere DJs) müssen trotzdem den Track bekommen
            if result["is_duplicate"]:
                matched = result["matched"]
                tag = "exact" if result["is_exact"] else f"{result['score']}%"
                log.warning(f"DUPLICATE [{tag}] (silent): {track.display} ← {matched.display if matched else '?'}")
            else:
                log.info(f"OK (silent): {track.display}")
            # Sync zu Peers: track_event senden damit andere DJs die History haben
            await self.hub.broadcast({
                "type":          "track_event",
                "track":         track.to_dict(),
                "is_duplicate":  result["is_duplicate"],
                "is_exact":      result["is_exact"],
                "score":         result["score"],
                "matched":       result["matched"].to_dict() if result["matched"] else None,
                "similar":       [],
                "peer_sync":     True,   # nur History-Sync, kein Alert beim Absender
                "history_count": len(history) + 1,
                "timestamp":     time.time(),
                "venue_id":      venue,
            }, venue_id=venue)
            return

        matched = result["matched"]
        await self.hub.broadcast({
            "type": "track_event",
            "track": track.to_dict(),
            "is_duplicate": result["is_duplicate"],
            "is_exact": result["is_exact"],
            "score": result["score"],
            "matched": matched.to_dict() if matched else None,
            "similar": [
                {
                    "artist": t.artist,
                    "title": t.title,
                    "display": t.display,
                    "score": s,
                }
                for t, s in result["similar_tracks"]
            ],
            "history_count": len(history) + 1,
            "timestamp": time.time(),
            "venue_id": venue,
        }, venue_id=venue)

        if result["is_duplicate"]:
            tag = "exact" if result["is_exact"] else f"{result['score']}%"
            log.warning(f"DUPLICATE [{tag}]: {track.display} ← {matched.display if matched else '?'}")
        else:
            log.info(f"OK: {track.display}")

    async def _heartbeat_loop(self):
        while self._running:
            await asyncio.sleep(HEARTBEAT_INTERVAL)
            await self.hub.ping_all()

    async def _announce_loop(self):
        while self._running:
            await self.hub.broadcast({
                "type": "server_info",
                "node_id": self.node_id,
                "ip": self._local_ip(),
                "port": WS_PORT,
                "venue_id": self.settings.venue_id,
                "venue_name": self.settings.venue_name,
                "window_mode": self.settings.window_mode,
                "window_hours": self.settings.window_hours,
            "min_play_seconds": self.settings.min_play_seconds,
                "clients": self.hub.get_client_list(),
            })
            await asyncio.sleep(30)

    async def _broadcast_client_list(self):
        await self.hub.broadcast({
            "type": "client_list",
            "clients": self.hub.get_client_list(),
        })

    def stop(self):
        self._running = False


# ── Entry Point ───────────────────────────────────────────────────────────────
def main():
    engine = SeratoGuardEngine()
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)

    def _shutdown(*_):
        log.info("Shutdown signal empfangen")
        engine.stop()
        loop.stop()

    signal.signal(signal.SIGTERM, _shutdown)
    signal.signal(signal.SIGINT, _shutdown)

    try:
        loop.run_until_complete(engine.start())
    except RuntimeError:
        pass
    finally:
        loop.close()
        log.info("SeratoGuard gestoppt")


if __name__ == "__main__":
    main()
