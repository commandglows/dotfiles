-- Run with: nvim --headless -c "luafile tests/winbar-progress.lua" -c "qa!"
local progress = require("shipglows.progress")

progress.setup()
vim.cmd("enew")
local original = vim.wo.winbar

progress.start("test", { label = "Indexation", percentage = 30, bufnr = vim.api.nvim_get_current_buf() })
assert(vim.wo.winbar:find("shipglows.progress", 1, true), "overlay de progression absent")
local rendered = progress.winbar()
assert(rendered:find("Indexation", 1, true), "libelle de progression absent")
assert(rendered:find("30 %%"), "pourcentage de progression absent")
local evaluated = vim.api.nvim_eval_statusline(vim.wo.winbar, {
  winid = vim.api.nvim_get_current_win(),
  use_winbar = true,
}).str
assert(evaluated:find("Indexation", 1, true), "rendu reel de la winbar absent")

progress.update("test", { percentage = 72, message = "symboles" })
rendered = progress.winbar()
assert(rendered:find("72 %%"), "mise a jour du pourcentage absente")
assert(rendered:find("symboles", 1, true), "detail de progression absent")

progress.finish("test")
assert(vim.wo.winbar == original, "winbar originale non restauree")

print("WINBAR_PROGRESS_OK")
