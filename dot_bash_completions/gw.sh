# gw - Git Worktree switcher
# List all branches across repos with worktrees, fuzzy-select one, and
# cd into its worktree (or create one if it doesn't exist yet).
gw() {
    local gitlab_dir="$HOME/Documents/Gitlab"

    # --- Discover repos that have a worktrees/ directory ---
    local repos=()
    for dir in "$gitlab_dir"/*.worktrees/; do
        [[ -d "$dir" ]] || continue
        local repo_name
        repo_name=$(basename "$dir" .worktrees)
        [[ -d "$gitlab_dir/$repo_name/.git" ]] || [[ -f "$gitlab_dir/$repo_name/.git" ]] || continue
        repos+=("$repo_name")
    done

    if [[ ${#repos[@]} -eq 0 ]]; then
        echo "gw: no worktree-enabled repos found in $gitlab_dir" >&2
        return 1
    fi

    # --- Pick repo (skip if only one) ---
    local selected_repo
    if [[ ${#repos[@]} -eq 1 ]]; then
        selected_repo="${repos[0]}"
    else
        local sorted_repos
        sorted_repos=$(printf "%s\n" "${repos[@]}" \
            | awk '{if ($0 == "realtime-helm-package") print "\x00" $0; else print $0}' \
            | sort \
            | sed 's/^\x00//')
        selected_repo=$(echo "$sorted_repos" | fzf --height=40% --border --prompt="Repo > ")
    fi

    local repo_dir="$gitlab_dir/$selected_repo"
    local worktree_base="$gitlab_dir/$selected_repo.worktrees"
    mkdir -p "$worktree_base"

    # --- Fetch remote branches ---
    git --git-dir="$repo_dir/.git" fetch --prune origin 2>&1 | tail -1

    # --- Collect all branches (local + remote, deduplicated) ---
    local branches
    branches=$(git --git-dir="$repo_dir/.git" for-each-ref \
        --sort=-committerdate \
        --format='%(refname:short)' \
        refs/heads/ refs/remotes/origin/ \
      | sed 's|^origin/||' \
      | awk '!seen[$0]++' \
      | grep -v '^HEAD$')

    # --- Build branch -> worktree-path map ---
    local -A wt_map=()
    local current_wt=""
    while IFS= read -r line; do
        if [[ "$line" == worktree\ * ]]; then
            current_wt="${line#worktree }"
        elif [[ "$line" == branch\ refs/heads/* ]]; then
            local b="${line#branch refs/heads/}"
            wt_map["$b"]="$current_wt"
        fi
    done < <(git --git-dir="$repo_dir/.git" worktree list --porcelain 2>/dev/null)

    # --- Annotate branches with worktree path and fuzzy-select ---
    local chosen
    chosen=$(echo "$branches" | while IFS= read -r branch; do
        [[ -z "$branch" ]] && continue
        if [[ -n "${wt_map[$branch]:-}" ]]; then
            echo "$branch  (${wt_map[$branch]})"
        else
            echo "$branch"
        fi
    done | fzf --height=40% --border --prompt="Branch > " --select-1)

    [[ -z "$chosen" ]] && return

    local chosen_branch
    chosen_branch=$(echo "$chosen" | awk '{print $1}')

    # --- cd to existing worktree, or create one first ---
    if [[ -n "${wt_map[$chosen_branch]:-}" ]]; then
        cd "${wt_map[$chosen_branch]}" || return
    else
        local safe_name
        safe_name=$(echo "$chosen_branch" | sed 's|/|-|g; s/[^a-zA-Z0-9._-]//g')
        local target_dir="$worktree_base/$safe_name"

        if git --git-dir="$repo_dir/.git" show-ref --verify --quiet "refs/heads/$chosen_branch"; then
            git --git-dir="$repo_dir/.git" worktree add "$target_dir" "$chosen_branch" || return
        else
            git --git-dir="$repo_dir/.git" worktree add -b "$chosen_branch" "$target_dir" "origin/$chosen_branch" || return
        fi
        cd "$target_dir" || return
    fi
}

gwo() {
     gw && opencode
}

# gwrm - remove worktrees whose branch is merged into develop
gwrm() {
    local gitlab_dir="$HOME/Documents/Gitlab"

    # --- Discover repos (duplicated from gw) ---
    local repos=()
    for dir in "$gitlab_dir"/*.worktrees/; do
        [[ -d "$dir" ]] || continue
        local repo_name; repo_name=$(basename "$dir" .worktrees)
        [[ -d "$gitlab_dir/$repo_name/.git" || -f "$gitlab_dir/$repo_name/.git" ]] || continue
        repos+=("$repo_name")
    done
    if [[ ${#repos[@]} -eq 0 ]]; then
        echo "gwrm: no worktree-enabled repos found in $gitlab_dir" >&2; return 1
    fi

    # --- Pick repo (skip if only one) ---
    local selected_repo
    if [[ ${#repos[@]} -eq 1 ]]; then
        selected_repo="${repos[0]}"
    else
        local sorted_repos
        sorted_repos=$(printf "%s\n" "${repos[@]}" \
            | awk '{if ($0 == "realtime-helm-package") print "\x00" $0; else print $0}' \
            | sort | sed 's/^\x00//')
        selected_repo=$(echo "$sorted_repos" | fzf --height=40% --border --prompt="Repo > ")
    fi
    [[ -z "$selected_repo" ]] && return
    local repo_dir="$gitlab_dir/$selected_repo"

    # --- Fetch + resolve develop ref ---
    git --git-dir="$repo_dir/.git" fetch --prune origin 2>&1 | tail -1
    local dev_ref
    if git --git-dir="$repo_dir/.git" show-ref --verify --quiet refs/heads/develop; then
        dev_ref="develop"
    elif git --git-dir="$repo_dir/.git" show-ref --verify --quiet refs/remotes/origin/develop; then
        dev_ref="origin/develop"
    else
        echo "gwrm: no develop branch in $selected_repo" >&2; return 1
    fi

    # --- branch -> worktree map (duplicated from gw) ---
    local -A wt_map=()
    local current_wt=""
    while IFS= read -r line; do
        if [[ "$line" == worktree\ * ]]; then
            current_wt="${line#worktree }"
        elif [[ "$line" == branch\ refs/heads/* ]]; then
            wt_map["${line#branch refs/heads/}"]="$current_wt"
        fi
    done < <(git --git-dir="$repo_dir/.git" worktree list --porcelain 2>/dev/null)

    # --- Remove merged worktrees ---
    local removed=0 b path
    while IFS= read -r b; do
        b="${b#\* }"; b="${b//[[:space:]]/}"
        [[ -z "$b" || "$b" == "develop" ]] && continue
        path="${wt_map[$b]:-}"
        [[ "$path" == "$repo_dir.worktrees/"* ]] || continue
        # skip worktrees with uncommitted or stashed changes
        if git --git-dir="$repo_dir/.git" --work-tree="$path" status --porcelain | grep -q .; then
            echo "gwrm: $b has uncommitted changes, skipping" >&2; continue
        fi
        if git --git-dir="$repo_dir/.git" stash list 2>/dev/null | grep -q "^stash@{.*}: WIP on $b:"; then
            echo "gwrm: $b has stashed changes, skipping" >&2; continue
        fi
        echo "Removing worktree $path (branch $b)"
        git --git-dir="$repo_dir/.git" worktree remove "$path" \
            && git --git-dir="$repo_dir/.git" branch -d "$b" \
            && removed=$((removed+1))
    done < <(git --git-dir="$repo_dir/.git" branch --merged "$dev_ref" --format='%(refname:short)')

    [[ $removed -eq 0 ]] && echo "gwrm: nothing merged into $dev_ref to clean" || echo "gwrm: removed $removed worktree(s)"
}
