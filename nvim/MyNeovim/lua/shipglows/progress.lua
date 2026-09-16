local M = {}

local tasks = {}
local saved_winbars = {}
local sequence = 0
local overlay = "%{%v:lua.require'shipglows.progress'.winbar()%}"
local spinners = {
  "\226\160\139",
  "\226\160\153",
  "\226\160\185",
  "\226\160\184",
  "\226\160\188",
  "\226\160\180",
  "\226\160\166",
  "\226\160\167",
}

local function applies_to_buffer(task, buf)
  return not task.bufnr and not task.bufnrs or task.bufnr == buf or (task.bufnrs and task.bufnrs[buf])
end

local function redraw()
  vim.cmd("redrawstatus")
end

local function eligible_windows(task)
  local wins = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_win_is_valid(win) and applies_to_buffer(task, buf) then
      table.insert(wins, win)
    end
  end
  return wins
end

local function apply(task)
  for _, win in ipairs(eligible_windows(task)) do
    if saved_winbars[win] == nil then
      saved_winbars[win] = vim.api.nvim_get_option_value("winbar", { win = win })
    end
    vim.api.nvim_set_option_value("winbar", overlay, { win = win })
  end
  redraw()
end

local function restore_unused_windows()
  for win, original in pairs(saved_winbars) do
    if not vim.api.nvim_win_is_valid(win) then
      saved_winbars[win] = nil
    else
      local needed = false
      local buf = vim.api.nvim_win_get_buf(win)
      for _, task in pairs(tasks) do
        if applies_to_buffer(task, buf) then
          needed = true
          break
        end
      end
      if not needed then
        if vim.api.nvim_get_option_value("winbar", { win = win }) == overlay then
          vim.api.nvim_set_option_value("winbar", original, { win = win })
        end
        saved_winbars[win] = nil
      end
    end
  end
  redraw()
end

local function normalize_percentage(value)
  if type(value) ~= "number" then
    return nil
  end
  return math.max(0, math.min(100, math.floor(value + 0.5)))
end

local function latest_for_window(win)
  local buf = vim.api.nvim_win_get_buf(win)
  local latest
  for _, task in pairs(tasks) do
    if applies_to_buffer(task, buf) and (not latest or task.sequence > latest.sequence) then
      latest = task
    end
  end
  return latest
end

local function bar(percentage)
  if not percentage then
    return spinners[(math.floor(vim.uv.hrtime() / 1e8) % #spinners) + 1]
  end
  local width = 10
  local filled = math.floor((percentage * width / 100) + 0.5)
  return string.rep("\226\150\136", filled) .. string.rep("\226\150\145", width - filled)
end

function M.winbar()
  local win = tonumber(vim.g.statusline_winid) or vim.api.nvim_get_current_win()
  local task = latest_for_window(win)
  if not task then
    return ""
  end
  local suffix = task.percentage and string.format("  %d %%", task.percentage) or ""
  local detail = task.message and task.message ~= "" and (" \194\183 " .. task.message) or ""
  return string.format(
    " %%#DiagnosticInfo#\239\128\147 %s%%*  %s%s%s ",
    task.label,
    bar(task.percentage),
    suffix,
    detail
  )
end

function M.start(id, opts)
  opts = opts or {}
  if tasks[id] then
    tasks[id] = nil
    restore_unused_windows()
  end
  sequence = sequence + 1
  tasks[id] = {
    label = opts.label or "T\195\162che en cours",
    message = opts.message,
    percentage = normalize_percentage(opts.percentage),
    bufnr = opts.bufnr,
    bufnrs = opts.bufnrs,
    sequence = sequence,
  }
  apply(tasks[id])
end

function M.update(id, opts)
  local task = tasks[id]
  if not task then
    return
  end
  opts = opts or {}
  if opts.label ~= nil then
    task.label = opts.label
  end
  if opts.message ~= nil then
    task.message = opts.message
  end
  if opts.percentage ~= nil then
    task.percentage = normalize_percentage(opts.percentage)
  end
  sequence = sequence + 1
  task.sequence = sequence
  apply(task)
end

function M.finish(id)
  tasks[id] = nil
  restore_unused_windows()
end

function M.handle_lsp_progress(event)
  local data = event.data or {}
  local value = data.params and data.params.value or {}
  local client = data.client_id and vim.lsp.get_client_by_id(data.client_id) or nil
  local id = "lsp:" .. tostring(data.client_id or "inconnu") .. ":" .. tostring(data.params and data.params.token or "")
  local label = value.title or (client and client.name) or "LSP"
  if client and value.title then
    label = client.name .. " \194\183 " .. value.title
  end
  local bufnrs = client and client.attached_buffers or nil

  if value.kind == "end" then
    M.finish(id)
  elseif value.kind == "begin" then
    M.start(id, { label = label, message = value.message, percentage = value.percentage, bufnrs = bufnrs })
  else
    M.update(id, { label = label, message = value.message, percentage = value.percentage })
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("ShipGlowsWinbarProgress", { clear = true })
  vim.api.nvim_create_autocmd("LspProgress", {
    group = group,
    desc = "Afficher la progression LSP dans la winbar",
    callback = M.handle_lsp_progress,
  })
  vim.api.nvim_create_autocmd("WinEnter", {
    group = group,
    desc = "Prolonger la progression active aux nouvelles fenetres",
    callback = function()
      local win = vim.api.nvim_get_current_win()
      local task = latest_for_window(win)
      if task then
        apply(task)
      end
    end,
  })
end

return M
