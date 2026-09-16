-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.g.trouble_lualine = false

vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.fillchars:append({
  fold = " ",
  foldopen = "-",
  foldclose = "+",
  foldsep = " ",
})

-- Ensure mouse is fully enabled (scroll + click in all modes)
vim.opt.mouse = "a"
vim.opt.mousescroll = "ver:3,hor:6"

-- Prevent E35 "No previous regular expression" errors from snacks picker
-- when @/ register is empty and something internally calls n/N or histdel("search")
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    if vim.fn.getreg("/") == "" then
      vim.fn.setreg("/", "\\%^")
    end
  end,
})

vim.opt.sessionoptions = {
  "blank",
  "buffers",
  "curdir",
  "folds",
  "globals",
  "help",
  "tabpages",
  "winsize",
  "winpos",
  "terminal",
}

vim.opt.spell = false
vim.opt.spelllang = "fr,en_us"
