import csv
import io
import sqlite3
import zipfile
from typing import Optional


def parse_apkg(file_bytes: bytes) -> dict:
    results = {
        "deck_name": "Unknown",
        "total_cards": 0,
        "preview": [],
        "media_files": [],
        "errors": [],
    }

    try:
        with zipfile.ZipFile(io.BytesIO(file_bytes), "r") as zf:
            names = zf.namelist()

            if "collection.anki2" not in names:
                results["errors"].append("Invalid Anki package: collection.anki2 not found")
                return results

            media_files = [n for n in names if not n.endswith(".anki2") and not n.endswith("/")]
            results["media_files"] = media_files[:20]

            with zf.open("collection.anki2") as db_file:
                db_bytes = db_file.read()

            conn = sqlite3.connect(":memory:")
            conn.executescript(db_bytes.decode("latin-1", errors="replace"))
            conn.text_factory = str

            try:
                conn.execute("SELECT * FROM col LIMIT 1")
            except sqlite3.Error:
                results["errors"].append("Unsupported Anki version. Please use Anki 2.1+ to export.")
                conn.close()
                return results

            col_rows = list(conn.execute("SELECT name FROM col"))
            if col_rows:
                results["deck_name"] = col_rows[0][0] or "Unknown"

            note_rows = list(conn.execute("SELECT id, guid, mid, flds, tags FROM notes LIMIT 200"))
            results["total_cards"] = len(note_rows)

            for note_row in note_rows[:10]:
                note_id, guid, mid, flds, tags = note_row
                fields = flds.split("\x1f") if flds else []

                try:
                    tmpl_rows = list(conn.execute(
                        "SELECT name, ord FROM fields WHERE ntid = ? ORDER BY ord", (mid,)
                    ))
                except sqlite3.Error:
                    tmpl_rows = []

                front = fields[0] if len(fields) > 0 else ""
                back = fields[1] if len(fields) > 1 else ""

                if tmpl_rows:
                    field_map = {row[1]: row[0] for row in tmpl_rows}
                    front = fields[0] if 0 in field_map and len(fields) > 0 else front
                    back = fields[1] if 1 in field_map and len(fields) > 1 else back

                note_type = "Cloze" if "{{c" in front or "{{c" in back else "Basic"

                results["preview"].append({
                    "front": front[:200],
                    "back": back[:200],
                    "tags": tags or "",
                    "note_type": note_type,
                })

            conn.close()

    except zipfile.BadZipFile:
        results["errors"].append("Invalid zip file")
    except Exception as e:
        results["errors"].append(str(e)[:500])

    return results


def parse_csv_content(content: str) -> list[dict]:
    results = []
    try:
        dialect = csv.Sniffer().sniff(content[:1024])
        reader = csv.DictReader(io.StringIO(content), dialect=dialect)
    except (csv.Error, UnicodeDecodeError):
        lines = content.strip().split("\n")
        if not lines:
            return results

        first_line = lines[0]
        delimiter = "\t" if "\t" in first_line else ","
        reader = csv.DictReader(lines, delimiter=delimiter)

    for row in reader:
        results.append({k.strip(): v.strip() for k, v in row.items() if v})

    return results


def map_csv_to_cards(rows: list[dict], front_col: str, back_col: str, tags_col: Optional[str] = None) -> list[dict]:
    cards = []
    for row in rows:
        front = row.get(front_col, "")
        back = row.get(back_col, "")
        tags = row.get(tags_col, "") if tags_col else ""

        if not front or not back:
            continue

        cloze_answer = ""
        if "{{c" in front:
            import re
            match = re.search(r"\{\{c\d+::(.*?)\}\}", front)
            if match:
                cloze_answer = match.group(1)
            front = re.sub(r"\{\{c\d+::.*?\}\}", "______", front)

        cards.append({
            "front_text": front,
            "back_answer": cloze_answer or back,
            "back_meaning": back if cloze_answer else "",
            "tags": tags,
        })

    return cards