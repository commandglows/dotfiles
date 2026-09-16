-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
pcall(vim.api.nvim_del_augroup_by_name, "lazyvim_wrap_spell")

local reload_changed_files_group = vim.api.nvim_create_augroup("reload_changed_files", { clear = true })

vim.api.nvim_create_autocmd({ "WinEnter", "CursorHold" }, {
  group = reload_changed_files_group,
  desc = "Reload files changed outside Neovim",
  callback = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local name = vim.api.nvim_buf_get_name(bufnr)
    if name == "" then
      return
    end
    local stat = vim.uv.fs_stat(name)
    if stat and stat.type == "file" then
      vim.schedule(function()
        if vim.api.nvim_get_current_buf() == bufnr then
          vim.cmd("checktime")
        end
      end)
    end
  end,
})

local function markdown_heading_level(line)
  local hashes = line:match("^(#+)%s")
  if not hashes then
    return 0
  end
  return #hashes
end

local function markdown_is_h1(line_num)
  local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1] or ""
  return markdown_heading_level(line) == 1
end

local function markdown_heading_line_at_or_before_cursor(line_num)
  for ln = line_num, 1, -1 do
    local line = vim.api.nvim_buf_get_lines(0, ln - 1, ln, false)[1] or ""
    if markdown_heading_level(line) > 0 then
      return ln
    end
  end
  return 0
end

local function markdown_toggle_global_fold_except_h1()
  local folded = vim.b.shipglows_fold_except_h1_only or false
  if folded then
    vim.cmd("normal! zR")
    vim.wo.foldlevel = 99
    vim.opt_global.foldlevelstart = 99
  else
    vim.cmd("normal! zM")
    vim.wo.foldlevel = 1
    vim.opt_global.foldlevelstart = 1
  end
  vim.b.shipglows_fold_except_h1_only = not folded
end

local function markdown_toggle_current_heading_fold()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local heading_line = markdown_heading_line_at_or_before_cursor(cursor[1])
  if heading_line == 0 then
    local next_heading = vim.fn.search("^#+\\s", "nW")
    if next_heading ~= 0 then
      heading_line = next_heading
    else
      vim.notify("Aucun titre dans ce document")
      return
    end
  end

  if heading_line == 0 then
    vim.notify("Aucun titre dans ce document")
    return
  end

  local saved_col = cursor[2]
  vim.api.nvim_win_set_cursor(0, { heading_line, 0 })

  local is_closed = vim.fn.foldclosed(".") ~= -1
  if is_closed then
    vim.cmd("normal! zO")
  else
    vim.cmd("normal! zC")
  end

  vim.api.nvim_win_set_cursor(0, { cursor[1], saved_col })
end

local function markdown_set_h1_fold_policy()
  vim.wo.foldlevel = 1
  vim.opt_global.foldlevelstart = 1
  vim.wo.foldmethod = vim.wo.foldmethod ~= "manual" and vim.wo.foldmethod or "indent"

  local heading_fold_modes = { "n", "x" }

  vim.keymap.set("n", "zM", function()
    vim.cmd("normal! zM")
    vim.wo.foldlevel = 1
  end, { buffer = true, desc = "Close all folds (keep H1 open)" })

  vim.keymap.set(heading_fold_modes, "zm", function()
    if vim.wo.foldlevel <= 1 then
      vim.wo.foldlevel = 1
    else
      vim.cmd("normal! zm")
    end
  end, { buffer = true, desc = "Fold one more level (keep H1 open)" })

  vim.keymap.set(heading_fold_modes, "zc", function()
    local line = vim.api.nvim_win_get_cursor(0)[1]
    if markdown_is_h1(line) then
      vim.wo.foldlevel = 1
      return
    end
    vim.cmd("normal! zc")
  end, { buffer = true, desc = "Close fold under cursor (skip H1)" })

  vim.keymap.set(heading_fold_modes, "z2", function()
    vim.wo.foldlevel = 2
    vim.opt_global.foldlevelstart = 2
  end, { buffer = true, desc = "Fold below H2 (keep H1/H2 visible)" })

  vim.keymap.set(heading_fold_modes, "z3", function()
    vim.wo.foldlevel = 3
    vim.opt_global.foldlevelstart = 3
  end, { buffer = true, desc = "Fold below H3 (keep H1/H2/H3 visible)" })

  vim.keymap.set(heading_fold_modes, "Z3", function()
    vim.wo.foldlevel = 3
    vim.opt_global.foldlevelstart = 3
  end, { buffer = true, desc = "Fold below H3 (keep H1/H2/H3 visible)" })

  vim.keymap.set(heading_fold_modes, "z4", function()
    vim.wo.foldlevel = 4
    vim.opt_global.foldlevelstart = 4
  end, { buffer = true, desc = "Fold below H4 (keep H1/H2/H3/H4 visible)" })

  vim.keymap.set(heading_fold_modes, "Z4", function()
    vim.wo.foldlevel = 4
    vim.opt_global.foldlevelstart = 4
  end, { buffer = true, desc = "Fold below H4 (keep H1/H2/H3/H4 visible)" })

  vim.keymap.set(heading_fold_modes, "z5", function()
    vim.wo.foldlevel = 5
    vim.opt_global.foldlevelstart = 5
  end, { buffer = true, desc = "Fold below H5 (keep H1/H2/H3/H4/H5 visible)" })

  vim.keymap.set(heading_fold_modes, "Z5", function()
    vim.wo.foldlevel = 5
    vim.opt_global.foldlevelstart = 5
  end, { buffer = true, desc = "Fold below H5 (keep H1/H2/H3/H4/H5 visible)" })

  vim.keymap.set(heading_fold_modes, "zh", function()
    require("shipglows").search_headings({ 1, 2, 3, 4, 5, 6 })
  end, { buffer = true, desc = "Next heading (any level)" })

  vim.keymap.set(heading_fold_modes, "za", function()
    local line = vim.api.nvim_win_get_cursor(0)[1]
    if markdown_is_h1(line) then
      vim.wo.foldlevel = 1
      return
    end
    vim.cmd("normal! za")
  end, { buffer = true, desc = "Toggle fold under cursor (skip H1)" })

  vim.keymap.set("x", "q", function()
    markdown_toggle_global_fold_except_h1()
  end, { buffer = true, desc = "Toggle fold all except H1 / unfold all" })

  vim.keymap.set("x", "r", function()
    markdown_toggle_current_heading_fold()
  end, { buffer = true, desc = "Toggle current section fold (any heading level)" })
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    markdown_set_h1_fold_policy()
  end,
})

vim.api.nvim_create_autocmd({ "ModeChanged" }, {
  pattern = "*",
  callback = function()
    require("shipglows.ui_mode").apply_mode_colors()
  end,
})
