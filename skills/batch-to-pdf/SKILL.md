---
name: batch-to-pdf
description: Compile a batch of captured articles into a single PDF via Typst. Each article gets a header block showing the source URL and capture date, a page-numbered footer runs throughout, and a cover + table of contents open the document. Use when the user wants a printable/shareable compendium of a scrape batch, says "make a PDF of these captures", "compile the batch to PDF", or "print the batch report".
---

# batch-to-pdf

Produce a single typeset PDF from a Local-Web-Capture batch directory.

## Inputs

Either:
- An existing **batch id** (produced by `batch-capture`) — resolve to `<capture-root>/batches/<batch-id>/`.
- A **list of URLs** — in which case run `batch-capture` first (without `--pdf`), then compile its output.

If the user hands over a plain directory that looks like a batch folder (has `report.agent.json` + `articles/`), accept it directly.

## Preconditions

- `typst` must be on PATH. If missing, install via `cargo install typst-cli` or `brew install typst`. Do not silently skip.
- `<batch-dir>/report.agent.json` must exist — this is the structured manifest the template reads. If only a markdown report exists, regenerate the agent JSON first (re-run `batch-capture` in report-only mode).

## Template

Bundled at `assets/typst/batch-report.typ` in this plugin. The template expects three `--input` values:

- `manifest` — absolute path to `report.agent.json`.
- `capture_root` — absolute path to the batch directory (so article file refs resolve).
- `title` — optional document title, default `"Batch Capture Report"`.

## What the PDF contains

1. **Cover page** — title, batch id, generation timestamp, capture count summary.
2. **Table of contents** — one line per article: `[##NN] Title — domain`.
3. **One section per article.** Each section starts on a new page with:
   - `[##NN] Title` heading.
   - A shaded metadata block showing:
     - **Source URL** (clickable link)
     - **Captured** (ISO timestamp)
     - **Domain**
     - **Language · Word count · Extractor (rung)**
   - Body text, YAML frontmatter stripped, paragraph breaks preserved, `#`/`##` rendered as bolded lines.
4. **Footer on every page** — centered, small, light grey: `Page N of M`.

## Command

Locate the bundled template (`${CLAUDE_PLUGIN_ROOT}/assets/typst/batch-report.typ` or the equivalent resolved plugin path) and run:

```bash
typst compile \
  --root / \
  --input manifest="<batch-dir>/report.agent.json" \
  --input capture_root="<batch-dir>" \
  --input title="<user-supplied or derived>" \
  "<template-path>" \
  "<batch-dir>/report.pdf"
```

Use `--root /` because article files are read via absolute paths in the manifest.

## Options

- `--title "<str>"` — override the cover title.
- `--out <path>` — write the PDF somewhere other than `<batch-dir>/report.pdf`.
- `--open` — open the resulting PDF with the user's default viewer (`xdg-open` on Linux) after compile.

## Flow

1. Resolve batch directory (from id, URL list, or explicit path).
2. Verify `report.agent.json` is present and well-formed (parse-check; fail early if not).
3. Verify `typst` is on PATH; otherwise tell the user how to install.
4. Run `typst compile` with the inputs above.
5. If compile fails, surface the stderr (Typst errors are usually about a missing article file or a JSON field mismatch — both fixable).
6. On success, report the output path and its file size. Offer `--open` if the user might want it immediately.

## Do not

- Do not edit or rewrite captured article bodies to "clean them up" for the PDF. Render what's on disk.
- Do not embed remote images or fonts — everything must render from the user's machine.
- Do not regenerate the batch just to change the PDF title; use `--title`.
- Do not fall back to wkhtmltopdf or pandoc if Typst is missing; ask the user to install Typst.
