local user_root_dir = vim.fs.normalize((vim.uv.os_homedir() or vim.env.HOME or vim.fn.expand("~")))
local launch_dir = vim.fn.getcwd()
local explorer_panel = require("config.explorer-panel")

local function resolve_root_dir()
  return user_root_dir
end

return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  cmd = "Neotree",
  keys = {
    {
      "<leader>ec",
      function()
        require("config.neotree-smart").open("filesystem", launch_dir)
      end,
      desc = "NeoTree (cwd)",
    },
    {
      "<leader>er",
      function()
        require("config.neotree-smart").open("filesystem", resolve_root_dir())
      end,
      desc = "NeoTree (root)",
    },
    {
      "<leader>eb",
      function()
        require("config.neotree-smart").open("buffers")
      end,
      desc = "NeoTree (buffers)",
    },
    {
      "<leader>ee",
      function()
        require("config.neotree-smart").toggle()
      end,
      desc = "NeoTree (toggle)",
    },
    {
      "<leader>eg",
      function()
        require("config.neotree-smart").open("git_status")
      end,
      desc = "NeoTree (git)",
    },
  },
  opts = function()
    local dir_git_cache = {}

    local function collapse_or_close_tree(state)
      local tree = state.tree
      local node = tree and tree:get_node()
      local root = tree and tree:get_nodes()[1]
      if not node or not root then
        return
      end

      if node:get_id() == root:get_id() then
        require("neo-tree.command").execute({ source = state.name, action = "close" })
        return
      end

      if not (node:has_children() and node:is_expanded()) then
        local parent = tree:get_node(node:get_parent_id())
        if parent and parent:get_id() == root:get_id() then
          require("neo-tree.ui.renderer").focus_node(state, root:get_id())
          return
        end
      end

      require("neo-tree.sources.common.commands").close_node(state)
    end

    local function normalize_status(status)
      if type(status) == "table" then
        return status[1]
      end
      return status
    end

    local function mark_parent_dirs(git_root, git_status)
      local cache = {}

      for changed_path, raw_status in pairs(git_status or {}) do
        if type(changed_path) == "string" then
          local status = normalize_status(raw_status)
          if status and status ~= "!" then
            local marker = status == "?" and "?" or "*"
            local current = changed_path

            while true do
              local parent = vim.fs.dirname(current)
              if not parent or parent == current or #parent < #git_root then
                break
              end

              local existing = cache[parent]
              if existing ~= "?" then
                cache[parent] = marker
              end
              current = parent
            end
          end
        end
      end

      dir_git_cache[git_root] = cache
    end

    local function contained_git_status(_, node)
      if node.type ~= "directory" then
        return {}
      end

      local git = require("neo-tree.git")
      local path = node.path or node:get_id()
      local git_root = git.find_existing_worktree(path)
      if not git_root then
        return {}
      end

      local marker = dir_git_cache[git_root] and dir_git_cache[git_root][path] or nil
      if not marker then
        return {}
      end

      return {
        text = marker .. " ",
        highlight = marker == "?" and "NeoTreeGitUntracked" or "NeoTreeGitModified",
      }
    end

    return {
      close_if_last_window = true,
      popup_border_style = "rounded",
      enable_git_status = true,
      enable_diagnostics = true,
      sources = { "filesystem", "buffers", "git_status", "document_symbols" },
      event_handlers = {
        {
          event = "git_status_changed",
          handler = function(args)
            mark_parent_dirs(args.git_root, args.git_status)
          end,
        },
      },
      filesystem = {
        bind_to_cwd = false,
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = false,
        hijack_netrw_behavior = "open_default",
        window = {
          mappings = {
            ["l"] = "open",
            ["Y"] = function(state)
              local node = state.tree:get_node()
              require("shipglows.path").copy(node and node.path)
            end,
          },
        },
        components = {
          contained_git_status = contained_git_status,
        },
        renderers = {
          file = {
            { "indent" },
            {
              "container",
              content = {
                { "name", zindex = 10 },
                { "clipboard", zindex = 10 },
                { "diagnostics", errors_only = true, zindex = 20, align = "right" },
                { "git_status", zindex = 10, align = "right" },
              },
            },
          },
          directory = {
            { "indent" },
            {
              "container",
              content = {
                { "contained_git_status", zindex = 15 },
                { "name", zindex = 10 },
                { "clipboard", zindex = 10 },
                { "diagnostics", errors_only = true, zindex = 20, align = "right", hide_when_expanded = true },
                { "git_status", zindex = 10, align = "right", hide_when_expanded = true },
              },
            },
          },
        },
      },
      document_symbols = {
        window = {
          mappings = {
            ["h"] = "close_node",
            ["l"] = "toggle_node",
            ["Z"] = "expand_all_nodes",
          },
        },
      },
      window = {
        position = "left",
        width = explorer_panel.width,
        mappings = {
          ["<space>"] = "none",
          ["<esc>"] = collapse_or_close_tree,
          ["l"] = "open",
          ["h"] = "close_node",
          ["<c-f>"] = function(state)
            local node = state.tree:get_node()
            local path = node and (node.type == "directory" and node.path or vim.fs.dirname(node.path))
              or vim.fn.getcwd()
            require("snacks").picker.files({ cwd = path })
          end,
          ["<c-g>"] = function(state)
            local node = state.tree:get_node()
            local path = node and (node.type == "directory" and node.path or vim.fs.dirname(node.path))
              or vim.fn.getcwd()
            require("snacks").picker.grep({ cwd = path })
          end,
        },
      },
      default_component_configs = {
        indent = {
          with_expanders = true,
          expander_collapsed = "+",
          expander_expanded = "-",
          expander_highlight = "NeoTreeExpander",
        },
        icon = {
          folder_closed = "+",
          folder_open = "-",
          folder_empty = ".",
          default = " ",
        },
        git_status = {
          symbols = {
            added = "A",
            modified = "M",
            deleted = "D",
            renamed = "R",
            untracked = "?",
            ignored = "!",
            unstaged = "U",
            staged = "S",
            conflict = "C",
          },
        },
      },
    }
  end,
}
