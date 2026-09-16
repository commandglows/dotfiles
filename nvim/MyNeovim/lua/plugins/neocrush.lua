return {
  "taigrr/neocrush.nvim",
  enabled = true,
  branch = "v2-bridge",
  event = "VeryLazy",
  dependencies = {
    { "nvim-telescope/telescope.nvim" },
    { "taigrr/glaze.nvim" },
  },
  config = function(_, opts)
    local glaze = require("glaze")
    glaze.register("crush", "github.com/taigrr/crush", { plugin = "neocrush.nvim" })
    require("neocrush").setup(opts)
  end,
  opts = {
    highlight_group = "IncSearch",
    highlight_duration = 900,
    auto_focus = true,
    terminal_width = 80,
    terminal_side = "right",
    terminal_cmd = "crush",
    cvm = {
      upstream = "taigrr/crush",
    },
    keys = {
      toggle = "<leader>cc",
      focus = "<leader>cf",
      logs = "<leader>cl",
      cancel = "<leader>cx",
      restart = "<leader>cr",
      paste = "<leader>cp",
      cvm_releases = "<leader>cvr",
      cvm_local = "<leader>cvl",
    },
  },
}
