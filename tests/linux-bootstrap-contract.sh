#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_STATE_HOME="$TMP/state"
export DOTFILES_REPO_URL="$ROOT_DIR"
export DOTFILES_BRANCH="contract-test"
mkdir -p "$HOME"

printf 'dotfiles: Dry-run preview without local checkout.\n'
export DOTFILES_DIR="$HOME/.dotfiles"
if "$ROOT_DIR/install-dotfiles.sh" --dry-run >"$TMP/dry.out" 2>&1; then
  if ! rg -q 'DRY-RUN: would clone' "$TMP/dry.out" || [ -e "$DOTFILES_DIR" ]; then
    echo "Expected a pure dry-run plan for missing checkout." >&2
    cat "$TMP/dry.out" >&2
    exit 1
  fi
else
  cat "$TMP/dry.out" >&2
  exit 1
fi

printf 'dotfiles: Fresh local checkout delegate preview.\n'
rm -rf "$DOTFILES_DIR"
git clone --quiet --no-checkout "$ROOT_DIR" "$DOTFILES_DIR"
git -C "$DOTFILES_DIR" checkout --quiet -b "$DOTFILES_BRANCH" "$(git -C "$ROOT_DIR" rev-parse HEAD)"
before="$(find "$TMP" -mindepth 1 ! -name dry.out ! -name delegated-dry.out -print | sort)"
if ! "$ROOT_DIR/install-dotfiles.sh" --dry-run --only neovim >"$TMP/delegated-dry.out" 2>&1; then
  cat "$TMP/delegated-dry.out" >&2
  exit 1
fi
after="$(find "$TMP" -mindepth 1 ! -name dry.out ! -name delegated-dry.out -print | sort)"
if [ "$before" != "$after" ] || rg -q 'DRY-RUN: would clone' "$TMP/delegated-dry.out"; then
  echo "Expected delegated dry-run on existing valid checkout without filesystem mutation." >&2
  echo "before:" >&2; printf '%s\n' "$before" >&2
  echo "after:" >&2; printf '%s\n' "$after" >&2
  cat "$TMP/delegated-dry.out" >&2
  exit 1
fi

printf 'dotfiles: Piped bootstrap delegate preview.\n'
if ! bash < "$ROOT_DIR/install-dotfiles.sh" --dry-run --only neovim >"$TMP/piped-dry.out" 2>&1; then
  cat "$TMP/piped-dry.out" >&2
  exit 1
fi
if rg -q 'Bad substitution|not found' "$TMP/piped-dry.out"; then
  cat "$TMP/piped-dry.out" >&2
  exit 1
fi

printf 'dotfiles: Non-git checkout guard.\n'
rm -rf "$DOTFILES_DIR"
mkdir -p "$HOME"
cat <<'EOF' > "$DOTFILES_DIR"
collision target
EOF
if "$ROOT_DIR/install-dotfiles.sh" --check >"$TMP/non-git.out" 2>&1; then
  echo "Expected failure on non-git checkout target." >&2
  exit 1
fi
if ! rg -q 'not a Git checkout' "$TMP/non-git.out"; then
  cat "$TMP/non-git.out" >&2
  exit 1
fi

printf 'Linux bootstrap contract: OK\n'
