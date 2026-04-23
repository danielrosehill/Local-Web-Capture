---
name: scrape-web-page
description: General-purpose web page scraper via the user's localhost (preserves Israeli IP for geo-restricted sites). Handles any page that is NOT a clean article — SPAs, branch locators, product catalogs, search result pages, government portals, dashboards, API endpoints discovered via devtools, or anything requiring raw HTML, rendered DOM, network/XHR responses, or structured extraction. Supports scripted user interaction (click "load more", scroll, type into search, iterate a city dropdown) for sites that hide data behind UI actions — a naive "scrape this URL" will return nothing on those. Canonical user invocation provides a triple: (URL, interactive target to click/type/scroll, data to extract) — the skill loads the URL, activates the target in a loop until it stops producing new content, then extracts the requested data. Trigger phrases: "scrape this page", "dump the HTML", "find the API behind this page", "capture this SPA", "get all the X from this page", "extract the JSON", "scrape branch list / store list / catalog", "load URL, click this, then extract that", "I had to click to load everything", any non-article URL. For clean article extraction use `scrape-article` instead.
---

# scrape-web-page

Flexible scraper for arbitrary web pages. Unlike `scrape-article`, does not assume a readability-friendly article body exists. Supports four output modes: raw HTML, rendered DOM HTML, extracted structured data (JSON/CSV), and network-response capture (finding the backing API of an SPA).

## Hard constraint

Requests must originate from this machine. Do **not** route through a hosted reader (Jina, Firecrawl SaaS, ScrapingBee, etc.). The whole reason this plugin exists is to use the user's Israeli IP.

## Pick a mode before you start

Ask (or infer from the goal):

- **`raw`** — plain HTML as served. Use for server-rendered sites, or to inspect the initial payload of an SPA before JS runs.
- **`rendered`** — HTML after JS execution. Use for SPAs where content is injected client-side on load with no user interaction required.
- **`interactive`** — rendered + scripted user interactions (click "load more" buttons, scroll, type into a search box, select a dropdown, paginate). **Many SPAs hide data behind a "load all" or per-city filter** — e.g. the Israel Post branch locator requires clicking through cities or a "show all branches" button before the full list appears. A naive one-shot scrape of the landing URL will return an empty or partial dataset. If the user says anything like "I had to click to load all the branches", the mode is `interactive`.
- **`extract`** — structured data pulled from the DOM or embedded JSON blobs. User specifies what to extract (e.g. "all branch ids and names", "product name + price", "table rows"). Often pairs with `interactive` or `network`.
- **`network`** — capture XHR / fetch responses while loading (and optionally interacting with) the page. Use when the goal is to discover the backing API of an SPA — this is what you want for branch locators, store finders, autocomplete endpoints. Often the right first move for SPAs: catch the API once, then skip the browser on future runs.

Decision order for an unknown SPA:

1. Try `network` first — if the page fires a clean JSON endpoint, use that directly from here on.
2. If the endpoint requires interaction to fire (e.g. only triggers on city search), fall through to `interactive` + `network` combined: script the interactions while capturing responses.
3. Only resort to DOM scraping (`extract` off a `rendered` / `interactive` capture) if no JSON endpoint is exposed.

Do not default to `rendered` — it is the slowest. Start at `raw` unless the user's goal obviously needs JS.

## `interactive` mode — scripted user actions

Use when the data only appears after the user does something.

### Preferred invocation: user supplies the triple

The cleanest way to drive this mode is for the user to provide three things:

1. **URL** — the page to load.
2. **Interactive target** — the thing to click / type / scroll to reveal the data. A CSS selector is ideal; plain text ("the button labelled 'טען עוד'", "the city dropdown", "scroll to bottom") is fine — resolve it to a selector on the loaded page.
3. **Data to extract** — what the user actually wants out ("all branch ids and their Hebrew names", "every row in the results table", "the price and product name of each card").

Given that triple, the recipe is fixed:

```
load URL
→ repeat: activate the interactive target, wait for new content
  (stop when the target disappears, is disabled, or row count stops growing)
→ once settled, extract the requested data from the final DOM
→ save as JSON (with a sidecar raw HTML dump in case extraction needs tweaking)
```

Resolve the target by kind:

- **Button / link** (pagination, "load more", "show all"): click in a loop until it's gone / disabled / row count plateaus.
- **Dropdown / select**: enumerate `<option>` values, load each, concatenate+dedupe results.
- **Search box**: `page.type(sel, query, delay=120)`, wait for suggestions, click the match.
- **Scroll**: repeated `page.mouse.wheel` until `document.body.scrollHeight` stops growing.

Always pair with `network` capture so you keep raw JSON payloads even if the DOM extraction is brittle.

Echo back what you resolved before running: "Loading X, will click selector `Y` until it stops producing new rows, then extract `Z`." One-line confirmation, then proceed under auto mode.

### Typical recipes

### Click-through "load more" / pagination

```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_context(locale="he-IL").new_page()
    page.goto(url, wait_until="networkidle")

    # Click "load more" until it disappears or stops adding rows
    while True:
        btn = page.query_selector("button:has-text('טען עוד')")  # or data-testid, etc.
        if not btn or not btn.is_visible():
            break
        before = page.eval_on_selector_all("ul.branches li", "els => els.length")
        btn.click()
        page.wait_for_timeout(800)
        after = page.eval_on_selector_all("ul.branches li", "els => els.length")
        if after == before:
            break

    html = page.content()
    browser.close()
```

### Iterate a dropdown / city list

If the page filters by city and there's no "all" option, enumerate the city `<option>` values and load each in turn, concatenating results. Deduplicate by the id field the API returns.

### Autocomplete / physical typing

Some sites only fire the search on per-character input (e.g. Maccabi medicines). Use `page.type(selector, query, delay=120)` rather than `fill`, then wait for the suggestion dropdown.

### Scroll-triggered lazy load

```python
prev_height = 0
while True:
    page.mouse.wheel(0, 4000)
    page.wait_for_timeout(600)
    h = page.evaluate("document.body.scrollHeight")
    if h == prev_height:
        break
    prev_height = h
```

### Always pair with `network` capture

Run the interaction script with the response listener from `network` mode attached. That way even if the DOM scrape is brittle, you have the raw JSON payloads saved.

### When to stop automating and ask

If the interaction required is ambiguous ("click through all the cities" — are there 50 or 500? captcha? rate-limit?), do **one** city end-to-end first, show the user the result, confirm before looping. Auto mode does not license a 10-minute headless browser run without checkpointing.

## Escalation ladder

Same rungs as `scrape-article`. Consult `sites.yaml` first.

### Rung 1 — Scrapling `Fetcher` (raw)

```python
from scrapling.fetchers import Fetcher
page = Fetcher.get(url, stealthy_headers=True, follow_redirects=True, timeout=20)
# page.status, page.html_content
```

### Rung 2 — Scrapling `StealthyFetcher` (Camoufox, rendered + anti-bot)

```python
from scrapling.fetchers import StealthyFetcher
page = StealthyFetcher.fetch(url, headless=True, network_idle=True, humanize=True)
```

### Rung 2b — Scrapling `PlayWrightFetcher` (rendered, no stealth)

```python
from scrapling.fetchers import PlayWrightFetcher
page = PlayWrightFetcher.fetch(url, headless=True, network_idle=True)
```

### Rung 3 — authenticated

Defer to `scrape-authenticated`.

## `network` mode — capturing API calls

For SPAs the fastest win is usually to identify the JSON endpoint powering the UI and call it directly. Two approaches:

### A. Passive capture via Playwright

```python
from playwright.sync_api import sync_playwright
import json, pathlib

responses = []
with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    ctx = browser.new_context(locale="he-IL")
    page = ctx.new_page()

    def on_response(resp):
        ct = resp.headers.get("content-type", "")
        if "json" in ct or resp.url.endswith(".json"):
            try:
                responses.append({"url": resp.url, "status": resp.status, "body": resp.json()})
            except Exception:
                pass

    page.on("response", on_response)
    page.goto(url, wait_until="networkidle")
    # Optionally interact: page.fill("input#city", "ירושלים"); page.wait_for_timeout(2000)
    browser.close()

pathlib.Path(out_path).write_text(json.dumps(responses, ensure_ascii=False, indent=2))
```

After capture, report the distinct endpoint hosts + paths so the user can decide which to call directly next time.

### B. Direct API call once endpoint is known

`curl` or `Fetcher.get`, with headers copied from devtools. Record the endpoint under the domain's entry in `sites.yaml` as `api_endpoints:`.

## `extract` mode — structured data out of the DOM

Prefer, in order:

1. **Embedded JSON** — look for `<script type="application/ld+json">`, `<script id="__NEXT_DATA__">`, `window.__INITIAL_STATE__ = ...`. Parse that directly; it's the cleanest source.
2. **Backing API** (network mode, above) — if the DOM is a rendering of a JSON blob, fetch the JSON.
3. **CSS selectors** — `page.css("selector").attrib["data-id"]` + `.text` for each row. Preserve Hebrew verbatim.

Do not scrape heuristically if a JSON source exists on the page.

## CLI fallbacks

- `curl -sL -A "Mozilla/5.0" "<url>"` — sanity check for raw mode when Scrapling acts up.
- `wget -qO- "<url>"` — same.
- `jq` — for slicing captured JSON.
- Playwright MCP — fallback for rendered / network modes when Scrapling's Playwright integration misbehaves.

## Output

Save under the resolved capture root (per `reference/save-location.md`), subdirectory `pages/YYYY/MM/`.

Filename: `YYYY-MM-DD--HHMM--<domain>--<slug>--<shorthash>.<ext>`

Extensions:

- `.html` for `raw` / `rendered`
- `.json` for `network` / `extract`
- `.md` only if the user explicitly wants a markdown rendering

Write a sidecar `.meta.json` next to every capture:

```json
{
  "url": "...",
  "domain": "...",
  "captured_at": "<ISO now, Israel time>",
  "mode": "raw|rendered|extract|network",
  "extractor": "scrapling-static|scrapling-stealth|scrapling-playwright|playwright-direct|curl",
  "rung": 1,
  "status": 200,
  "notes": "optional — flags like 'captcha hit', 'login wall', 'found API at /api/branches'"
}
```

## Strategy cache — sites.yaml

Same file as `scrape-article`. Record per domain:

```yaml
doar.israelpost.co.il:
  strategy: playwright     # SPA
  notes: "Branch locator; backing API at /api/..."
  api_endpoints:
    - https://.../api/branches
```

## After saving

- Report: file path, mode, rung, status code, byte / row count.
- For `network` mode: list distinct JSON endpoints hit, one per line.
- For `extract` mode: show a 3-row preview of the extracted data.
- If the capture looks empty/thin, say so and recommend the next rung or mode.

## Do not

- Do not fall back to hosted readers.
- Do not silently downgrade a `network` capture to an HTML dump — if no JSON was seen, say so.
- Do not invent API endpoints. Report only what the browser actually requested.
- Do not scrape images/media unless explicitly asked.
