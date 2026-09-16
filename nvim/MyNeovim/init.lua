-- bootstrap lazy.nvim, LazyVim and your plugins
vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("myneovim_start_workspace", { clear = true }),
  callback = function()
    if vim.fn.argc() ~= 0 then
      return
    end

    local listed_file_buffers = vim.tbl_filter(function(buf)
      if not vim.api.nvim_buf_is_valid(buf) or vim.fn.buflisted(buf) ~= 1 then
        return false
      end
      if vim.bo[buf].buftype ~= "" then
        return false
      end
      return vim.api.nvim_buf_get_name(buf) ~= ""
    end, vim.api.nvim_list_bufs())

    if #listed_file_buffers > 0 then
      return
    end

    local current_buf = vim.api.nvim_get_current_buf()
    if vim.bo[current_buf].modified or vim.api.nvim_buf_get_name(current_buf) ~= "" then
      return
    end

    vim.schedule(function()
      require("config.neotree-smart").open("filesystem", vim.fn.getcwd())
    end)
  end,
})

require("config.lazy")
