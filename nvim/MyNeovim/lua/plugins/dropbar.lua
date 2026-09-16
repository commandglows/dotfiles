return {
  "Bekaboo/dropbar.nvim",
  enabled = true,
  event = { "BufReadPost", "BufNewFile", "FileType" },
  dependencies = { "nvim-telescope/telescope-fzf-native.nvim" },
  opts = { bar = { padding = { left = 1, right = 1 } } },
  keys = {
    {
      "<leader>;",
      function()
        require("dropbar.api").pick()
      end,
      desc = "Choisir dans le fil d'Ariane",
    },
    {
      "[;",
      function()
        require("dropbar.api").goto_context_start()
      end,
      desc = "Debut du contexte precedent",
    },
    {
      "];",
      function()
        require("dropbar.api").select_next_context()
      end,
      desc = "Contexte suivant",
    },
  },
}
