---
name: scrape-authenticated
description: Tier-3 escalation — capture an article or page from a paywalled, logged-in, or aggressively-gated site by driving the user's real Chrome via bb-browser (login state + cookies + user's IP). Use ONLY when scrape-article reports that headless rungs failed because of auth/paywall (e.g. Haaretz, Calcalist+, subscriber-only Israeli content). Do not use for ordinary scrapes — the headless path is cheaper.
---

# scrape-authenticated

Last-resort capture path. Drives the user's real Chrome, so requests carry the user's cookies, login state, and Israeli IP.

## When to use

Only when one of the following is true:
- `scrape-article` reported that headless rungs 1–3 hit a paywall/login wall.
- `sites.yaml` marks the domain as `strategy: authenticated` (known paywalled site).
- User explicitly asks to capture from a logged-in session.

Otherwise **reject** and redirect to `scrape-article`. A GUI browser run is heavier, slower, and reveals the user's identity to the site.

## Tooling

**bb-browser** (`epiral/bb-browser`) — CLI + MCP that drives the user's logged-in Chrome.

If bb-browser isn't installed, tell the user and recommend `capture-setup` rather than silently falling back.

## Flow

1. Confirm the user is already logged in to the target site in Chrome. If not, ask them to sign in first; don't attempt auth flows from this skill.
2. Drive bb-browser to navigate to the URL, wait for the article container to render, then extract visible text.
3. Convert to markdown (same frontmatter/layout as `scrape-article`, with `extractor: bb-browser` and `rung: 4`).
4. Save to `~/local-web-capture/articles/YYYY/MM/` using the same filename convention.

## Output

Same schema as `scrape-article`. Add to frontmatter:
```yaml
extractor: bb-browser
rung: 4
authenticated: true
```

## Do not

- Do not attempt to solve captchas or defeat protections. If the page challenges, stop and tell the user.
- Do not store cookies, credentials, or the page's Set-Cookie headers in the capture file.
- Do not run this for sites that worked on a lower rung — re-read `sites.yaml` first.
