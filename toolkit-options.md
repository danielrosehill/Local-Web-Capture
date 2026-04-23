# Toolkit

Hard constraint: every tool runs locally so requests exit the user's IP.

## Primary (default ladder)

| Tier | Tool | Use when |
|------|------|----------|
| 1 | **Scrapling** `Fetcher` | Default. Static HTML, no browser. |
| 2 | **Scrapling** `StealthyFetcher` (Camoufox) | Tier 1 blocked by bot detection / Cloudflare. |
| 2b | **Scrapling** `PlayWrightFetcher` | Needs JS render, stealth not required. |
| 3 | **bb-browser** | Paywalled / logged-in / session-bound. Real Chrome. |

## Backups (kept installed, not default)

- `webclaw` — Rust CLI, alt Tier 1.
- `lightpanda` — lightweight headless engine.
- `camofox-browser` / `stealth-browser-mcp` — alt Tier 2.
- Playwright MCP — alt Tier 2b.

## Disqualified

Any hosted/cloud service (Browserbase, Jina SaaS, Firecrawl SaaS, HyperBrowser, etc.).

## Not adopted

- `apify/crawlee-python` — crawling framework, overkill for single-URL captures.
- `lorien/awesome-web-scraping` — link list, not a tool.
