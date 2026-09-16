return {
  url = "https://codeberg.org/andyg/leap.nvim.git",
  dependencies = { "tpope/vim-repeat" },
  keys = {
    { "<leader>jl", "<Plug>(leap)", mode = { "n", "x", "o" }, desc = "Leap dans la fenetre" },
    { "<leader>jL", "<Plug>(leap-from-window)", mode = "n", desc = "Leap entre les fenetres" },
  },
}
