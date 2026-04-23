# Local-Web-Capture

Claude Code plugin for capturing web content **from the user's own machine** — so every request exits via the user's IP. Built for geo-restricted content (seeded with Israeli news + e-commerce) where hosted scrapers get blocked at the edge.

## Principle

Cheapest method that works wins. Escalation ladder:

| Rung | Method | Tool | When |
|------|--------|------|------|
| 1 | Headless, static HTTP | Scrapling `Fetcher` | Default. Server-rendered articles, simple prices. |
| 2 | Headless, stealth | Scrapling `StealthyFetcher` (Camoufox) | Bot-blocked / Cloudflare. |
| 2b | Headless, JS render | Scrapling `PlayWrightFetcher` | Needs JS, no bot block. |
| 3 | Real Chrome, logged in | `bb-browser` | Paywalled / session-bound. |

Backups (installed, not default): `webclaw`, `lightpanda`, `camofox-browser`, `stealth-browser-mcp`, Playwright MCP.

Per-domain choice is cached in `sites.yaml` so the right rung is picked on repeat captures.

## Skills

- `setup-tools` — one-time install of Scrapling, bb-browser, data dir seeding.
- `scrape-article` — Rungs 1–3, save markdown capture.
- `scrape-authenticated` — Rung 4 only, real Chrome via bb-browser.
- `scrape-price` — structured price snapshot for e-commerce URLs.
- `capture-translate` — scrape + save a translated version (default he→en; arbitrary pairs supported).
- `batch-capture` — list of URLs in, individual captures + human/agent summary reports out.
- `batch-to-pdf` — compile a batch into a single typeset PDF (Typst) with source URL + capture date per article and page-numbered footer.
- `capture-list` — browse/search/summarise the data directory.

## Where captures are saved

Resolution order (see `reference/save-location.md`):

1. `--out <path>` explicit override.
2. **Project-local** — if the current working directory is inside a git repo, save to `<repo_root>/captures/`. Keeps research artefacts with the project they inform.
3. **Global fallback** — `~/local-web-capture/`.

Layout is the same in both modes:

```
<root>/
├── articles/YYYY/MM/*.md         # markdown + frontmatter
├── prices/<domain>/*.json        # structured price snapshots
├── translations/YYYY/MM/*.md     # stacked translations
├── batches/<batch-id>/           # batch-capture output
│   ├── articles/
│   ├── report.md                 # human-summary
│   ├── report.agent.json         # agent-summary (strict schema)
│   └── report.pdf                # optional, via batch-to-pdf
├── sites.yaml                    # per-domain strategy cache
└── .cache/
```

See `reference/data-layout.md` for the full schema.

## Toolkit evaluation

See `toolkit-options.md` for the shortlist of ~22 candidate browser/extractor projects ranked by stars with verdicts.

## Important: MCP bias note

Once the plugin is validated end-to-end, **remove Playwright from user-level MCP config**. If it stays globally visible, Claude will pull toward it on every scrape request regardless of what the skill ladder says. Leaving it at project level (or installing only when needed) keeps the ladder honest.
