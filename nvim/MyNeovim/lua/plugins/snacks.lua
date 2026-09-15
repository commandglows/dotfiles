local explorer_panel = require("config.explorer-panel")

local function normalize_dir(path)
  if not path or path == "" then
    return nil
  end
  return vim.fs.normalize(path)
end

local function directory_exists(path)
  local stat = path and vim.uv.fs_stat(path) or nil
  return stat and stat.type == "directory" or false
end

local function gather_project_directories(root)
  root = normalize_dir(root)
  if not directory_exists(root) then
    return {}
  end

  local seen = { [root] = true }
  local results = {
    {
      text = ".",
      path = root,
    },
  }
  local ignored = {
    [".git"] = true,
    ["node_modules"] = true,
    ["dist"] = true,
    ["build"] = true,
    [".next"] = true,
    ["coverage"] = true,
    ["__pycache__"] = true,
  }

  local queue = { { path = root, depth = 0 } }
  local max_depth = 4
  local max_dirs = 300
  local idx = 1

  while idx <= #queue and #results < max_dirs do
    local current = queue[idx]
    idx = idx + 1

    if current.depth < max_depth then
      for name, entry_type in vim.fs.dir(current.path) do
        if entry_type == "directory" and not ignored[name] then
          local full = normalize_dir(current.path .. "/" .. name)
          if full and not seen[full] then
            seen[full] = true
            results[#results + 1] = {
              text = vim.fs.relpath(root, full) or name,
              path = full,
            }
            queue[#queue + 1] = { path = full, depth = current.depth + 1 }
            if #results >= max_dirs then
              break
            end
          end
        end
      end
    end
  end

  table.sort(results, function(a, b)
    return a.text < b.text
  end)

  return results
end

local function grep_in_selected_directory()
  local root = normalize_dir(LazyVim.root()) or normalize_dir(vim.fn.getcwd())
  local cwd = normalize_dir(vim.fn.getcwd())
  local file_dir = normalize_dir(vim.fn.expand("%:p:h"))
  local items = gather_project_directories(root)

  local function add_priority_dir(path, label)
    path = normalize_dir(path)
    if not directory_exists(path) then
      return
    end
    for _, item in ipairs(items) do
      if item.path == path then
        item.text = label
        return
      end
    end
    items[#items + 1] = { text = label, path = path }
  end

  add_priority_dir(cwd, ". (cwd)")
  add_priority_dir(root, "/ (root)")
  if file_dir and file_dir ~= cwd and file_dir ~= root then
    add_priority_dir(file_dir, "%:h (file dir)")
  end

  table.sort(items, function(a, b)
    return a.text < b.text
  end)

  vim.ui.select(items, {
    prompt = "Grep in directory",
    format_item = function(item)
      return item.text
    end,
  }, function(choice)
    if not choice or not choice.path then
      return
    end
    Snacks.picker.grep({ cwd = choice.path })
  end)
end

return {
  "folke/snacks.nvim",
  enabled = true,
  priority = 1000,
  lazy = false,
  keys = {
    { "<leader>ff", LazyVim.pick("files", { root = false }), desc = "Find Files (cwd)" },
    { "<leader>fF", LazyVim.pick("files"), desc = "Find Files (root dir)" },
    { "<leader>fe", function() Snacks.explorer() end, desc = "Explorer Snacks (cwd)" },
    { "<leader>fE", function() Snacks.explorer({ cwd = LazyVim.root() }) end, desc = "Explorer Snacks (root dir)" },
    { "<leader>fr", function() Snacks.picker.recent({ filter = { cwd = true } }) end, desc = "Recent (cwd)" },
    { "<leader>fR", LazyVim.pick("oldfiles"), desc = "Recent (root dir)" },
    { "<leader>ft", function() Snacks.terminal() end, desc = "Terminal (cwd)" },
    { "<leader>fT", function() Snacks.terminal(nil, { cwd = LazyVim.root() }) end, desc = "Terminal (root dir)" },
    { "<leader>gD", function() Snacks.picker.git_diff({ base = "origin", group = true }) end, desc = "Git Diff Origin" },
    { "<leader>sg", LazyVim.pick("live_grep", { root = false }), desc = "Grep (cwd)" },
    { "<leader>sd", grep_in_selected_directory, desc = "Grep (pick dir)" },
    { "<leader>sw", LazyVim.pick("grep_word", { root = false }), mode = { "n", "x" }, desc = "Visual selection or word (cwd)" },
    { "<leader>sW", LazyVim.pick("grep_word"), mode = { "n", "x" }, desc = "Visual selection or word (root dir)" },
  },
  init = function()
    -- LazyVim references the global `Snacks` while resolving other plugin opts.
    if not _G.Snacks then
      _G.Snacks = require("snacks")
    end

    vim.api.nvim_create_autocmd("VimEnter", {
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
  end,
  opts = {
    bigfile = { enabled = true },
    dashboard = { enabled = false },
    explorer = {
      enabled = true,
      win = {
        list = {
          keys = {
            ["Y"] = function(picker)
              local item = picker:current()
              require("shipglows.path").copy(item and (item.file or item.path))
            end,
          },
        },
      },
    },
    indent = { enabled = true },
    input = { enabled = true },
    notifier = { enabled = false }, -- using nvim-notify
    picker = {
      icons = {
        files = {
          enabled = false,
        },
        git = {
          enabled = false,
        },
      },
      sources = {
        git_diff = {
          focus = "list",
          layout = {
            fullscreen = true,
            layout = {
              box = "vertical",
              border = true,
              title = "{title} {live} {flags}",
              title_pos = "center",
              { win = "input", height = 1, border = "bottom" },
              { win = "list", height = 3, border = "none" },
              { win = "preview", title = "{preview}", border = "top" },
            },
          },
          win = {
            input = {
              keys = {
                ["<Tab>"] = { "focus_list", mode = { "i", "n" } },
                ["<S-Tab>"] = { "focus_preview", mode = { "i", "n" } },
                ["<Down>"] = { "preview_scroll_down", mode = { "i", "n" } },
                ["<Up>"] = { "preview_scroll_up", mode = { "i", "n" } },
              },
            },
            list = {
              keys = {
                ["<Tab>"] = "list_down",
                ["<S-Tab>"] = "list_up",
                ["<Down>"] = "preview_scroll_down",
                ["<Up>"] = "preview_scroll_up",
              },
            },
            preview = {
              keys = {
                ["<Tab>"] = "list_down",
                ["<S-Tab>"] = "list_up",
                ["<Down>"] = "preview_scroll_down",
                ["<Up>"] = "preview_scroll_up",
                ["j"] = "preview_scroll_down",
                ["k"] = "preview_scroll_up",
              },
            },
          },
        },
        explorer = {
          git_status = true,
          git_status_open = true,
          git_untracked = true,
          diagnostics = true,
          follow_file = true,
          layout = function()
            return explorer_panel.snacks_layout()
          end,
          win = {
            list = {
              keys = {
                ["<Esc>"] = "explorer_close",
                ["<c-f>"] = "picker_files",
                ["<c-g>"] = "picker_grep",
              },
            },
          },
          format = function(item, picker)
            local fmt = require("snacks.picker.format")
            local git = require("snacks.picker.source.git")
            local ret = {}

            if item.label then
              ret[#ret + 1] = { item.label, "SnacksPickerLabel" }
              ret[#ret + 1] = { " ", virtual = true }
            end

            if item.parent then
              vim.list_extend(ret, fmt.tree(item, picker))
            end

            if item.status then
              local status = git.git_status(item.status)
              local hl = "SnacksPickerGitStatus"
              if status.unmerged then
                hl = "SnacksPickerGitStatusUnmerged"
              elseif status.staged then
                hl = "SnacksPickerGitStatusStaged"
              else
                hl = "SnacksPickerGitStatus" .. status.status:sub(1, 1):upper() .. status.status:sub(2)
              end

              local icon = status.status:sub(1, 1):upper()
              icon = status.status == "untracked" and "?" or status.status == "ignored" and "!" or icon
              if picker.opts.icons.git.enabled then
                icon = picker.opts.icons.git[status.unmerged and "unmerged" or status.status] or icon
                if status.staged then
                  icon = picker.opts.icons.git.staged
                end
              end

              ret[#ret + 1] = { icon .. " ", hl }
            end

            if item.severity then
              vim.list_extend(ret, fmt.severity(item, picker))
            end

            vim.list_extend(ret, fmt.filename(item, picker))

            if item.comment then
              ret[#ret + 1] = { item.comment, "SnacksPickerComment" }
              ret[#ret + 1] = { " " }
            end

            return ret
          end,
        },
      },
    },
    quickfile = { enabled = true },
    scroll = { enabled = false }, -- using neoscroll
    statuscolumn = { enabled = false },
    words = { enabled = true },
  },
  config = function(_, opts)
    require("snacks").setup(opts)
    vim.api.nvim_set_hl(0, "SnacksPickerGitStatusModified", { fg = "#ff9e3b", bold = true })
    vim.api.nvim_set_hl(0, "SnacksPickerGitStatusAdded", { fg = "#98bb6c", bold = true })
    vim.api.nvim_set_hl(0, "SnacksPickerGitStatusDeleted", { fg = "#e46876", bold = true })
    vim.api.nvim_set_hl(0, "SnacksPickerGitStatusUntracked", { fg = "#7fb4ca", bold = true })
    vim.api.nvim_set_hl(0, "SnacksPickerGitStatusIgnored", { fg = "#727169" })
    vim.api.nvim_set_hl(0, "SnacksPickerGitStatusStaged", { fg = "#7aa89f", bold = true })
    vim.api.nvim_set_hl(0, "SnacksPickerGitStatusUnmerged", { fg = "#e46876", bold = true })
  end,
}
