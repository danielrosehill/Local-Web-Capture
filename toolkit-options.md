# Toolkit options — evaluation

Candidate open-source tools for the local-web-capture extractor layer.

**Hard constraint:** must run locally so the request exits from the user's IP (Israeli IP is the whole point — geo-restriction bypass). Any tool that is fundamentally a hosted/cloud service is disqualified regardless of star count.

Metadata fetched 2026-04-23 via GitHub API.

---

## Ranked by stars

| # | Repo | Stars | Lang | Last push | Verdict |
|---|------|------:|------|-----------|---------|
| 1 | [vercel-labs/agent-browser](https://github.com/vercel-labs/agent-browser) | 30,312 | Rust | 2026-04-20 | **Shortlist.** Local CLI for agent browser automation. Worth a deeper look. |
| 2 | [lightpanda-io/browser](https://github.com/lightpanda-io/browser) | 29,189 | Zig | 2026-04-23 | **Shortlist (infra).** A new headless browser engine built for AI; fast + low memory. More of a Playwright alternative than an extractor. Promising as the browser layer under other tools. |
| 3 | [browserbase/stagehand](https://github.com/browserbase/stagehand) | 22,296 | TS | 2026-04-23 | **Consider.** SDK works locally on top of Playwright, but it's the flagship of a hosted-browser company — roadmap bias is toward the cloud product. |
| 4 | [Skyvern-AI/skyvern](https://github.com/Skyvern-AI/skyvern) | 21,343 | Python | 2026-04-23 | **Skip for this use case.** Heavy agentic workflow automation (LLM-driven clicking through forms). Overkill for article capture or price snapshots. |
| 5 | [hangwin/mcp-chrome](https://github.com/hangwin/mcp-chrome) | 11,283 | TS | 2026-01-06 | **Top pick.** MCP server as a Chrome extension — drives *your actual browser* with *your cookies/session*. Natively satisfies both geo-restriction (your IP) and paywalls (your login). Only caveat: last push is Jan 2026. |
| 6 | [ntegrals/openbrowser](https://github.com/ntegrals/openbrowser) | 9,395 | TS | 2026-04-02 | **Consider.** Autonomous browser agent toolkit. More agentic than needed. |
| 7 | [n4ze3m/page-assist](https://github.com/n4ze3m/page-assist) | 7,812 | TS | 2026-04-19 | **Skip.** Browser extension for chatting with local LLMs about the current page — not an extractor/scraper. |
| 8 | [steel-dev/steel-browser](https://github.com/steel-dev/steel-browser) | 6,897 | TS | 2026-04-21 | **Consider.** Self-hostable browser API, Docker-friendly. Good if you want a persistent local browser daemon. |
| 9 | [epiral/bb-browser](https://github.com/epiral/bb-browser) | 4,753 | TS | 2026-04-19 | **Top pick.** CLI + MCP that drives your logged-in Chrome. Same category as mcp-chrome but more active and adds a CLI. Ideal fit for Haaretz-style paywalled Israeli sites. |
| 10 | [browserbase/mcp-server-browserbase](https://github.com/browserbase/mcp-server-browserbase) | 3,280 | TS | 2026-03-31 | **Disqualified.** Routes through Browserbase cloud — fails the localhost-IP constraint. |
| 11 | [jo-inc/camofox-browser](https://github.com/jo-inc/camofox-browser) | 2,941 | JS | 2026-04-19 | **Consider (niche).** Anti-detect headless browser; useful if a target site actively blocks bot UAs. |
| 12 | [VibiumDev/vibium](https://github.com/VibiumDev/vibium) | 2,786 | Go | 2026-03-18 | **Consider.** Browser automation for agents + humans; Go binary is easy to deploy. |
| 13 | [h4ckf0r0day/obscura](https://github.com/h4ckf0r0day/obscura) | 1,384 | Rust | 2026-04-13 | **Consider (niche).** Headless browser for scraping; anti-detect focus. |
| 14 | [HyperAgent](https://github.com/hyperbrowserai/HyperAgent) | 1,280 | TS | 2026-02-14 | **Skip.** Stale and tied to HyperBrowser cloud. |
| 15 | [browserwing/browserwing](https://github.com/browserwing/browserwing) | 1,234 | Go | 2026-04-21 | **Consider.** Turns your browser into MCP commands — same family as mcp-chrome. |
| 16 | [AIPexStudio/AIPex](https://github.com/AIPexStudio/AIPex) | 1,152 | TS | 2026-04-13 | **Skip.** Browser assistant UI, not a scraping/extraction tool. |
| 17 | [platonai/Browser4](https://github.com/platonai/Browser4) | 1,037 | Kotlin | 2026-04-23 | **Skip for this stack.** JVM dependency is friction for a Python/Node workflow. |
| 18 | [jae-jae/fetcher-mcp](https://github.com/jae-jae/fetcher-mcp) | 1,029 | TS | 2026-01-14 | **Skip.** MCP wrapping Playwright — you already have Playwright MCP installed, so this is redundant. |
| 19 | [adamlui/ai-web-extensions](https://github.com/adamlui/ai-web-extensions) | 540 | JS | 2026-04-23 | **Skip.** User-facing browser extensions (ChatGPT, Claude in the browser), not extraction. |
| 20 | [0xMassi/webclaw](https://github.com/0xMassi/webclaw) | 535 | Rust | 2026-04-23 | **Shortlist.** "Local-first web content extraction for LLMs" — exactly the stated job. Rust binary, single-file install. Low stars but on-purpose. |
| 21 | [0xSero/parchi](https://github.com/0xSero/parchi) | 517 | TS | 2026-04-12 | **Skip.** Browser-side AI companion, not a backend extractor. |
| 22 | [vibheksoni/stealth-browser-mcp](https://github.com/vibheksoni/stealth-browser-mcp) | 497 | Python | 2026-03-22 | **Consider (niche).** Anti-bot bypass MCP. Keep in reserve for sites that detect automation. |

---

## Recommendation

**Escalation ladder — cheapest method that works wins.** Start headless; only invoke a GUI browser when the task genuinely needs one (auth walls, anti-bot, session-bound content).

### Tier 1 — headless fast path (default)
For server-rendered articles and simple price pages. No browser UI, no cookies needed.
- **0xMassi/webclaw** — Rust binary, "local-first extraction for LLMs". Purpose-built for this exact job. Primary candidate for the fast path.
- **lightpanda-io/browser** — lightweight headless engine (Zig). Useful if webclaw struggles with light JS.
- **Playwright MCP** (already installed) — proven headless fallback when the above come up thin.

### Tier 2 — headless with stealth
Only when Tier 1 gets blocked by bot detection.
- **jo-inc/camofox-browser** — anti-detect headless.
- **vibheksoni/stealth-browser-mcp** — anti-bot bypass as an MCP.
- **h4ckf0r0day/obscura** — Rust headless with anti-detect.

### Tier 3 — real browser (last resort)
Only when the content is session-bound (paywall, logged-in state, hard geo + fingerprint checks). Requests exit via your real Chrome, with your cookies.
- **epiral/bb-browser** — CLI + MCP, most active in this category. Primary candidate.
- **hangwin/mcp-chrome** — alternative; more stars but staler.

### Disqualified
- browserbase/mcp-server-browserbase (hosted)
- HyperAgent (hosted + stale)

---

## Next action

Install **webclaw** and wire it into `scrape-article` as the primary extractor. Keep Playwright MCP as the fallback already in place. Add **bb-browser** as an optional Tier-3 skill (`scrape-authenticated`) for paywalled/logged-in scrapes — not on the default path.
