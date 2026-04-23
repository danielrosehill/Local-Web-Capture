---
name: capture-translate
description: Capture an article from a URL (via the normal localhost scrape path) and save a translated version alongside the original. Default language pair is Hebrew → English; supports arbitrary source → target. Saves to ~/local-web-capture/translations/. Use when the user shares a Hebrew article URL and wants the English version, says "capture and translate", or passes a URL in a language they want rendered into another.
---

# capture-translate

Scrape an article from localhost, then produce a translation alongside the original capture.

## Flow

1. **Scrape first.** Invoke `scrape-article` (or `scrape-authenticated` if the user indicates the page is behind auth). Use the saved markdown + frontmatter as the source — do **not** re-fetch just to translate.
2. **Detect or confirm source language.** Default assumption: source is Hebrew. If frontmatter `language` disagrees or the user specified otherwise, use that.
3. **Pick target language.** Default target is English (`en`). User can override (`--to es`, "translate to French", etc.).
4. **Translate.**
5. **Save translation** to `<capture-root>/translations/YYYY/MM/YYYY-MM-DD--HHMM--<slug>--<src>-<tgt>.md`. Resolve `<capture-root>` per `reference/save-location.md` (project-local preferred; global fallback).

## Translator choice

**Default: Claude (inline).** For the user's typical volume (one article at a time), Claude translating directly in-conversation gives the best quality with zero extra deps. This is the right choice for most calls.

**Optional: LibreTranslate (local server).** For bulk or scripted runs, a locally-running LibreTranslate instance is a good fit — keeps the request local and avoids sending content to external APIs. Install notes:
```bash
pip install libretranslate
libretranslate --host 127.0.0.1 --port 5000 --load-only en,he,ar,es,fr,de,ru
```
Call:
```bash
curl -s -X POST http://127.0.0.1:5000/translate \
  -H 'Content-Type: application/json' \
  -d '{"q":"<text>","source":"he","target":"en","format":"text"}'
```

Pick LibreTranslate over Claude only when:
- The user is running this in a loop/batch.
- The user explicitly asks for it.
- The article exceeds a length where inline translation becomes unwieldy.

Otherwise use Claude.

## Output format

Stacked (block-per-section), not side-by-side, for readability in plain markdown viewers:

```markdown
---
source_url: <url>
source_capture: <path to the original article file>
source_language: he
target_language: en
translator: claude | libretranslate
translated_at: <ISO now>
title_source: <original title>
title_target: <translated title>
---

# <translated title>

> Source: <url>
> Original title: <original title>

<translated body as markdown, same structure as source>

---

## Original (Hebrew)

<original body>
```

## Preserve structure

- Keep heading levels, list/quote structure, paragraph breaks.
- Do not translate code blocks, URLs, email addresses, or numbers.
- Preserve Hebrew proper nouns in parenthetical transliteration only when disambiguation helps (people, place names the English reader won't know).

## After saving

Report: path, translator used, source/target languages, word counts for both versions.

## Do not

- Do not translate without first capturing the original — we always want both.
- Do not send article text to hosted translation APIs (Google/DeepL) from this skill. The user's localhost-only posture is deliberate.
- Do not paraphrase or editorialize — translate faithfully.
