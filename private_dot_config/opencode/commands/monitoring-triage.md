---
description: Triage #monitoring-alerts and open a reviewed draft MR (arg "dry-run" = no push/MR)
model: claude-code/claude-opus-5-5[1m]#medium
---
Mode: `$ARGUMENTS` (if it contains "dry-run": never push, never create/update MRs, never write state).

This is an unattended, explicitly requested multi-step task: the AGENTS.md "Investigation budget"
does NOT apply. Nobody will answer questions — never stop to ask; carry every step through to the end.
A dry run still creates the worktree, commits locally, and runs the review.
If you cannot justify a fix without data you can't access, propose the most defensible minimal
change anyway (e.g. better alert labels/annotations/runbook, or a rule correction) and say so in the report.

1. **Read alerts.** State file: `~/.local/state/triage/last_ts` (if missing, use now − 24h).
   `slackcli conversations read C0A8SL0DN77 --exclude-replies --json --oldest <last_ts>`.
   Alerts are in `attachments[].fallback/text`. Ignore `[RESOLVED]` ones unless the same alert fires repeatedly.
   Group by alert name; pick the ONE most actionable (repeating / prod / critical).
   If nothing is actionable, write the newest read `ts` to the state file (skip in dry-run), report, and stop.
2. **Dedupe.** `glab mr list --search "<alert name>"` in the target repo; if an open MR exists,
   write the newest read `ts` to the state file (skip in dry-run), report, and stop.
3. **Investigate.** Start in `~/Documents/Gitlab/realtime-helm-package` (alert rules, values, charts).
   If the root cause is in another repo under `~/Documents/Gitlab/`, use that repo instead.
   Never touch the existing working tree: `git fetch` then
   `git worktree add /tmp/triage-<alert> -b fix/<alert-kebab> origin/<default-branch>` and work there.
   **Monitoring data** — verify the cause with real data before fixing. Use ONLY
   `mon-curl <grafana|prometheus|alertmanager|loki> <path> [curl args]` (handles auth; never call rbw yourself,
   never print credentials). Examples:
   - `mon-curl prometheus /api/v1/query -G --data-urlencode 'query=<promql>'` (also `/api/v1/query_range`)
   - `mon-curl alertmanager /api/v2/alerts`
   - `mon-curl loki /loki/api/v1/query_range -G --data-urlencode 'query={namespace="default"} |= "error"' --data-urlencode 'limit=50'`
   - `mon-curl grafana /api/search?query=<dashboard>`
   Use `-G` with `--data-urlencode` for GET queries. If it exits 3 (vault locked), continue without it and say so in the report.
4. **Fix.** Minimal change that addresses the root cause (tuning a threshold only if it's clearly wrong). Commit.
5. **Draft MR** (skip in dry-run): push, then
   `glab mr create --draft --title "fix: <alert>" --description "<alert, cause, fix, slack permalink>"` — NO assignee.
6. **Review.** Call the @mr-reviewer subagent with the MR iid (dry-run: the worktree path + base branch).
   Apply its required changes, commit (push unless dry-run), and re-review. Max 2 rounds.
7. **Hand off** (skip in dry-run): `glab mr update <iid> --assignee @me`, then write the newest processed `ts` to the state file.
8. **Report** in under 10 lines: alert, repo, fix, review outcome, MR link (or worktree path in dry-run).
