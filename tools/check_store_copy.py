#!/usr/bin/env python3
"""
Check the Harbour store copy against the form's limits.

    python3 tools/check_store_copy.py

Harbour silently truncates or rejects over-long fields, and the summary limit
in particular is easy to sail past once you start editing. Run this after any
change to store/STORE.md.
"""

import re
import sys
from pathlib import Path

LIMITS = {"Summary": 200, "Description": 4000}


def main() -> int:
    doc = Path(__file__).resolve().parent.parent / "store" / "STORE.md"
    text = doc.read_text()
    ok = True

    for field, limit in LIMITS.items():
        m = re.search(
            r"^## " + field + r"\b.*?```\n(.*?)```",
            text, re.S | re.M,
        )
        if not m:
            print(f"MISSING  {field}: no fenced block found under '## {field}'")
            ok = False
            continue
        body = m.group(1).rstrip("\n")
        n = len(body)
        status = "ok " if n <= limit else "OVER"
        if n > limit:
            ok = False
        print(f"{status}  {field:<12} {n:>5} / {limit} characters"
              f"{'  (' + str(n - limit) + ' too many)' if n > limit else ''}")

    print("\nall fields fit" if ok else "\nFIX THE FIELDS MARKED OVER")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
