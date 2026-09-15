local M = {}
local explorer_panel = require("config.explorer-panel")

local SOURCES = { "filesystem", "buffers", "git_status", "document_symbols" }
local last_source = "filesystem"

local function active_state()
  local mgr_ok, manager = pcall(require, "neo-tree.sources.manager")
  local rdr_ok, renderer = pcall(require, "neo-tree.ui.renderer")
  if not mgr_ok or not rdr_ok then
    return nil, nil
  end
  for _, source in ipairs(SOURCES) do
    local state = manager.get_state(source)
    if state and renderer.window_exists(state) then
      return source, state
    end
  end
  return nil, nil
end

function M.toggle()
  local active_source, state = active_state()
  if active_source and state then
    require("neo-tree.command").execute({ source = active_source, action = "close" })
    return
  end

  local cmd_ok, cmd = pcall(require, "neo-tree.command")
  if not cmd_ok then
    vim.cmd("Neotree " .. last_source)
    return
  end
  cmd.execute({ source = last_source, position = "left" })
  vim.schedule(function()
    local _, opened_state = active_state()
    if opened_state then
      explorer_panel.resize(opened_state.winid)
    end
  end)
end

function M.open(target_source, target_dir)
  last_source = target_source
  local cmd_ok, cmd = pcall(require, "neo-tree.command")
  if not cmd_ok then
    vim.cmd("Neotree")
    return
  end

  local active_source, state = active_state()
  local same = active_source == target_source
  if same and target_dir and state and state.path then
    same = vim.fs.normalize(state.path) == vim.fs.normalize(target_dir)
  end

  if same then
    cmd.execute({ source = target_source, action = "close" })
    return
  end

  cmd.execute({ source = target_source, dir = target_dir, position = "left" })
  vim.schedule(function()
    local _, opened_state = active_state()
    if opened_state then
      explorer_panel.resize(opened_state.winid)
    end
  end)
end

return M
