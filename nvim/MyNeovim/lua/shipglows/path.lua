local M = {}

local function absolute(path)
  if not path or path == "" then
    return nil
  end

  return vim.uv.fs_realpath(path) or vim.fn.fnamemodify(path, ":p")
end

function M.copy(path)
  path = absolute(path)
  if not path then
    vim.notify("Aucun chemin a copier", vim.log.levels.WARN)
    return
  end

  require("shipglows.clipboard").copy(path)
  vim.notify("Chemin copie : " .. path, vim.log.levels.INFO)
end

function M.current_buffer()
  M.copy(vim.api.nvim_buf_get_name(0))
end

return M
