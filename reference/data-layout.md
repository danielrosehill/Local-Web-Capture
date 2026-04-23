# Data layout

Root: `~/local-web-capture/`

```
~/local-web-capture/
├── articles/          # scraped articles (one file per capture)
│   └── YYYY/MM/       # date-bucketed
├── prices/            # price snapshots
│   └── <domain>/      # per-site history
├── translations/      # capture + translate outputs
│   └── YYYY/MM/
├── .cache/            # extractor cache, not for user consumption
└── sites.yaml         # per-domain scraping recipes (selectors, strategy)
```

## File naming

- Articles: `YYYY-MM-DD--<slug>--<shorthash>.md` — markdown body with YAML frontmatter.
- Prices: `<domain>/YYYY-MM-DD--<product-slug>.json` — structured price record.
- Translations: `YYYY-MM-DD--<slug>--<src>-<tgt>.md` — two-column or stacked format.

## Frontmatter schema (articles & translations)

```yaml
url: https://...
domain: example.co.il
title: ...
author: ...
published_at: 2026-04-23           # ISO, best-effort
captured_at: 2026-04-23T14:32:05+03:00
language: he                        # ISO 639-1
extractor: crawl4ai | playwright | curl+readability
word_count: 1234
translated:                         # only present in translations/
  target_language: en
  translator: claude
  translated_at: ...
```

## sites.yaml

Per-domain registry. Lets skills look up the right strategy without rediscovery.

```yaml
ynet.co.il:
  strategy: crawl4ai            # crawl4ai | playwright | curl
  article_selector: "div.article-body"
  language: he

shufersal.co.il:
  strategy: playwright          # JS-heavy
  price_selectors:
    product_name: "h1.product-title"
    price: "span.price"
    unit_price: "span.unit-price"
  language: he
```
