return {
  "mbbill/undotree",
  cmd = "UndotreeToggle",
  init = function()
    if vim.fn.executable("diff") == 0 and vim.fn.executable("git") == 1 then
      vim.g.undotree_DiffCommand = "git diff --no-index --no-ext-diff --"
    end
  end,
  keys = {
    {
      "<leader>ut",
      "<cmd>UndotreeToggle<cr>",
      desc = "Arbre des annulations",
    },
  },
}
