@echo off
where nvim.exe >nul 2>nul
if errorlevel 1 (
  echo Neovim is not installed. Rerun the Dotfiles Windows bootstrap without -SkipTools.
  exit /b 1
)
nvim.exe %*
