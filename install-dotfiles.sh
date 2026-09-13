#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${DOTFILES_REPO_URL:-https://github.com/commandglows/dotfiles.git}"
BRANCH="${DOTFILES_BRANCH:-master}"
DOTFILES_DIR="${DOTFILES_DIR:-${HOME:-/tmp}/.dotfiles}"

HAS_DRY_RUN=false
HAS_CHECK=false
HAS_UNINSTALL=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) HAS_DRY_RUN=true ;;
    --check) HAS_CHECK=true ;;
    --uninstall) HAS_UNINSTALL=true ;;
  esac
done

normalize_repo_url() {
  printf '%s' "$1" | tr '\\' '/' | sed -E 's#\.git/?$##' | sed -E 's#/$##' | tr '[:upper:]' '[:lower:]'
}

log() {
  printf 'dotfiles: %s\n' "$*"
}

die() {
  log "ERROR: $*"
  exit 1
}

require_git() {
  command -v git >/dev/null 2>&1 || die "git is missing; install git before running the bootstrap."
}

assert_checkout_ready() {
  [ -e "$DOTFILES_DIR/.git" ] || die "$DOTFILES_DIR exists but is not a Git checkout; it was left unchanged."
  local origin
  origin="$(git -C "$DOTFILES_DIR" remote get-url origin 2>/dev/null || true)"
  if [ -z "$origin" ]; then
    die "No git origin found in $DOTFILES_DIR; remove this path or repoint DOTFILES_DIR."
  fi
  if [ "$(normalize_repo_url "$origin")" != "$(normalize_repo_url "$REPO_URL")" ]; then
    die "Origin mismatch. Expected $REPO_URL, found $origin."
  fi
  local dirty
  dirty="$(git -C "$DOTFILES_DIR" status --porcelain 2>/dev/null || true)"
  [ -z "$dirty" ] || die "Local changes were found in $DOTFILES_DIR; commit or stash them before rerunning."
  local branch
  branch="$(git -C "$DOTFILES_DIR" branch --show-current 2>/dev/null || true)"
  [ "$branch" = "$BRANCH" ] || die "Checkout branch '$branch' does not match '$BRANCH'."
}

if [ ! -e "$DOTFILES_DIR" ]; then
  if [ "$HAS_DRY_RUN" = true ]; then
    log "DRY-RUN: would clone $REPO_URL ($BRANCH) into $DOTFILES_DIR."
    exit 0
  fi
  if [ "$HAS_CHECK" = false ] && [ "$HAS_UNINSTALL" = false ]; then
    require_git
    mkdir -p "$(dirname "$DOTFILES_DIR")"
    git clone --branch "$BRANCH" --single-branch "$REPO_URL" "$DOTFILES_DIR"
  fi
else
  assert_checkout_ready
fi

export DOTFILES_DIR
export DOTFILES_REPO_URL="$REPO_URL"
export DOTFILES_BRANCH="$BRANCH"

exec "$DOTFILES_DIR/dotfiles/install-dotfiles.sh" "$@"
