#!/usr/bin/env python3
"""Merge supplement data into collocations.json."""
import json

JSON_PATH = "platform/plugins/english_listening/assets/collocations.json"
SUPP_PATH = "collocations_supplement.json"

with open(JSON_PATH, "r", encoding="utf-8") as f:
    data = json.load(f)

with open(SUPP_PATH, "r", encoding="utf-8") as f:
    supplement = json.load(f)

print(f"Existing: {len(data)} entries")
print(f"Supplement: {len(supplement)} entries")

added = 0
skipped = 0
for key, val in supplement.items():
    if key.lower() not in {k.lower() for k in data}:
        data[key] = val
        added += 1
    else:
        skipped += 1

print(f"Added: {added}, Skipped (duplicate): {skipped}")

# Sort by type then alphabetically
type_order = {"phrasalVerb": 0, "prepositional": 1, "noun": 2, "adjective": 3, "idiom": 4}
sorted_items = sorted(data.items(), key=lambda x: (type_order.get(x[1].get("type", "idiom"), 99), x[0]))

with open(JSON_PATH, "w", encoding="utf-8") as f:
    f.write("{\n")
    for i, (word, entry) in enumerate(sorted_items):
        comma = "," if i < len(sorted_items) - 1 else ""
        f.write(f'  "{word}": {{"type":"{entry["type"]}","meaning":"{entry["meaning"]}"}}{comma}\n')
    f.write("}\n")

from collections import Counter
types = Counter(v["type"] for _, v in sorted_items)
print(f"\nTotal: {len(sorted_items)}")
print(f"By type: {dict(types)}")
print("Done!")