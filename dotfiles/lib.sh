#!/usr/bin/env bash

die() { printf 'dotfiles: ERROR: %s\n' "$*" >&2; exit 1; }
info() { printf 'dotfiles: %s\n' "$*"; }
plan() { printf 'dotfiles: DRY-RUN: %s\n' "$*"; }

normalize_repo_url() { printf '%s' "$1" | tr '\\' '/' | sed -E 's#\.git/?$##;s#/$##' | tr '[:upper:]' '[:lower:]'; }

require_linux_host() {
  case "$(uname -s)" in
    Linux) ;;
    MINGW*|MSYS*|CYGWIN*) die 'Windows/MSYS is unsupported here. Run powershell.exe -NoProfile -File install-dotfiles.ps1.' ;;
    *) die 'This installer supports native Linux only. Use install-dotfiles.ps1 on Windows.' ;;
  esac
  [ -z "${TERMUX_VERSION:-}" ] || die 'Termux keeps its dedicated installer: dotfiles/termux.sh.'
}

show_help() {
  cat <<'EOF'
Usage: install-dotfiles.sh [--dry-run|--check|--update|--uninstall] [--only id,id]

Dry-run mutates nothing. Check is read-only. Update fast-forwards a clean,
matching checkout. Uninstall removes only journal-proven artifacts, restores
backups, and leaves packages installed. ShipGlows owns agents, skills, MCP,
Doppler, and developer provisioning.
EOF
}

parse_arguments() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --dry-run) DOTFILES_DRY_RUN=true ;;
      --check) DOTFILES_CHECK=true ;;
      --update) DOTFILES_UPDATE=true ;;
      --uninstall) DOTFILES_UNINSTALL=true ;;
      --only=*) DOTFILES_ONLY="${1#*=}" ;;
      --only) shift; [ "$#" -gt 0 ] || die '--only requires a comma-separated value'; DOTFILES_ONLY="$1" ;;
      --help|-h) show_help; exit 0 ;;
      *) die "unknown option: $1" ;;
    esac
    shift
  done
  local count=0
  [ "$DOTFILES_CHECK" = true ] && count=$((count+1)); [ "$DOTFILES_UPDATE" = true ] && count=$((count+1)); [ "$DOTFILES_UNINSTALL" = true ] && count=$((count+1))
  [ "$count" -le 1 ] || die 'choose only one of --check, --update, or --uninstall'
  if [ "$DOTFILES_DRY_RUN" = true ] && [ "$count" -gt 0 ]; then die '--dry-run cannot be combined with --check, --update, or --uninstall'; fi
}

git_text() { local output; output="$(git "$@" 2>&1)" || die "git $* failed: $output"; printf '%s' "$output"; }

validate_checkout() {
  [ -e "$DOTFILES_DIR" ] || return 1
  [ -e "$DOTFILES_DIR/.git" ] || die "$DOTFILES_DIR exists but is not a Git checkout; it was left unchanged"
  command -v git >/dev/null 2>&1 || die 'git is required to validate the checkout'
  local origin dirty branch
  origin="$(git_text -C "$DOTFILES_DIR" remote get-url origin)"
  [ "$(normalize_repo_url "$origin")" = "$(normalize_repo_url "$DOTFILES_REPO_URL")" ] || die "origin mismatch: expected $DOTFILES_REPO_URL, found $origin"
  dirty="$(git_text -C "$DOTFILES_DIR" status --porcelain)"
  [ -z "$dirty" ] || die 'checkout is dirty; commit or stash it (the installer never resets or stashes)'
  branch="$(git_text -C "$DOTFILES_DIR" branch --show-current)"
  [ "$branch" = "$DOTFILES_BRANCH" ] || die "checkout branch '$branch' does not match '$DOTFILES_BRANCH'; switch explicitly"
}

sync_checkout() {
  [ -e "$DOTFILES_DIR" ] || die "$DOTFILES_DIR is absent. Clone $DOTFILES_REPO_URL there first; this entrypoint never executes a remote script."
  validate_checkout
  if [ "$DOTFILES_UPDATE" = true ]; then
    git -C "$DOTFILES_DIR" fetch origin "$DOTFILES_BRANCH" || die 'git fetch failed'
    git -C "$DOTFILES_DIR" merge --ff-only "origin/$DOTFILES_BRANCH" || die 'checkout is not fast-forwardable'
  fi
}

validate_manifest() {
  [ -f "$DOTFILES_MANIFEST" ] || die "manifest not found: $DOTFILES_MANIFEST"
  local expected=$'id\towner\tplatforms\tprofile\tdeps\tapt_package\tdnf_package\tpacman_package\tzypper_package\tbrew_package\twinget_package\tconfig_source\ttarget_linux\ttarget_windows\tmode_linux\tmode_windows\tconflict_policy\tprivilege\thealth_probe\tnode_package' header
  IFS= read -r header < "$DOTFILES_MANIFEST"; [ "$header" = "$expected" ] || die 'components.tsv header does not match the required schema'
  awk -F '\t' 'NR>1 {if(NF!=20||$1!~/^[a-z0-9][a-z0-9-]*$/||seen[$1]++||$2!="dotfiles"||$17!="backup")exit 1}' "$DOTFILES_MANIFEST" || die 'components.tsv has an invalid, duplicate, foreign-owned, or unsafe row'
}

platform_rows() { awk -F '\t' 'NR>1 && (","$3",")~/,linux,/ {print}' "$DOTFILES_MANIFEST"; }

select_components() {
  local requested id row deps dep old_ifs
  requested="$DOTFILES_ONLY"; if [ -z "$requested" ]; then requested="$(platform_rows|awk -F '\t' '$4=="core"{printf "%s%s",s,$1;s=","}')"; fi
  [ -n "$requested" ] || die 'no Linux components selected'; SELECTED_IDS=""
  add_component() {
    id="$1"; case ",$SELECTED_IDS," in *",$id,"*) return;; esac
    row="$(platform_rows|awk -F '\t' -v id="$id" '$1==id{print;found=1}END{if(!found)exit 1}')" || die "unknown or unsupported Linux component: $id"
    deps="$(printf '%s\n' "$row"|cut -f5)"
    if [ -n "$deps" ] && [ "$deps" != '-' ]; then old_ifs="$IFS"; IFS=','; for dep in $deps; do add_component "$dep"; done; IFS="$old_ifs"; fi
    SELECTED_IDS="${SELECTED_IDS:+$SELECTED_IDS,}$id"
  }
  old_ifs="$IFS"; IFS=','; for id in $requested; do [ -n "$id" ] || die 'empty component in --only'; add_component "$id"; done; IFS="$old_ifs"; export SELECTED_IDS
}

selected_rows() { platform_rows|awk -F '\t' -v ids=",$SELECTED_IDS," 'index(ids,","$1","){print}'; }

resolve_target() {
  local value="$1" xdg="${XDG_CONFIG_HOME:-$HOME/.config}"
  value="${value//'${HOME}'/$HOME}"; value="${value//'${XDG_CONFIG_HOME}'/$xdg}"; printf '%s' "$value"
}

assert_user_target() {
  case "$1" in "$HOME"|"$HOME"/*) ;; *) die "refusing target outside HOME: $1";; esac
  case "$1" in *$'\t'*|*$'\n'*) die 'target contains a tab or newline';; esac
}

ensure_state() { mkdir -p "$DOTFILES_STATE_DIR"; [ -f "$DOTFILES_JOURNAL" ] || printf 'platform\tcomponent\ttarget\tsource\tkind\tbackup\tproof\n' > "$DOTFILES_JOURNAL"; }
append_journal() {
  local v; for v in "$@"; do case "$v" in *$'\t'*|*$'\n'*) die 'unsafe journal value';; esac; done
  ensure_state; printf 'linux\t%s\t%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" "$5" "$6" >> "$DOTFILES_JOURNAL"
}

backup_target() {
  local component="$1" target="$2" root backup
  [ -e "$target" ] || [ -L "$target" ] || return 0
  root="$DOTFILES_STATE_DIR/backups/$(date -u +%Y%m%dT%H%M%SZ)-$$"; mkdir -p "$root"; backup="$root/${component}-$(basename "$target")"
  [ ! -e "$backup" ] || backup="$backup-$RANDOM"; mv -- "$target" "$backup"; info "preserved existing target in $backup" >&2; printf '%s' "$backup"
}

hash_file() { if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1"|awk '{print $1}'; else shasum -a 256 "$1"|awk '{print $1}'; fi; }

create_managed_link() {
  local component="$1" source="$2" target="$3" backup
  assert_user_target "$target"; [ -e "$source" ] || die "source missing for $component: $source"
  if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$source")" ]; then return; fi
  if [ "$DOTFILES_DRY_RUN" = true ]; then plan "would link $target -> $source"; return; fi
  backup="$(backup_target "$component" "$target")"; mkdir -p "$(dirname "$target")"; ln -s "$source" "$target"
  append_journal "$component" "$target" "$source" link "$backup" "link:$(readlink -f "$source")"
}

create_managed_copy() {
  local component="$1" source="$2" target="$3" backup
  assert_user_target "$target"; [ -f "$source" ] || die "source missing for $component: $source"
  if [ -f "$target" ] && [ "$(hash_file "$source")" = "$(hash_file "$target")" ]; then return; fi
  if [ "$DOTFILES_DRY_RUN" = true ]; then plan "would copy $source to $target"; return; fi
  backup="$(backup_target "$component" "$target")"; mkdir -p "$(dirname "$target")"; cp -- "$source" "$target"
  append_journal "$component" "$target" "$source" copy "$backup" "sha256:$(hash_file "$target")"
}

install_shell_block() {
  local component="$1" target="$2" begin end tmp
  assert_user_target "$target"; begin="# >>> dotfiles:$component >>>"; end="# <<< dotfiles:$component <<<"
  if [ -f "$target" ] && grep -Fq "$begin" "$target"; then return; fi
  if [ "$DOTFILES_DRY_RUN" = true ]; then plan "would add managed shell block $component to $target"; return; fi
  mkdir -p "$(dirname "$target")"; tmp="$(mktemp "$(dirname "$target")/.dotfiles-shell.XXXXXX")"; [ ! -f "$target" ] || cat "$target" > "$tmp"
  cat >> "$tmp" <<EOF

$begin
export PATH="\$HOME/.local/bin:\$PATH"
command -v starship >/dev/null 2>&1 && eval "\$(starship init bash)"
command -v zoxide >/dev/null 2>&1 && eval "\$(zoxide init bash)"
$end
EOF
  mv -- "$tmp" "$target"; append_journal "$component" "$target" builtin:shell-block shell-block '' "marker:$component"
}

detect_package_manager() { local m; for m in apt-get dnf pacman zypper brew; do command -v "$m" >/dev/null 2>&1 && { printf '%s' "$m"; return; }; done; return 1; }
package_column() { case "$1" in apt-get)printf 6;;dnf)printf 7;;pacman)printf 8;;zypper)printf 9;;brew)printf 10;;esac; }
run_privileged() { if [ "$(id -u)" -eq 0 ]; then "$@"; elif command -v sudo >/dev/null 2>&1; then sudo -- "$@"; else die "package installation requires root or sudo: $*"; fi; }
probe_ok() {
  local probes="$1" p path old="$IFS"
  IFS='|'; for p in $probes; do
    IFS="$old"
    if command -v "$p" >/dev/null 2>&1; then
      path="$(command -v "$p" 2>/dev/null)"
      case "$path" in /mnt/*|*.exe) IFS='|'; continue;; esac
      return 0
    fi
    IFS='|'
  done
  IFS="$old"; return 1
}

install_packages() {
  local manager column packages='' missing='' row package probe id
  manager="$(detect_package_manager)" || die 'no supported package manager found (apt-get, dnf, pacman, zypper, brew)'; column="$(package_column "$manager")"
  while IFS= read -r row; do
    id="$(printf '%s\n' "$row"|cut -f1)"; package="$(printf '%s\n' "$row"|cut -f"$column")"; probe="$(printf '%s\n' "$row"|cut -f19)"
    [ -n "$probe" ] && [ "$probe" != '-' ] || continue
    if [ "$DOTFILES_UPDATE" != true ] && probe_ok "$probe"; then continue; fi
    if [ -z "$package" ] || [ "$package" = '-' ]; then missing="${missing:+$missing, }$id ($probe)"; else packages="${packages:+$packages }$package"; fi
  done < <(selected_rows)
  [ -z "$missing" ] || die "dependencies have no $manager mapping: $missing. Install them explicitly or choose supported components."
  [ -n "$packages" ] || return
  if [ "$DOTFILES_DRY_RUN" = true ]; then plan "would use $manager for: $packages"; return; fi
  case "$packages" in *[!a-zA-Z0-9._+\ -]*) die 'unsafe package token in manifest';; esac
  # shellcheck disable=SC2086
  case "$manager" in apt-get)run_privileged apt-get update;run_privileged apt-get install -y --no-install-recommends $packages;;dnf)run_privileged dnf install -y $packages;;pacman)run_privileged pacman -S --needed --noconfirm $packages;;zypper)run_privileged zypper --non-interactive install $packages;;brew)brew install $packages;;esac
}

install_artifacts() {
  local row id source target mode
  while IFS= read -r row; do
    id="$(printf '%s\n' "$row"|cut -f1)"; source="$(printf '%s\n' "$row"|cut -f12)"; target="$(resolve_target "$(printf '%s\n' "$row"|cut -f13)")"; mode="$(printf '%s\n' "$row"|cut -f15)"
    case "$mode" in none|-) :;;link)create_managed_link "$id" "$DOTFILES_DIR/$source" "$target";;copy)create_managed_copy "$id" "$DOTFILES_DIR/$source" "$target";;shell-block)install_shell_block "$id" "$target";;*)die "unsupported Linux mode '$mode' for $id";;esac
  done < <(selected_rows)
}

check_installation() {
  local failed=0 row id source target mode probe
  while IFS= read -r row; do
    id="$(printf '%s\n' "$row"|cut -f1)";source="$(printf '%s\n' "$row"|cut -f12)";target="$(resolve_target "$(printf '%s\n' "$row"|cut -f13)")";mode="$(printf '%s\n' "$row"|cut -f15)";probe="$(printf '%s\n' "$row"|cut -f19)"
    if [ -n "$probe" ] && [ "$probe" != '-' ] && ! probe_ok "$probe"; then printf 'MISSING command: %s [%s]\n' "$probe" "$id";failed=1;fi
    case "$mode" in link)[ -L "$target" ]&&[ "$(readlink -f "$target")" = "$(readlink -f "$DOTFILES_DIR/$source")" ]||{ printf 'MISSING config: %s [%s]\n' "$target" "$id";failed=1;};;copy)[ -f "$target" ]||{ printf 'MISSING config: %s [%s]\n' "$target" "$id";failed=1;};;shell-block)[ -f "$target" ]&&grep -Fq "# >>> dotfiles:$id >>>" "$target"||{ printf 'MISSING shell block: %s [%s]\n' "$target" "$id";failed=1;};;esac
  done < <(selected_rows)
  [ "$failed" -eq 0 ] || die 'health check failed; see MISSING entries'; info 'Linux Dotfiles check passed.'
}

remove_shell_block() { local file="$1" component="$2" tmp;[ -f "$file" ]||return;tmp="$(mktemp "$(dirname "$file")/.dotfiles-uninstall.XXXXXX")";awk -v b="# >>> dotfiles:$component >>>" -v e="# <<< dotfiles:$component <<<" '$0==b{s=1;next}$0==e{s=0;next}!s{print}' "$file">"$tmp";mv -- "$tmp" "$file"; }

run_uninstall() {
  [ -f "$DOTFILES_JOURNAL" ] || { info 'no Linux journal exists; nothing is owned for removal'; return; }
  mapfile -t records < <(awk -F '\t' 'NR>1&&$1=="linux"{print}' "$DOTFILES_JOURNAL"); local -A seen=();local i record component target source kind backup proof owned
  for((i=${#records[@]}-1;i>=0;i--));do
    record="${records[$i]}";IFS=$'\t' read -r _ component target source kind backup proof<<<"$record";[ -z "${seen[$target]:-}" ]||continue;seen[$target]=1;assert_user_target "$target";owned=false
    case "$kind" in link)if [ ! -e "$target" ]&&[ ! -L "$target" ];then owned=true;elif [ -L "$target" ]&&[ "link:$(readlink -f "$target")" = "$proof" ];then owned=true;fi;;copy)if [ ! -e "$target" ];then owned=true;elif [ -f "$target" ]&&[ "sha256:$(hash_file "$target")" = "$proof" ];then owned=true;fi;;shell-block)if [ ! -f "$target" ]||grep -Fq "# >>> dotfiles:$component >>>" "$target";then owned=true;fi;;esac
    if [ "$owned" != true ];then printf 'REFUSED changed target: %s\n' "$target" >&2;continue;fi
    case "$kind" in link|copy)[ ! -e "$target" ]&&[ ! -L "$target" ]||rm -- "$target";;shell-block)remove_shell_block "$target" "$component";;esac
    if [ -n "$backup" ]&&[ -e "$backup" ];then mkdir -p "$(dirname "$target")";mv -- "$backup" "$target";info "restored $target";fi
  done;info 'packages were intentionally left installed'
}
