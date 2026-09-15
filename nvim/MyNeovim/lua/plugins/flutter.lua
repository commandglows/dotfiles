return {
  "nvim-flutter/flutter-tools.nvim",
  ft = "dart",
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {},
  config = function()
    require("flutter-tools").setup({
      ui = {
        -- minimal UI configuration; users can extend later
        border = "rounded",
      },
      decorations = {
        statusline = {
          app_version = true,
          device = true,
        },
      },
    })
    -- Optional keymaps (grouped under <leader>f)
    local wk = require("which-key")
    wk.register({
      f = {
        name = "Flutter",
        r = { "<cmd>FlutterRun<cr>", "Run" },
        d = { "<cmd>FlutterDevices<cr>", "Devices" },
        s = { "<cmd>FlutterStartDebugging<cr>", "Start Debug" },
        c = { "<cmd>FlutterStop<cr>", "Stop" },
        w = { "<cmd>FlutterReload<cr>", "Hot Reload" },
        h = { "<cmd>FlutterHotRestart<cr>", "Hot Restart" },
      },
    }, { prefix = "<leader>" })
  end,
}