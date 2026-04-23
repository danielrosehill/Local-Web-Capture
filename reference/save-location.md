# Save location resolution

Every capture skill (`scrape-article`, `scrape-price`, `scrape-authenticated`, `capture-translate`, `batch-capture`) uses the same resolution to decide where to save.

## Resolution order

1. **Explicit override** — if the user passes `--out <path>` or an env var `LOCAL_WEB_CAPTURE_ROOT=<path>`, use that. Absolute wins.
2. **Project-local mode** — if the current working directory is inside a git repository (`git rev-parse --show-toplevel` succeeds), save to `<repo_root>/captures/`. This is the default when Claude Code is invoked inside a working repo.
3. **Global fallback** — otherwise save to `~/local-web-capture/`.

Rationale: captures are often research artefacts that belong with the repo they're informing (a news roundup, a price snapshot supporting a decision doc, source material for a blog post). Keeping them in-tree makes them commit-along-with-the-analysis by default. For ad-hoc captures made from `~`, the global dir catches them.

## Subtree layout (same in both modes)

```
<root>/
├── articles/YYYY/MM/*.md
├── prices/<domain>/*.json
├── translations/YYYY/MM/*.md
├── batches/<batch-id>/       # created by batch-capture
│   ├── articles/
│   ├── report.md
│   ├── report.pdf            # optional
│   └── report.agent.json     # agent-summary
├── sites.yaml                 # per-domain strategy cache (lookup: project first, then global)
└── .cache/
```

## sites.yaml lookup order

Project-local captures still benefit from the global strategy cache. Lookup order when resolving a domain's scrape rung:

1. `<project>/captures/sites.yaml` (project-specific overrides — rare, e.g. "this client's staging site needs stealth").
2. `~/local-web-capture/sites.yaml` (global, the usual source).

Writes default to the global file unless the user explicitly scopes an entry to the project.

## Notes

- Never write captures under `.git/` or inside lockfiles.
- If saving into a repo that has `.gitignore` rules ignoring `captures/`, honour them silently — do not fight the user's intent.
- When running project-local, print the resolved path on first save so the user sees where things are going.
