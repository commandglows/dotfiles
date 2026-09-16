return {
  "Wansmer/treesj",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  keys = {
    { "gS", "<cmd>TSJToggle<cr>", desc = "Basculer le bloc structure" },
  },
  opts = {
    use_default_keymaps = false,
    max_join_length = 120,
  },
}
