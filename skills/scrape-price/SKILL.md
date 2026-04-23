---
name: scrape-price
description: Capture product name + price (and optional unit price, stock, SKU) from an Israeli e-commerce URL via the user's localhost, saving a structured JSON snapshot under ~/local-web-capture/prices/<domain>/. Use when the user wants to track a price on Yad2, Shufersal, Rami Levy, KSP, Ivory, Zap, or similar, or asks to "grab the price" / "snapshot this listing".
---

# scrape-price

Capture a structured price record for a product URL. One file per capture — history accumulates naturally.

## Hard constraint

Must run from this machine's network. The request must exit via the user's Israeli IP. No hosted scrapers.

## Strategy

1. Parse URL → domain.
2. Look up `sites.yaml`. Most Israeli retail sites need **playwright** (SPA or JS-rendered prices). Default to playwright unless `sites.yaml` says otherwise.
3. Use the `price_selectors` block from `sites.yaml` if present. If the domain is unknown, prompt the user for the selectors once and add them to `sites.yaml` for future runs.

## Playwright capture

Via the installed Playwright MCP:
1. `playwright_navigate(url)`.
2. Wait (1–3s) for the price selector to appear. If it never appears, abort with a clear error — do not save an empty record.
3. Read text content of each configured selector.
4. Also read `document.title` and the final URL (in case of redirects).

## Output

Path: `~/local-web-capture/prices/<domain>/YYYY-MM-DD--<product-slug>.json`

```json
{
  "url": "...",
  "final_url": "...",
  "domain": "shufersal.co.il",
  "product_name": "...",
  "price": {
    "raw": "₪ 12.90",
    "amount": 12.90,
    "currency": "ILS"
  },
  "unit_price": {"raw": "...", "amount": null, "unit": null},
  "in_stock": true,
  "sku": null,
  "captured_at": "2026-04-23T14:32:05+03:00",
  "extractor": "playwright",
  "selectors_used": { "product_name": "...", "price": "..." }
}
```

Parse `amount` by stripping currency symbols and thousands separators (Israeli sites use both `,` and `.` — detect the decimal carefully).

## After saving

- Report the file path, product name, and parsed price.
- If a prior snapshot for the same product exists, note the delta vs the most recent one.
- If the selectors returned empty, say so and ask the user to re-check selectors rather than saving nulls.

## Do not

- Do not "click to reveal price" or interact beyond navigation + waits, unless the user explicitly allows it.
- Do not save partial records silently.
