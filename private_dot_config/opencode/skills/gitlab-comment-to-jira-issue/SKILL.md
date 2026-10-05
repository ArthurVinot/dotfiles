---
name: gitlab-comment-to-jira-issue
description: Distill a GitLab MR note into a Jira ticket. Use when the user shares a GitLab note/discussion URL and wants a Jira issue filed, or when an MR discussion is too long to resolve in-thread.
argument-hint: "GitLab note URL (https://gitlab.com/.../merge_requests/N#note_NNN)"
---

# gitlab-comment-to-jira-issue

Distill a noisy MR thread into one focused ticket. Opinionated about
what to keep, what to drop, and which questions to ask before drafting.

The body is short. Every sentence carries a fact no other sentence
carries. Target **≤ 250 words**.

## Defaults (pre-filled, confirmed each run)

| Field    | Default                                                  |
|----------|----------------------------------------------------------|
| Project  | XCP                                                      |
| Type     | Task                                                     |
| Lang     | fr                                                       |
| Assignee | Unassigned                                               |
| Labels   | `RT` + one kind label (`Improvement`, `Bug`, …) — ask which |
| Status   | `Refinement Review` (transition after create)             |

Labels and status are **never** "none" / "default". A fresh ticket
lands in refinement review, not Draft.

## Never put this in the body

Each line below is a mistake made on a real run and corrected by the
user. Do not repeat them.

- **Meta-narration of the ticket's own scope.** No "Périmètre :
  recherche uniquement", no "L'intention d'alerter est déjà actée
  (demande produit relayée par X, portée par Y)". The scope answer
  shapes *what* you write; it is not a paragraph *about* the ticket.
- **Redundancy across sections.** If a metric, file, or artifact is
  named in "Étapes à Suivre", it must not also appear in "Scope &
  Contraintes". One fact, one place.
- **A "Point de départ" grounding paragraph** assembled from repo
  greps. A grep result belongs inline in the step that consumes it.
- **Hardened feasibility.** The thread said *"je ne suis pas
  complètement sûr qu'on puisse le faire"* → write *"on ne sait pas
  **si on saura** distinguer A de B"*, never *"on ne sait pas
  distinguer A de B"*. Asserting impossibility is a different claim
  than reporting uncertainty.
- **Invented implementation hints.** "(état de la skill exposé en
  métrique, route/processor actif, etc.)" — you guessed; it was cut.
- **An invented validation method.** Ask it (step 5c). Do not infer
  "validé sur le serveur X où le fix a été mesuré" from an MR link.
- **Plural follow-up tickets** unless the user said plural. Default
  wording: "fera l'objet d'un ticket à part".
- **Attribution beyond one person.** At most one name, in Contexte, as
  the person who raised the concern. Everyone else's contribution is
  reported as substance, not as "X a dit que".
- **Hard-wrapped lines.** Write one physical line per paragraph.
  jira-cli turns every newline into a separate ADF paragraph.

## Steps

### 1. Parse the input
Extract: GitLab host, project path, MR iid, note id. If given a
discussion id, expand to the last note id.
**Done when:** the four fields are on hand and the host responds.

### 2. Harvest the discussion
Fetch the **whole** thread, not the target note alone. For DiffNotes,
capture file path and new line range.
**Done when:** every note is on hand.

### 3. Pin the MR
Fetch title, target branch, author, `Closes`/`Relates` issue keys,
head SHA. The related Jira key is a required hyperlink in the body.
**Done when:** iid, title, target branch, SHA, related keys on hand.

### 4. Clarify the scope (macro, closed choice)
Ask: "Périmètre du ticket — est-ce :"
- **(a) Spécifique à cette MR** — décision/action dans le contexte de
  cette MR, ne s'applique pas ailleurs
- **(b) Généralisation d'un pattern** — règle réutilisable ailleurs
- **(c) Recherche d'abord** — mesurer / comparer / investiguer avant
  de pouvoir décider

Exactly one. Type stays `Task` in all three cases.
**Done when:** the user has chosen.

### 5. Clarify three things (open, one round)
Ask together, in one question block:

a. **"Le ticket porte sur *faut-il le faire* ou sur *comment le
   faire* ?"** The answer becomes exactly one sentence in the body:
   "Ce ticket porte sur le *comment*."
b. **"Qu'est-ce qui est hors scope ?"** Do not offer abstract
   (i)/(ii)/(iii) boundaries — they get mis-picked. Ask concretely,
   and state the default you will apply: *la décision est prise dans
   ce ticket ; seule l'implémentation part en ticket à part.* A
   research ticket that concludes nothing is worthless.
c. **"Comment valide-t-on le livrable ?"** (reproduire le bug sur un
   serveur de dev / comparer deux mesures / relire un plan…). Never
   guess this.

Do **not** ask who arbitrates the decision — on a real run that
answer produced zero text in the ticket.
**Done when:** a, b, c are answered.

### 6. Distill
3 lines max: the unresolved question, the options, the recommendation
if any. Must stand alone for a reader with no MR access.
**Done when:** 3 lines, self-contained.

### 7. Confirm the Jira shape (micro)
Pre-fill the defaults table, including **labels and status**. Ask to
confirm or override. No silent override.
**Done when:** all six fields set.

### 8. Locate the task template
`docs/team-backend/task-template.{lang}.md` in the repo. If absent,
ask which template to use.
**Done when:** template path on hand, or "no template" chosen.

### 9. Forge the body

Scope (a) → framed "lié à cette MR uniquement".
Scope (b) → framed "réutilisable pour d'autres cas similaires".
Scope (c) → use this skeleton verbatim, three sections, nothing more:

```markdown
## 💭 Quel Problème Résolvons-nous et Pourquoi ?

<La MR [!N](url) ([XCP-XXXX](jira-url)) fait X. Conséquence non couverte.>
<Un nom : la personne qui a soulevé le problème, et pourquoi ça compte.>
<Le blocage identifié dans le [thread](note-url) est qu'on ne sait pas si …>

## 🔭 Scope & Contraintes

Ce ticket porte sur le *comment*.
Livrable => une restitution écrite répondant à deux questions :
- <question 1>
- <question 2, conditionnelle : "Si c'est possible, …">
Hors scope : <ce que 5b a exclu>, qui fera l'objet d'un ticket à part.

## 📋 Étapes à Suivre

- <inventaire / mesure>
- <vérification du signal discriminant>
- Si oui : <proposition, validée selon la méthode donnée en 5c>
- Si non : documenter ce qu'il manque pour pouvoir <faire la chose>.
```

Rules that bind the skeleton:
- Steps use **bullets** when they branch (`Si oui` / `Si non`);
  numbers only when strictly sequential.
- The `Livrable` questions must not restate the steps. Two questions,
  three at the very most.
- Link the trigger note. Quote it verbatim **only if the wording
  itself is the signal** — a one-line review remark is summarized.
- Inline links, never a links block.

**Done when:** the body has the MR URL, the note URL, the related
Jira key as a link, is ≤ 250 words, and every "Never put this in the
body" line has been checked against it.

### 10. Checkpoint — show the draft, wait for go
Print title, body, and the six Jira fields. **Do not create.** Ask:
"On crée ? (terse ou complet ?)" On changes-requested, loop back to
4 / 5 / 7 / 9.
**Done when:** the user said yes.

### 11. Create, then transition
Write the body to a file with **one line per paragraph**, then:

```bash
jira issue create -p XCP -t Task -l RT -l Improvement \
  -s "<title>" --template /tmp/opencode/body.md --no-input
jira issue move <KEY> "Refinement Review"
```

`jira issue edit` has **no** `--template` flag — to fix a body use
`jira issue edit <KEY> --no-input -b "$(cat /tmp/opencode/body.md)"`.

Then render-check with `jira issue view <KEY> --plain`: links must
show their URL (proof they became ADF links), and each paragraph must
be one block, not one block per source line.

Person names stay plain text — jira-cli cannot emit ADF `mention`
nodes. Say so, and offer to let the user @-mention manually.
**Done when:** key on hand, status moved, render verified.

### 12. Offer the post-comment (opt-in)
Propose `glab mr note` linking the new issue. Wait for the go.
**Done when:** answered yes or no.

### 13. Hand back
Return the Jira URL and a one-line summary. Include the MR comment
URL if step 12 ran.
**Done when:** the user has the URL(s).
