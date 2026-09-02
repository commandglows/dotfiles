#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"; P="$ROOT_DIR/install-dotfiles.ps1"
[ -f "$P" ]; rg -n '\[switch\]\$DryRun|\[switch\]\$Check|\[switch\]\$Update|\[switch\]\$Uninstall|\[string\[\]\]\$Only' "$P" >/dev/null
rg -n 'status.*--porcelain|remote.*get-url.*origin|--ff-only|never resets or stashes|not a Git checkout' "$P" >/dev/null
rg -n 'journal\.tsv|backups|REFUSED changed target|Packages were intentionally left installed' "$P" >/dev/null
rg -n 'Import-Csv.*Delimiter|components\.tsv|Unknown or unsupported Windows component' "$P" >/dev/null
rg -n 'Update-ProcessPath|GetEnvironmentVariable.*Path.*User|GetEnvironmentVariable.*Path.*Machine' "$P" >/dev/null
rg -n 'InstallYaziPlugins|ya\.exe|pkg install|selected\.id -contains .yazi.' "$P" >/dev/null
rg -n '^neovim-shortcut\tdotfiles\twindows\tcore.*\tbin\t-\t\$\{HOME\}/\.dotfiles/bin\tnone\tpath.*\tn\.cmd\t-' "$ROOT_DIR/dotfiles/components.tsv" >/dev/null
rg -n 'where nvim\.exe|nvim\.exe %\*' "$ROOT_DIR/bin/n.cmd" >/dev/null
rg -n '^rio\tdotfiles\twindows\tcore.*raphamorim\.rio\trio/config\.toml\t-\t\$\{LOCALAPPDATA\}/rio/config\.toml\tnone\tcopy.*rio\|rio\.exe' "$ROOT_DIR/dotfiles/components.tsv" >/dev/null
rg -n 'SelectPrevSplit|SelectNextSplit|control \| shift' "$ROOT_DIR/rio/config.toml" >/dev/null
rg -n "@zed-industries/codex-acp@0\.16\.0|codex-acp-win32-\$architecture|pnpm\.cmd|npm\.cmd|--include=optional|--config\.optional=true" "$P" >/dev/null
rg -n 'Find-CodexAcpNativeBinary|Test-CodexAcpRuntime|Node reported success.*native' "$P" >/dev/null
rg -n 'Test-WinGetConvergedExitCode.*-1978335189|already at the latest applicable WinGet version' "$P" >/dev/null
rg -n 'pnpm.*bin --global|Find-CodexAcpWrapper|fixture-instance|no-applicable-upgrade' "$P" "$ROOT_DIR/tests/windows-bootstrap.behavior.Tests.ps1" >/dev/null
rg -n 'Test-HealthProbe|split.*&|split.*\\\|' "$P" >/dev/null
awk -F '\t' '
  $1=="windows-native-toolchain" { toolchain=($3=="windows" && $4=="core" && $11=="BrechtSanders.WinLibs.POSIX.UCRT" && $19=="gcc.exe&cmake.exe&ninja.exe") }
  $1=="tree-sitter-cli" { treesitter=($3=="windows" && $4=="core" && $11=="tree-sitter.tree-sitter-cli" && $19=="tree-sitter.exe") }
  $1=="codex-acp" { deps=($5=="neovim,windows-native-toolchain,tree-sitter-cli") }
  END { if(!toolchain || !treesitter || !deps) exit 1 }
' "$ROOT_DIR/dotfiles/components.tsv"
rg -n 'Build\.ps1 -BuildFromSource false' "$ROOT_DIR/nvim/MyNeovim/lua/plugins/avante.lua" >/dev/null
rg -n 'telescope_fzf_native_build|enabled = fzf_native_build ~= nil|executable\("cmake"\)|executable\("cl"\)' "$ROOT_DIR/nvim/MyNeovim/lua/plugins/telescope.lua" >/dev/null
if rg -n 'checkout.*-B|Set-ExecutionPolicy|\$PROFILE|doppler secrets|gh auth|curl.*\|.*(sh|bash)|Remove-Item.*-Recurse' "$P";then printf 'FAIL: forbidden behavior\n' >&2;exit 1;fi
rg -n 'install-dotfiles\.ps1|DryRun' "$ROOT_DIR/dotfiles/windows.ps1" >/dev/null
printf 'Windows bootstrap static contract: OK\n'
