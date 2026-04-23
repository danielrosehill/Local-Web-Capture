---
name: batch-capture
description: Capture a list of URLs in one job. Saves each article individually with a timestamp, then produces a summary report across the batch (markdown always; PDF optional via Typst). Supports two report modes: human-summary (readable prose + per-item cards) and agent-summary (JSON optimised for LLM consumption). Use when the user supplies multiple URLs — pasted, in a file, or from clipboard — and wants both the individual captures and a synthesised overview.
---

# batch-capture

One command, many URLs, individual captures + a batch-level report.

## Inputs

Accept any of:
- A list of URLs pasted in the message.
- A path to a text file with one URL per line (`--urls-file <path>`).
- A markdown file containing links — extract them.

Ignore blanks and comments (lines starting with `#`).

Deduplicate by normalised URL (strip utm_*, fbclid, gclid params).

## Batch identity & location

1. Resolve the capture root via `reference/save-location.md` (project-local preferred; global fallback).
2. Generate a batch id: `YYYY-MM-DD-HHMM--<6char-hash>` where the hash is short SHA of the joined URL list.
3. Create `<root>/batches/<batch-id>/` with subdirs `articles/`.

## Per-URL capture

For each URL:
1. Run the standard escalation ladder (`scrape-article` semantics — Rung 1 webclaw → … → Rung 4 bb-browser only if flagged as auth-required).
2. Save the individual capture as `<root>/batches/<batch-id>/articles/NN--<slug>--<shorthash>.md` where `NN` is zero-padded sequence (preserves input order in listings). Include standard frontmatter.
3. Track outcome in an in-memory manifest: url, final_url, title, extractor/rung, word_count, language, status (`ok` / `thin` / `failed`), error message if any, capture file path, captured_at ISO timestamp.

Keep going on individual failures — the report captures the gaps. Stop only if a systemic issue emerges (e.g. all Rung-1 calls fail — suggests a webclaw problem, surface it and ask).

## Reports

Always write **both** reports to the batch directory:

### report.md (human-summary)

```markdown
# Batch capture — <batch-id>

**Run:** <ISO timestamp, Israel TZ>
**URLs submitted:** N
**Captured successfully:** M
**Failed / thin:** N-M
**Languages:** he (12), en (3), …

## Summary

<2–4 paragraph synthesis across the captured articles: dominant themes, noteworthy outliers, timeline if dates cluster, contradictions or convergences between sources. Write this as useful prose — not a bullet-dump. Cite items as [#01], [#02] so the reader can jump to the card below.>

## Items

### [#01] <title>
- Source: <domain> · <published_at if known>
- Language: <he/en/...>
- Words: <n>  ·  Rung: <1-4>
- URL: <original>
- File: articles/01--<slug>--<hash>.md

<3–5 sentence summary of this article specifically. If translated, summarise in English regardless of source language.>

### [#02] …

## Failures

| # | URL | Reason |
|---|-----|--------|
| … | … | … |
```

### report.agent.json (agent-summary)

Optimised for agent consumption — strict schema, no prose decoration:

```json
{
  "batch_id": "2026-04-23-1530--a1b2c3",
  "generated_at": "2026-04-23T15:35:12+03:00",
  "capture_root": "<absolute path>",
  "counts": {"submitted": 15, "captured": 13, "failed": 2, "thin": 0},
  "themes": ["…", "…"],
  "items": [
    {
      "n": 1,
      "url": "…",
      "final_url": "…",
      "domain": "ynet.co.il",
      "title": "…",
      "language": "he",
      "word_count": 812,
      "extractor": "webclaw",
      "rung": 1,
      "captured_at": "…",
      "file": "articles/01--…--abc123.md",
      "summary": "2–4 sentence factual summary in English.",
      "key_claims": ["…", "…"],
      "entities": {"people": ["…"], "orgs": ["…"], "places": ["…"]},
      "dates_mentioned": ["2026-04-22"]
    }
  ],
  "failures": [{"n": 14, "url": "…", "reason": "timeout at rung 2"}]
}
```

Keep `summary` + `key_claims` tight and factual — this file is consumed by other agents, not humans.

### report.pdf (optional)

If the user asks for a PDF or passes `--pdf`, use the `typst-document-generator` plugin (or plain Typst) to render `report.md` via a simple template. Save to `<batch-id>/report.pdf`. Do not block the skill on PDF generation — produce the markdown first, then the PDF as a bonus step.

## Flags

- `--urls-file <path>` — read URLs from file.
- `--pdf` — also render the human report as PDF.
- `--agent-only` — skip the human report; just write `report.agent.json`.
- `--human-only` — skip the agent JSON.
- `--out <path>` — override save root (see save-location reference).
- `--translate <target-lang>` — run `capture-translate` semantics per item and report in the target language.
- `--concurrency <N>` — default 3. Do not hammer a single domain.

## Do not

- Do not follow pagination or site-internal links from captured articles.
- Do not silently skip failed URLs — every input URL appears somewhere in the report (captured, thin, or failed).
- Do not write a report that synthesises articles you failed to capture.
- Do not send any content to hosted services to generate summaries. Use Claude inline; the whole plugin is localhost-only.
