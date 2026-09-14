return {
  "Cannon07/code-preview.nvim",
  event = "VeryLazy",
  cmd = {
    "CodePreviewInstallClaudeCodeHooks",
    "CodePreviewInstallOpenCodeHooks",
    "CodePreviewInstallCodexCliHooks",
    "CodePreviewInstallCopilotCliHooks",
    "CodePreviewUninstallClaudeCodeHooks",
    "CodePreviewUninstallOpenCodeHooks",
    "CodePreviewUninstallCodexCliHooks",
    "CodePreviewCloseDiff",
    "CodePreviewStatus",
  },
  config = function()
    require("code-preview").setup({
      diff = {
        layout = "tab",
      },
    })
  end,
}