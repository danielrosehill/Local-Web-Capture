---
name: capture-list
description: Browse, search, or summarise what's in the local-web-capture data directory (~/local-web-capture/). Use when the user asks "what did I capture recently", "find my captures of X", "list articles from ynet", or wants a table of recent captures.
---

# capture-list

Read-only browser over `~/local-web-capture/`.

## Supported queries

- **Recent**: last N captures across articles/, prices/, translations/.
- **By domain**: all captures from a specific site.
- **By date range**: YYYY-MM or YYYY-MM-DD..YYYY-MM-DD.
- **Text search**: grep titles and first paragraphs.
- **Price history**: for a given product URL, show all snapshots + delta chart (simple text).

## Implementation

Walk the tree, parse frontmatter/JSON, and print a table:

```
DATE        DOMAIN          TITLE                                    EXTRACTOR   WORDS
2026-04-22  ynet.co.il      ...                                       webclaw     812
2026-04-20  haaretz.co.il   ...                                       bb-browser  1240
```

Use `rg` / `find` for speed. Do not load whole article bodies unless asked.

## Do not

- Do not modify or delete captures from this skill (that's out of scope — user does it manually).
- Do not re-scrape; this is a local read-only view.
