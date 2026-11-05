# dotfiles

Laptop setup (Ubuntu 22.04) managed with [chezmoi](https://chezmoi.io).

## New machine

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin init --apply https://github.com/ArthurVinot/dotfiles.git
```

## Profiles

`chezmoi init` asks once for a **profile** (`work` / `personal`) and a git email,
stored in `~/.config/chezmoi/chezmoi.toml`. Work-only parts:

- `.bashrc`: jira, kubectl/kubectx, KUBECONFIG, `pass` secrets, mssql/keploy, gcloud, `cdgl`, `oc` (`{{ if .work }}` blocks)
- `.gitconfig`: gitlab.com credential helper (via `pass`), `safe.directory`, `defaultBranch = develop`, pre-push hook
- opencode `opencode.json`: Claude Code plugin/provider, Bedrock, OpenRouter (Gemini, Anthropic via Bedrock), `claude-code` build/plan models
- Files listed in `.chezmoiignore` (k9s, `~/.bash_completions`, git hooks, opencode `AGENTS.md` and work agents/skills)
- `work:` sections of `.chezmoidata/packages.yaml`, `npm:confluence-cli` in the mise config

Change profile: `chezmoi init --prompt` (or edit `chezmoi.toml`), then `chezmoi apply`.

Personal OpenCode: Sol high (Build), Astra high (Plan); connect your ChatGPT/Codex account with `opencode auth login openai`.

## Layout

| What | Where |
|---|---|
| Dotfiles | `dot_*`, `private_dot_config/` |
| Package lists (apt, brew, snap, flatpak) | `.chezmoidata/packages.yaml` |
| Runtimes (python, node), pipx/npm CLI tools, other CLI tools | `private_dot_config/mise/config.toml` |
| Managers and CLI bootstrap (mise, brew, bun, oh-my-posh, opencode, codex; both profiles) | `run_once_before_00-bootstrap.sh` |
| Install scripts (re-run when their list changes) | `run_onchange_after_*.sh.tmpl` |
| oh-my-tmux upstream config | `.chezmoiexternal.toml` |

## Daily use

```sh
chezmoi add ~/.some_file      # track a new file
chezmoi re-add                # pull live edits back into the repo
chezmoi diff && chezmoi apply # push repo state to $HOME
```

## Secrets

Never committed. They live in `pass` (`~/.password-store`, restore it + the GPG key manually);
`.bashrc` loads them via `pass show env/bashrc_secrets`. Not tracked on purpose:
`~/.git-credentials`, `~/.config/opencode/service.json`, `~/.kube`, `~/.docker/config.json`, `~/.claude.json`.

## Manual installs (third-party apt repos / .deb)

docker-ce (+ buildx/compose plugins), google-chrome-stable, brave-browser, slack-desktop,
claude-desktop, clockify, balena-etcher, mongodb-compass / mongosh / database-tools,
mysql-workbench-community / mysql-connector-odbc, pgadmin4, virtualbox-7.1, gitlab-ci-local,
displaylink-driver, nnstreamer, dive, klogg, sequeler, mssql-tools18, Google Cloud SDK (`~/google-cloud-sdk`),
JetBrains Toolbox.
