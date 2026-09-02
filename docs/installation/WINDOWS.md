# Windows installation

Run the canonical script without loading a PowerShell profile:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install-dotfiles.ps1 -DryRun
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install-dotfiles.ps1
```

Modes are `-DryRun`, `-Check`, `-Update`, and `-Uninstall`; they are mutually constrained. `-Only neovim,yazi,rio` selects components. `-SkipTools` applies configuration without WinGet packages. `-ConfigureWezTerm` adds WezTerm. Rio and its Windows configuration are part of the default core profile. Neovim and Yazi install the `n` and `y` command shortcuts with their shared dotfiles `bin` directory on the user `PATH`. Selecting Yazi automatically runs `ya pkg install` after its configuration is installed; `-InstallYaziPlugins` remains accepted for compatibility but is no longer required.

The checkout must have expected origin, branch, and clean worktree. Updates fetch and merge `--ff-only`; the installer never resets, stashes, or recreates a branch. WinGet failures explain the missing prerequisite. PATH reconstruction merges current process, user, and machine values.

No PowerShell profile, execution policy, credential, secret, agent, skill, MCP client, or Doppler setting is modified.
