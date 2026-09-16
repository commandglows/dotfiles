return {
  "dmmulroy/tsc.nvim",
  cmd = { "TSC", "TSCStop", "TSCOpen", "TSCClose" },
  keys = {
    { "<leader>cT", "<cmd>TSC<cr>", desc = "TypeScript: verifier le projet" },
    { "<leader>xT", "<cmd>TSCOpen<cr>", desc = "TypeScript: ouvrir les erreurs" },
    { "<leader>xC", "<cmd>TSCClose<cr>", desc = "TypeScript: fermer les erreurs" },
  },
  opts = {
    auto_open_qflist = true,
    auto_close_qflist = false,
    auto_focus_qflist = false,
    auto_start_watch_mode = false,
    use_trouble_qflist = true,
    use_diagnostics = false,
    flags = {
      noEmit = true,
      watch = false,
    },
  },
}
