---
name: scrape-article
description: Scrape an article from a URL via the user's localhost (preserves Israeli IP for geo-restricted sites) and save a clean markdown capture. Use when the user gives a URL and wants the article body saved, or says "capture this article", "scrape this", or references Israeli news sites (ynet, haaretz, n12, calcalist, timesofisrael, etc.).
---

# scrape-article

Capture a single article and save it as markdown with frontmatter. Resolve save root per `reference/save-location.md` (project-local `<repo>/captures/articles/YYYY/MM/` preferred, else `~/local-web-capture/articles/YYYY/MM/`, `--out` overrides).

## Hard constraint

Requests must originate from this machine. Do **not** route through a hosted reader (Jina, Firecrawl SaaS, ScrapingBee, etc.).

## Escalation ladder — stop at the first rung that returns a real body

All rungs are headless except Tier 3. Prefer speed: do not skip ahead unless `sites.yaml` marks the domain as known-hard.

### Rung 1 — Scrapling `Fetcher` (static, fastest)

Plain HTTP + lxml. No browser. Use this by default.

```python
from scrapling.fetchers import Fetcher

page = Fetcher.get(url, stealthy_headers=True, follow_redirects=True, timeout=20)
# page.status, page.html_content, page.css("article"), page.markdown
```

If `page.status` ≥ 400, body < 200 chars, or the main content looks like nav/boilerplate → escalate.

### Rung 2 — Scrapling `StealthyFetcher` (Camoufox, anti-bot)

Headless. Use when Tier 1 hit 403, Cloudflare challenge, or empty body on a site that shouldn't be empty.

```python
from scrapling.fetchers import StealthyFetcher

page = StealthyFetcher.fetch(url, headless=True, network_idle=True, humanize=True)
```

### Rung 2b — Scrapling `PlayWrightFetcher` (JS render, no stealth)

Headless. Use when the page needs JS to populate content but is not bot-blocked.

```python
from scrapling.fetchers import PlayWrightFetcher

page = PlayWrightFetcher.fetch(url, headless=True, network_idle=True)
```

### Rung 3 — authenticated real browser

**Do not use from this skill.** If the page is paywalled or session-bound, stop and tell the user to run `scrape-authenticated` (uses bb-browser).

### Backup paths (only if Scrapling fails on a specific domain)

- `webclaw --format markdown --only-main-content "<url>"` — Rust CLI fallback for Tier 1.
- Playwright MCP — fallback for Tier 2b.
- `camofox-browser` / `stealth-browser-mcp` — fallback for Tier 2.

Record the backup used in `sites.yaml` so future runs start at the right rung.

## Extracting the body

Scrapling returns an `Adaptor`. Prefer in this order:
1. `page.css_first("article").markdown` (or `<main>`, or site-specific selector from `sites.yaml`).
2. If that's empty or too short, try the whole document: `page.markdown`.
3. Strip nav/footer/aside via `page.css("nav, footer, aside, script, style").remove()` before reading markdown.

If the domain has a `selectors` entry in `sites.yaml`, use it with `auto_match=True` so it heals across DOM changes.

## Strategy cache — sites.yaml

1. Parse URL → domain.
2. Look up domain in `<capture-root>/sites.yaml`, then `~/local-web-capture/sites.yaml`. Use recorded `strategy` (`static` | `stealth` | `playwright` | `auth`) as starting rung.
3. After a successful scrape, if the domain is new or the rung differs, propose updating the global `sites.yaml`.

## Output

Filename: `YYYY-MM-DD--HHMM--<slug>--<shorthash>.md`.

```markdown
---
url: <original url>
domain: <domain>
title: <title>
author: <author or null>
published_at: <ISO date or null>
captured_at: <ISO now, Israel timezone>
language: <detected ISO 639-1>
extractor: scrapling-static | scrapling-stealth | scrapling-playwright | webclaw | playwright-mcp
rung: 1 | 2 | 2b | 3
word_count: <int>
---

# <title>

<markdown body>
```

Slug = first 6 kebab-cased words of title, ASCII-only. Shorthash = first 6 chars of SHA1 of URL.

## After saving

- Report file path, rung used, and word count.
- If extraction was thin, say so and recommend the next rung — do not silently save junk.
- Offer to update `sites.yaml` if the rung differs from the cached entry.

## Do not

- Do not follow pagination or fetch related links unless asked.
- Do not save images/media — text only.
- Do not overwrite an existing capture with the same shorthash; append `-v2`.
- Do not fall back to a hosted reader to "fix" a failure — that defeats the point.
