---
name: setup-tools
description: First-run / re-check setup for Local-Web-Capture. Verifies the data directory exists, installs the Rung-1 headless extractor (webclaw), sets up the Rung-4 real-browser path (bb-browser), seeds sites.yaml, and flags Playwright MCP for removal once validated. Use when the user wants to initialise the plugin, when a capture skill reports a missing dependency, when onboarding a new machine, or to re-check the install.
---

# setup-tools

One-time (re-runnable) setup for the Local-Web-Capture plugin. Idempotent — safe to run repeatedly.

## Why this plugin exists

All captures run **from the user's localhost** so the HTTP request originates from the user's Israeli IP. This is deliberate — it is the reason we do not use hosted readers like Jina or Firecrawl SaaS for these jobs.

## Steps

1. **Verify data directory.** Check `~/local-web-capture/` exists with subdirs `articles/`, `prices/`, `translations/`, `.cache/`. Create any missing. Confirm `sites.yaml` exists at the root — if missing, copy from the plugin's reference seed.

2. **Install Rung-1 extractor: webclaw.** Primary headless path (Rust binary).
   - Check the repo for install instructions: https://github.com/0xMassi/webclaw
   - Typical: `cargo install webclaw` or a prebuilt release binary to `~/.local/bin/webclaw`.
   - Verify: `webclaw --version`.

3. **Install Rung-3 extractor: bb-browser.** For the authenticated/real-Chrome path.
   - Repo: https://github.com/epiral/bb-browser
   - Install per upstream docs, then register as an MCP server if the plugin's `scrape-authenticated` skill will call it via MCP.
   - Confirm the user is signed in to target paywalled sites (Haaretz, Calcalist+) in their real Chrome profile.

4. **Optional Rung-2 stealth:** install `camofox-browser` or `stealth-browser-mcp` if known-hard sites (bot-blocked) come up.

5. **Optional translator fallback: LibreTranslate.** Only if the user plans bulk translate jobs. Not required for occasional use — Claude handles inline.
   ```bash
   pip install libretranslate
   ```

6. **Playwright MCP transitional note.** The existing user-level Playwright MCP is a usable Rung-2 fallback *during* bring-up. Once webclaw + bb-browser are wired and validated on real captures, **remove Playwright from user-level MCP config** (`~/.claude/settings.json`) so Claude does not bias toward it. Leave it as a project-level MCP if still needed occasionally.

7. **Report status.** Print a one-screen summary: data dir path, webclaw version (or "not installed"), bb-browser status, Playwright MCP present (yes/no — flag for removal once validated), sites.yaml entry count.

## Notes

- Do not run captures from this skill — it only sets up the environment.
- If a dependency install would take >60s, tell the user and proceed; do not wait silently.
- Never write API keys or credentials into the data directory.
