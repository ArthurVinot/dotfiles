---
name: fill-mr-description
description: >-
  Fill `.gitlab/merge_request_templates/review.md` with a concise MR
  description distilled from the last commit.
  Use when the user says: fill the MR, fill the template, write the MR,
  prepare merge request, write merge request description.
---

# Fill MR Description

**Fill** is the root act: overwrite `.gitlab/merge_request_templates/review.md` with a concise MR description derived from the last commit.

## Steps

### 1. Read the template

Read `.gitlab/merge_request_templates/review.md` at the project root.

**Criterion**: the template's checklist structure and section headings are in your context.

### 2. Read the last commit

Read `git log -1` and `git show --stat HEAD`. Collect:

- **Ticket**: the `XCP-\d+` token in the commit message (or branch name)
- **Part**: if the message or branch implies sequenced delivery, append `Part N` to the title
- **Scope**: the kebab-case path(s) under `services/` that were changed
- **Nature**: feat/fix/refactor/chore
- **Test path**: the `tests/` path mirroring the changed code

**Criterion**: you have the ticket, changed paths, and nature of change.

### 3. Apply every rule in the format reference

Rewrite the file applying every rule in [Format reference](#format-reference) below. Rules are ordered; apply them in that order.

**Criterion**: every rule is applied and no placeholder remains.

## Format reference

### Title

Replace `#add_jira_ticket_number` with the ticket number. Keep the `Closes` prefix. Keep the `# Merge request Template` heading. Keep the HTML comment verbatim.

### Checklist

- Pre-check `[x]` every item satisfied by the current branch state.
- Leave `[ ]` for items not yet done.
- **Remove** items that categorically never apply to this kind of change (e.g. "Create a screenshot" for a non-UI refactor; "Communication needed" for a trivial change; cherry picks if none).

### Section filtering

Remove every conditional section whose folder path is not among the changed paths — heading **and** all its nested items. Within a kept section, remove sub-sections whose scope doesn't match the changed files. Keep only:

- The `## Checklist before validating Merge Request` section.
- The section(s) matching changed folders (with only applicable sub-sections).
- The `### Final` section.

### Final section

Keep the `Remove the Draft prefix` line and the `Set Jira ticket Status to *Code review*` line. Remove the entire communication message block.

### Summary

Keep the `Servers used:` line filled with the actual server or environment used. Remove `Post Screenshot:` line. Remove the `<img>` element entirely. Remove the `Channel or recipient:` line. Then add the `How to test` section below.

### How to test

After the `Summary`, add a `### How to test` section with concrete, copy-pasteable steps to exercise the change locally and observe the result.

This is a **fallback**: some kept sections already carry testing instructions for specific parts of the monorepo (e.g. the `data-pipeline` cURL examples, the `databases` migration logs). When a kept section already covers how to test the change, fill that in-place and do **not** add a separate `How to test` section. Add `How to test` only for changes not covered by such a section.

When you do add it:

- Derive the steps from the changed files, not a template. Tie each step to a named artifact from the diff (alert name, endpoint, migration, script).
- Cover every distinct behavior the diff introduces (e.g. one block per alert severity, one cURL per endpoint).
- State the expected observable outcome for each step (what fires, what returns, where to look) and any wait or `for:` duration.
- End with a cleanup block that reverts any injected test state.
- If the change is genuinely not locally testable, write one line saying why instead of omitting the section.

### Review template

Strip the entire `<!-- Review template ... -->` comment block and everything inside it. No traces remain.

## Completion criterion

Every rule in [Format reference](#format-reference) has been applied. No placeholders, no reviewer template, no screenshot element, no comms section remain, and testing instructions are present — either filled into a kept section that already provides them, or as a dedicated `How to test` section otherwise.
