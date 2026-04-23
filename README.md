# Local-Web-Capture

Claude Code plugin for capturing web content **from the user's own machine** — so every request exits via the user's Israeli IP. Built for geo-restricted Israeli news sites and Israeli e-commerce pricing, where hosted scrapers (Jina, Firecrawl SaaS, etc.) get blocked at the edge.

## Principle

Cheapest method that works wins. Escalation ladder:

| Rung | Method | Tool | When |
|------|--------|------|------|
| 1 | Headless, purpose-built | `webclaw` | Default. Server-rendered articles, simple prices. |
| 2 | Headless, full JS | `lightpanda` / Playwright MCP | Rung 1 returned thin content. |
| 3 | Headless, stealth | `camofox` / `stealth-browser-mcp` | Bot-blocked. |
| 4 | Real Chrome, logged in | `bb-browser` | Paywalled / session-bound. |

Per-domain choice is cached in `~/local-web-capture/sites.yaml` so the right rung is picked on repeat captures.

## Skills

- `setup-tools` — one-time install of webclaw, bb-browser, data dir seeding.
- `scrape-article` — Rungs 1–3, save markdown capture.
- `scrape-authenticated` — Rung 4 only, real Chrome via bb-browser.
- `capture-translate` — scrape + save a translated version (default he→en; arbitrary pairs supported).
- `capture-list` — browse/search/summarise the data directory.

## Data directory

Everything lands under `~/local-web-capture/`:

```
articles/YYYY/MM/*.md       # markdown + frontmatter
prices/<domain>/*.json      # structured price snapshots
translations/YYYY/MM/*.md   # stacked translations
sites.yaml                   # per-domain strategy cache
.cache/                      # extractor internals
```

See `reference/data-layout.md` for the full schema.

## Toolkit evaluation

See `toolkit-options.md` for the full shortlist of ~22 candidate browser/extractor projects and verdicts.

## Important: MCP bias note

Once the plugin is validated end-to-end, **remove Playwright from user-level MCP config** (`~/.claude/settings.json`). If it stays globally visible, Claude will pull toward it on every scrape request regardless of what the skill ladder says. Leaving it at project level (or installing only when needed) keeps the ladder honest.
