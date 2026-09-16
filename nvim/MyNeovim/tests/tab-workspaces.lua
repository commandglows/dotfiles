-- Run with: nvim --headless -c "luafile tests/tab-workspaces.lua" -c "qa!"
local lazy = require("lazy.core.config").plugins

assert(lazy["tabby.nvim"], "tabby.nvim absent")
assert(lazy["scope.nvim"], "scope.nvim absent")
assert(lazy["dropbar.nvim"], "dropbar.nvim absent")
assert(lazy["bufferline.nvim"] == nil or not lazy["bufferline.nvim"].enabled, "bufferline.nvim encore actif")
assert(not lazy["tabby.nvim"]._.loaded, "tabby.nvim charge trop tot")
assert(not lazy["scope.nvim"]._.loaded, "scope.nvim charge trop tot")
vim.cmd("doautocmd User VeryLazy")
assert(lazy["tabby.nvim"]._.loaded, "tabby.nvim non charge sur VeryLazy")
assert(lazy["scope.nvim"]._.loaded, "scope.nvim non charge sur VeryLazy")
assert(vim.o.showtabline == 2, "tabline non permanente")
assert(vim.o.tabline:find("TabbyRenderTabline", 1, true), "Tabby ne controle pas la tabline")

local lualine_config = require("lualine").get_config()
assert(vim.tbl_isempty(lualine_config.winbar), "Lualine occupe encore la winbar")

vim.cmd("enew")
vim.cmd("file ScopeTestA.md")
vim.bo.filetype = "markdown"
vim.cmd("doautocmd FileType markdown")
assert(lazy["dropbar.nvim"]._.loaded, "dropbar.nvim non charge sur FileType")
local first = vim.api.nvim_get_current_buf()
vim.cmd("badd ScopeTestB.lua")
local second = vim.fn.bufnr("ScopeTestB.lua")

assert(vim.wo.winbar:find("dropbar", 1, true), "Dropbar ne controle pas la winbar Markdown")
local unnamed_tabline = vim.api.nvim_eval_statusline(vim.o.tabline, { use_tabline = true, maxwidth = 160 }).str
assert(unnamed_tabline:find("Espace 1", 1, true), "nom stable par defaut absent")

local editor_win = vim.api.nvim_get_current_win()
vim.cmd("topleft 24vnew")
local explorer_win = vim.api.nvim_get_current_win()
vim.bo.filetype = "neo-tree"
vim.bo.buflisted = false
local explorer_width = vim.api.nvim_win_get_width(0) + 1
vim.api.nvim_set_current_win(editor_win)
local offset_tabline = vim.api.nvim_eval_statusline(vim.o.tabline, { use_tabline = true, maxwidth = 160 }).str
local explorer_end = offset_tabline:find("Explorateur", 1, true) + #"Explorateur" - 1
local workspace_start = offset_tabline:find("Espace 1", 1, true)
assert(explorer_end <= explorer_width, "libelle Explorateur hors de son offset")
assert(workspace_start > explorer_width, "espace courant melange avec l'offset Explorateur")
local previous_columns = vim.o.columns
vim.o.columns = 40
local narrow_tabline = vim.api.nvim_eval_statusline(vim.o.tabline, { use_tabline = true, maxwidth = 40 }).str
assert(narrow_tabline:find("Explorateur", 1, true), "offset Explorateur tronque en largeur reduite")
assert(narrow_tabline:find("E1", 1, true), "espace compact absent en largeur reduite")
vim.o.columns = previous_columns
vim.api.nvim_win_close(explorer_win, true)

vim.api.nvim_set_current_win(editor_win)
vim.cmd("topleft 20vnew")
local undo_win = vim.api.nvim_get_current_win()
vim.bo.filetype = "undotree"
vim.bo.buflisted = false
local undo_width = vim.api.nvim_win_get_width(0) + 1
vim.api.nvim_set_current_win(editor_win)
local undo_tabline = vim.api.nvim_eval_statusline(vim.o.tabline, { use_tabline = true, maxwidth = 160 }).str
local undo_end = undo_tabline:find("Undo", 1, true) + #"Undo" - 1
local undo_workspace_start = undo_tabline:find("Espace 1", 1, true)
assert(undo_end <= undo_width, "libelle Undo hors de son offset")
assert(undo_workspace_start > undo_width, "espace courant melange avec l'offset Undo")
vim.api.nvim_win_close(undo_win, true)

vim.api.nvim_set_current_win(editor_win)
vim.cmd("botright 22vnew")
local trouble_win = vim.api.nvim_get_current_win()
vim.bo.filetype = "Trouble"
vim.bo.buflisted = false
local trouble_width = vim.api.nvim_win_get_width(0) + 1
vim.api.nvim_set_current_win(editor_win)
local trouble_tabline = vim.api.nvim_eval_statusline(vim.o.tabline, { use_tabline = true, maxwidth = 160 }).str
local trouble_start = trouble_tabline:find("Trouble", 1, true)
assert(trouble_start and trouble_start > 160 - trouble_width, "libelle Trouble hors de son offset droit")
vim.api.nvim_win_close(trouble_win, true)

vim.cmd("Tabby rename_tab Code")
vim.cmd("tabnew")
vim.cmd("file ScopeTestC.md")
vim.bo.filetype = "markdown"
vim.cmd("doautocmd FileType markdown")
local third = vim.api.nvim_get_current_buf()
vim.cmd("Tabby rename_tab Documentation")

vim.cmd("tabprevious")
assert(vim.fn.buflisted(first) == 1 and vim.fn.buflisted(second) == 1, "buffers espace 1 non restaures")
assert(vim.fn.buflisted(third) == 0, "buffer espace 2 encore liste dans espace 1")
local first_tabline = vim.api.nvim_eval_statusline(vim.o.tabline, { use_tabline = true, maxwidth = 160 }).str
assert(first_tabline:find("Code", 1, true), "espace courant absent de la tabline")
assert(not first_tabline:find("Documentation", 1, true), "espace inactif visible dans la tabline")
assert(first_tabline:find("ScopeTestA.md", 1, true), "buffer A absent de la tabline de l'espace 1")
assert(first_tabline:find("ScopeTestB.lua", 1, true), "buffer B absent de la tabline de l'espace 1")
assert(not first_tabline:find("ScopeTestC.md", 1, true), "buffer C visible dans la tabline de l'espace 1")

vim.cmd("tabnext")
assert(vim.fn.buflisted(first) == 0 and vim.fn.buflisted(second) == 0, "buffers espace 1 encore listes")
assert(vim.fn.buflisted(third) == 1, "buffer espace 2 non restaure")
local second_tabline = vim.api.nvim_eval_statusline(vim.o.tabline, { use_tabline = true, maxwidth = 160 }).str
assert(second_tabline:find("Documentation", 1, true), "nom de l'espace courant absent")
assert(not second_tabline:find("Code", 1, true), "espace inactif visible dans la tabline")
assert(second_tabline:find("ScopeTestC.md", 1, true), "buffer C absent de la tabline de l'espace 2")
assert(not second_tabline:find("ScopeTestA.md", 1, true), "buffer A visible dans la tabline de l'espace 2")

local session_options = vim.opt.sessionoptions:get()
assert(vim.tbl_contains(session_options, "globals"), "sessionoptions ne conserve pas les noms et l'etat Scope")
local auto_session = lazy["auto-session"]
assert(vim.tbl_contains(auto_session.opts.pre_save_cmds, "ScopeSaveState"), "ScopeSaveState absent d'AutoSession")
assert(vim.tbl_contains(auto_session.opts.post_restore_cmds, "ScopeLoadState"), "ScopeLoadState absent d'AutoSession")

vim.wait(100, function()
  return vim.fn.maparg(vim.keycode("<leader><tab>2"), "n") ~= ""
end)
for _, lhs in ipairs({
  "]t",
  "[t",
  "<leader><tab>j",
  "<leader><tab>r",
  "<leader><tab>m",
  "<leader><tab>b",
  "<leader>;",
  "[;",
  "];",
}) do
  local expanded = lhs:gsub("<leader>", vim.g.mapleader or "\\")
  assert(vim.fn.maparg(vim.keycode(expanded), "n") ~= "", "raccourci absent: " .. lhs)
end
assert(vim.fn.maparg(vim.keycode("<leader><tab>1"), "n") ~= "", "raccourci espace 1 absent")
assert(vim.fn.maparg(vim.keycode("<leader><tab>2"), "n") ~= "", "raccourci espace 2 absent")
assert(vim.fn.maparg(vim.keycode("<leader><tab>3"), "n") == "", "raccourci espace 3 affiche sans espace")
vim.cmd("tabclose")
vim.wait(100, function()
  return vim.fn.maparg(vim.keycode("<leader><tab>2"), "n") == ""
end)
assert(vim.fn.maparg(vim.keycode("<leader><tab>2"), "n") == "", "raccourci espace 2 conserve apres fermeture")

print("TAB_WORKSPACES_OK")
