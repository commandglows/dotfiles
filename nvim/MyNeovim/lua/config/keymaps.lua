-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("t", "<C-Space>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Root/cwd convention under <leader>: lowercase = current working directory, uppercase = project root

-- Snacks explorer under the Explorer group (leader e)
-- Override the default <leader>e and <leader>E remaps from snacks_explorer extra
pcall(vim.keymap.del, "n", "<leader>e")
pcall(vim.keymap.del, "n", "<leader>E")
vim.keymap.set("n", "<leader>es", function()
  require("snacks").explorer()
end, { desc = "Snacks Explorer (cwd)" })
vim.keymap.set("n", "<leader>eS", function()
  require("snacks").explorer({ cwd = LazyVim.root() })
end, { desc = "Snacks Explorer (root)" })

-- Move Buffers picker under Buffer group
vim.keymap.del("n", "<leader>,")
vim.keymap.set("n", "<leader>bf", function()
  require("snacks").picker.buffers()
end, { desc = "Find Buffers" })

-- Move split commands under Windows group
vim.keymap.del("n", "<leader>-")
vim.keymap.del("n", "<leader>|")
vim.keymap.set("n", "<leader>w-", "<C-W>s", { desc = "Split Window Below", remap = true })
vim.keymap.set("n", "<leader>w|", "<C-W>v", { desc = "Split Window Right", remap = true })
vim.keymap.set("n", "<leader>ww", "<C-W>w", { desc = "Cycle Windows", remap = true })
vim.keymap.set("n", "<leader>wW", "<C-W>p", { desc = "Other Window", remap = true })
vim.keymap.set("n", "<leader>r", "<cmd>checktime<cr>", { desc = "Reload changed files" })
vim.keymap.set("n", "<leader>R", function()
  local init = vim.fn.stdpath("config") .. "/init.lua"
  vim.cmd("source " .. vim.fn.fnameescape(init))
  vim.cmd("redrawstatus!")
  vim.cmd("redraw!")
  vim.notify("Configuration et interface Neovim rechargées", vim.log.levels.INFO)
end, { desc = "Reload Neovim config and UI" })

-- Terminal submenu: open new terminals in horizontal/vertical splits
vim.keymap.set("n", "<leader>th", function()
  vim.cmd("botright split")
  vim.cmd("terminal")
  vim.cmd("wincmd J")
  vim.cmd("startinsert")
end, { desc = " Terminal Horizontal" })

vim.keymap.set("n", "<leader>tv", function()
  vim.cmd("vsplit")
  vim.cmd("terminal")
  vim.cmd("startinsert")
end, { desc = " Terminal Vertical" })

local function switch_to_other_buffer()
  local alt = vim.fn.bufnr("#")
  if alt <= 0 or not vim.api.nvim_buf_is_valid(alt) then
    vim.notify("Aucun buffer alternatif", vim.log.levels.WARN)
    return
  end

  vim.cmd("buffer " .. alt)
end

vim.keymap.set("n", "<leader>bb", switch_to_other_buffer, { desc = "Switch to Other Buffer" })
vim.keymap.del("n", "<leader>`")
vim.keymap.set("n", "<Tab>", "<cmd>bnext<cr>", { desc = "Buffer suivant", silent = true })
vim.keymap.set("n", "<S-Tab>", "<cmd>bprevious<cr>", { desc = "Buffer precedent", silent = true })
vim.keymap.set("i", "<S-Tab>", "<C-d>", { desc = "Desindenter" })
vim.keymap.set("i", "<C-t>", "<Nop>", { desc = "Desactiver indentation" })
vim.keymap.set("i", "<C-d>", "<Nop>", { desc = "Desactiver desindentation" })

-- Espaces de travail : tabs natifs Neovim, dont Scope isole les buffers.
vim.keymap.set("n", "]t", "<cmd>tabnext<cr>", { desc = "Espace suivant", silent = true })
vim.keymap.set("n", "[t", "<cmd>tabprevious<cr>", { desc = "Espace precedent", silent = true })
vim.keymap.set("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "Nouvel espace", silent = true })
vim.keymap.set("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Fermer l'espace", silent = true })
vim.keymap.set("n", "<leader><tab>o", "<cmd>tabonly<cr>", { desc = "Fermer les autres espaces", silent = true })
vim.keymap.set("n", "<leader><tab>j", function()
  local tab_name = require("tabby.feature.tab_name")
  local scope = require("scope.core")
  local spaces = {}

  scope.revalidate()

  for index, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
    table.insert(spaces, {
      index = index,
      tabpage = tabpage,
      name = tab_name.get(tabpage),
      buffer_count = #(scope.cache[tabpage] or {}),
    })
  end

  vim.ui.select(spaces, {
    prompt = "Choisir un espace :",
    format_item = function(space)
      local suffix = space.buffer_count > 1 and "buffers" or "buffer"
      return string.format("%d  %s  (%d %s)", space.index, space.name, space.buffer_count, suffix)
    end,
  }, function(space)
    if space then
      vim.api.nvim_set_current_tabpage(space.tabpage)
    end
  end)
end, { desc = "Choisir un espace" })
vim.keymap.set("n", "<leader><tab>m", "<cmd>ScopeMoveBuf<cr>", { desc = "Deplacer le buffer", silent = true })
vim.keymap.set("n", "<leader><tab>b", "<cmd>Telescope scope buffers<cr>", {
  desc = "Buffers de tous les espaces",
  silent = true,
})
vim.keymap.set("n", "<leader><tab>r", function()
  vim.ui.input({ prompt = "Nom de l'espace : " }, function(name)
    if not name or name == "" then
      return
    end
    require("tabby.feature.tab_name").set(0, name)
  end)
end, { desc = "Renommer l'espace" })

local function sync_workspace_number_keymaps()
  for index = 1, 9 do
    pcall(vim.keymap.del, "n", "<leader><tab>" .. index)
  end

  for index = 1, math.min(#vim.api.nvim_list_tabpages(), 9) do
    vim.keymap.set("n", "<leader><tab>" .. index, function()
      vim.cmd(index .. "tabnext")
    end, {
      desc = "Aller a l'espace " .. index,
      silent = true,
    })
  end
end

sync_workspace_number_keymaps()
vim.api.nvim_create_autocmd({ "TabNewEntered", "TabClosed" }, {
  desc = "Synchroniser les raccourcis des espaces",
  callback = function()
    vim.schedule(sync_workspace_number_keymaps)
  end,
})

local cheat_sheets = {
  {
    label = "Neovim",
    detail = "Cheatsheet privee de la config Neovim",
    path = "~/.dotfiles/nvim/MyNeovim/Cheat Sheet.md",
  },
  {
    label = "Focus Tags",
    detail = "Cheatsheet publique docs/focus-tags-cheatsheet.md",
    path = "~/.dotfiles/docs/focus-tags-cheatsheet.md",
  },
}

local function open_cheat_sheet(sheet)
  local path = vim.fn.expand(sheet.path)
  local target = vim.uv.fs_realpath(path) or vim.fn.fnamemodify(path, ":p")
  local current_name = vim.api.nvim_buf_get_name(0)
  local current = current_name ~= "" and (vim.uv.fs_realpath(current_name) or vim.fn.fnamemodify(current_name, ":p"))
    or ""

  local function close_and_return()
    local buf = vim.api.nvim_get_current_buf()
    local alt = vim.fn.bufnr("#")
    if alt > 0 and alt ~= buf and vim.api.nvim_buf_is_valid(alt) then
      vim.cmd("buffer " .. alt)
    else
      vim.cmd("enew")
    end
    pcall(vim.api.nvim_buf_delete, buf, { force = false })
  end

  if current == target then
    close_and_return()
    return
  end

  vim.cmd("edit " .. vim.fn.fnameescape(path))
  vim.bo.buflisted = false

  local close_desc = "Fermer " .. sheet.label
  vim.keymap.set("n", "q", close_and_return, { buffer = true, desc = close_desc })
  vim.keymap.set("n", "<leader>bd", close_and_return, { buffer = true, desc = close_desc })
  vim.keymap.set("n", "<leader>wd", close_and_return, { buffer = true, desc = close_desc })
end

local function choose_cheat_sheet()
  vim.ui.select(cheat_sheets, {
    prompt = "Cheatsheet",
    format_item = function(item)
      return item.label .. " - " .. item.detail
    end,
  }, function(choice)
    if choice then
      open_cheat_sheet(choice)
    end
  end)
end

vim.keymap.set("n", "<leader>H", choose_cheat_sheet, { desc = "Cheat Sheet" })

require("shipglows").setup()

local copy_current_path = require("shipglows.path").current_buffer
vim.api.nvim_create_user_command("CopyPath", copy_current_path, { desc = "Copier le chemin absolu" })
vim.keymap.set("n", "<leader>yp", copy_current_path, { desc = "Copier le chemin du buffer" })
vim.keymap.set("n", "Y", copy_current_path, { desc = "Copier le chemin du buffer" })

pcall(vim.keymap.del, "n", "<leader>L")

-- Explicit mouse wheel scroll (fixes scroll down through mosh/tmux)
vim.keymap.set({ "n", "v", "x" }, "<ScrollWheelUp>", "3<C-y>", { desc = "Scroll up" })
vim.keymap.set({ "n", "v", "x" }, "<ScrollWheelDown>", "3<C-e>", { desc = "Scroll down" })
vim.keymap.set("i", "<ScrollWheelUp>", "<C-o>3<C-y>", { desc = "Scroll up" })
vim.keymap.set("i", "<ScrollWheelDown>", "<C-o>3<C-e>", { desc = "Scroll down" })

-- Notifications (which-key group)
local copy_to_clipboard = require("shipglows.clipboard").copy
local notifications = require("shipglows.notifications")

vim.keymap.set("n", "<leader>nn", "<cmd>Noice history<cr>", { desc = "Afficher notifications" })

vim.keymap.set("n", "<leader>nc", function()
  local text = notifications.latest()
  if text then
    local result = copy_to_clipboard(text)
    vim.notify("Derniere notification copiee. Sauvegarde : " .. result.fallback_path, "info")
    return
  end
  vim.notify("Aucun message", "warn")
end, { desc = "Copier dernier message" })

vim.keymap.set("n", "<leader>nC", function()
  local text, count = notifications.report()
  if count > 0 then
    local result = copy_to_clipboard(text)
    vim.notify(count .. " messages copies. Sauvegarde : " .. result.fallback_path, "info")
    return
  end
  vim.notify("Aucun message", "warn")
end, { desc = "Copier tous les messages" })

local function open_difftastic()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    vim.notify("Difftastic requires a file-backed buffer", vim.log.levels.WARN)
    return
  end

  local root = vim.fs.root(0, ".git")
  if not root then
    vim.notify("Difftastic requires a git repository", vim.log.levels.WARN)
    return
  end

  local relpath = file:sub(#root + 2)
  if relpath == "" then
    vim.notify("Unable to resolve file path relative to git root", vim.log.levels.WARN)
    return
  end

  local head = vim.system({ "git", "-C", root, "show", ("HEAD:%s"):format(relpath) }, { text = true }):wait()
  if head.code ~= 0 then
    vim.notify(("Unable to read HEAD version for %s"):format(relpath), vim.log.levels.WARN)
    return
  end

  if vim.fn.executable("difft") ~= 1 then
    vim.notify("difft is not installed", vim.log.levels.ERROR)
    return
  end

  local tmp = vim.fn.tempname()
  vim.fn.writefile(vim.split(head.stdout or "", "\n", { plain = true }), tmp)

  vim.cmd("botright split")
  vim.cmd(("terminal difft --color=always %s %s"):format(vim.fn.shellescape(tmp), vim.fn.shellescape(file)))
  vim.cmd("startinsert")
end

vim.api.nvim_create_user_command("Difftastic", open_difftastic, {})
vim.keymap.set("n", "<leader>gt", open_difftastic, { desc = "Difftastic diff current file" })

-- Front matter folding shortcut in same namespace as fold commands (z...)
local function get_front_matter_end()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  if lines[1] ~= "---" then
    return nil
  end

  for lnum = 2, #lines do
    if lines[lnum] == "---" then
      return lnum
    end
  end

  return nil
end

function _G.__fm_foldexpr(lnum)
  local end_fm = vim.b.front_matter_end_line
  local first_line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
  local prev_expr = vim.b.fm_prev_foldexpr

  local function fallback_fold_expr()
    if prev_expr and prev_expr ~= "" and prev_expr ~= "v:lua.__fm_foldexpr(v:lnum)" then
      vim.v.lnum = lnum
      local ok, res = pcall(vim.api.nvim_eval, prev_expr)
      if ok and res ~= nil then
        return res
      end
    end
    if vim.treesitter and vim.treesitter.foldexpr then
      vim.v.lnum = lnum
      local ok, res = pcall(vim.treesitter.foldexpr)
      return ok and res or "="
    end
    return "="
  end

  if first_line ~= "---" or not end_fm then
    return fallback_fold_expr()
  end

  if lnum == 1 then
    return "a1"
  elseif lnum < end_fm then
    return "1"
  elseif lnum == end_fm then
    return "s1"
  end

  return fallback_fold_expr()
end

local function fold_front_matter()
  local end_fm = get_front_matter_end()
  vim.b.front_matter_end_line = end_fm
  vim.b.fm_prev_foldexpr = vim.wo.foldexpr

  if not end_fm then
    vim.notify("Pas de front matter détectable (--- ... ---) en tête de fichier", vim.log.levels.INFO)
    return
  end

  vim.wo.foldmethod = "expr"
  vim.wo.foldexpr = "v:lua.__fm_foldexpr(v:lnum)"

  local cur = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_win_set_cursor(0, { 1, 0 })

  if vim.fn.foldclosed(1) == 1 then
    vim.cmd("normal! zo")
  else
    vim.cmd("normal! zc")
  end

  vim.api.nvim_win_set_cursor(0, cur)
end

vim.api.nvim_create_user_command("FoldFrontMatter", fold_front_matter, {
  desc = "Toggle fold front matter (--- ... ---)",
})

pcall(vim.keymap.del, "n", "zF")
vim.keymap.set("n", "zF", "<cmd>FoldFrontMatter<cr>", {
  desc = "Fold front matter",
  silent = true,
  nowait = true,
})
