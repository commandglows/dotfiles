-- ShipGlows Plugin for NeoVim
-- This plugin allows navigation between Markdown headers using customizable shortcuts.

local M = {}

local function search_headings(levels, backward)
  local sorted_levels = {}
  for _, level in ipairs(levels) do
    sorted_levels[level] = true
  end

  local pattern_parts = {}
  for level in pairs(sorted_levels) do
    table.insert(pattern_parts, "^" .. string.rep("#", level) .. "\\s")
  end
  table.sort(pattern_parts)
  local pattern = table.concat(pattern_parts, "\\|")

  local flags = "W"
  if backward then
    flags = "bW"
  end

  local count = vim.v.count > 0 and vim.v.count or 1
  local found = 0
  for _ = 1, count do
    found = vim.fn.search(pattern, flags)
    if found == 0 then
      break
    end
  end

  if found == 0 then
    local label = table.concat(levels, ",")
    local direction = backward and "précédent" or "suivant"
    local plural = (count > 1) and "s" or ""
    vim.notify("Aucun titre H" .. label .. " " .. direction .. " (x" .. count .. ")" .. plural)
  end
end

function M.search_headings(levels, backward)
  search_headings(levels, backward)
end

local function set_panel_preset(preset)
  require("config.panel-resize").preset(preset)
end

M.setup = function()
  require("shipglows.progress").setup()

  local heading_modes = { "x" }
  local function setup_heading_keymaps(buf)
    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { desc = desc, noremap = true, silent = true, buffer = buf })
    end

    map("x", "n", function()
      search_headings({ 2, 3 })
    end, "Next heading H2/H3")

    map("x", "p", function()
      search_headings({ 2, 3 }, true)
    end, "Previous heading H2/H3")

    map(heading_modes, "]h", function()
      search_headings({ 2, 3 })
    end, "Next heading H2/H3")

    map(heading_modes, "[h", function()
      search_headings({ 2, 3 }, true)
    end, "Previous heading H2/H3")
  end

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    callback = function(ev)
      setup_heading_keymaps(ev.buf)
    end,
  })

  vim.api.nvim_create_user_command("ShipGlowsPanel1", function()
    set_panel_preset(1)
  end, { desc = "Set current panel size 1", force = true })

  vim.api.nvim_create_user_command("ShipGlowsPanel2", function()
    set_panel_preset(2)
  end, { desc = "Set current panel size 2", force = true })

  vim.api.nvim_create_user_command("ShipGlowsPanel3", function()
    set_panel_preset(3)
  end, { desc = "Set current panel size 3", force = true })

  vim.api.nvim_create_user_command("ShipGlowsPanelFull", function()
    set_panel_preset("full")
  end, { desc = "Set current panel full size", force = true })

  vim.keymap.set("n", "<leader>w1", "<cmd>ShipGlowsPanel1<cr>", { desc = "panel size 1" })
  vim.keymap.set("n", "<leader>w2", "<cmd>ShipGlowsPanel2<cr>", { desc = "panel size 2" })
  vim.keymap.set("n", "<leader>w3", "<cmd>ShipGlowsPanel3<cr>", { desc = "panel size 3" })
  vim.keymap.set("n", "<leader>wF", "<cmd>ShipGlowsPanelFull<cr>", { desc = "panel full size" })
  vim.keymap.set("t", "<leader>w1", "<C-\\><C-n><cmd>ShipGlowsPanel1<cr>", { desc = "panel size 1" })
  vim.keymap.set("t", "<leader>w2", "<C-\\><C-n><cmd>ShipGlowsPanel2<cr>", { desc = "panel size 2" })
  vim.keymap.set("t", "<leader>w3", "<C-\\><C-n><cmd>ShipGlowsPanel3<cr>", { desc = "panel size 3" })
  vim.keymap.set("t", "<leader>wF", "<C-\\><C-n><cmd>ShipGlowsPanelFull<cr>", { desc = "panel full size" })

  require("shipglows.mail").setup()
end

return M
