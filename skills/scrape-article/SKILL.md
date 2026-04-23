---
name: scrape-article
description: Scrape an article from a URL via the user's localhost (preserves Israeli IP for geo-restricted sites) and save a clean markdown capture to ~/local-web-capture/articles/. Use when the user gives a URL and wants the article body saved, or says "capture this article", "scrape this", or references Israeli news sites (ynet, haaretz, n12, calcalist, timesofisrael, etc.) they want archived.
---

# scrape-article

Capture a single article and save it as markdown with frontmatter to `~/local-web-capture/articles/YYYY/MM/`.

## Hard constraint

Requests must originate from this machine. Do **not** route through a hosted reader (Jina, Firecrawl SaaS, ScrapingBee, etc.) — the whole point is that the user's Israeli IP is what unlocks the content.

## Escalation ladder — stop at the first method that returns a real body

Cheapest → most expensive. Never skip ahead unless `sites.yaml` says the domain is known-hard (then start at the right rung).

### Rung 1 — webclaw (headless, purpose-built)
Primary path. Lightweight Rust extractor, LLM-optimized output.

```bash
webclaw extract "<url>" --format markdown --output -
```

Check exit code and body length. If body < 200 chars or mostly nav boilerplate → escalate.

### Rung 2 — lightpanda (headless, lighter JS)
For sites that need a tiny bit of JS but not full Chromium.

### Rung 3 — stealth headless
Only if the site blocks normal headless (captcha, 403, cloudflare challenge).
Tools: camofox-browser, stealth-browser-mcp, obscura. Pick based on what's installed.

### Rung 4 — authenticated real browser
**Do not use from this skill.** If the site is paywalled or session-bound, stop and tell the user to run `scrape-authenticated` (Tier-3 skill using bb-browser). Do not silently save a login-wall as if it were the article.

## Strategy cache — sites.yaml

On each run:
1. Parse URL → domain.
2. Look up domain in `<capture-root>/sites.yaml` first (project-local override if present), then `~/local-web-capture/sites.yaml`. Use its recorded `strategy` as the starting rung.
3. After a successful scrape, if the domain is new, propose adding it to the global `sites.yaml`.

## Output

Resolve the save root per `reference/save-location.md`:
- Inside a git repo → `<repo_root>/captures/articles/YYYY/MM/`.
- Otherwise → `~/local-web-capture/articles/YYYY/MM/`.
- `--out <path>` overrides both.

Filename: `YYYY-MM-DD--HHMM--<slug>--<shorthash>.md` (timestamp included so repeated captures of the same URL don't collide).

```markdown
---
url: <original url>
domain: <domain>
title: <title>
author: <author or null>
published_at: <ISO date or null>
captured_at: <ISO now, Israel timezone>
language: <detected ISO 639-1>
extractor: webclaw | lightpanda | playwright | stealth-*
rung: 1 | 2 | 3
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
