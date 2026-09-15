local function codex_acp_native_package()
  local platform = ({
    Linux = "linux",
    OSX = "darwin",
    Windows = "win32",
  })[jit.os]
  local architecture = ({
    arm64 = "arm64",
    x64 = "x64",
  })[jit.arch]

  if not platform or not architecture then
    return nil
  end

  return "codex-acp-" .. platform .. "-" .. architecture
end

local function resolve_native_codex_acp(wrapper)
  local native_package = codex_acp_native_package()
  if not native_package then
    return nil
  end

  local binary_name = jit.os == "Windows" and "codex-acp.exe" or "codex-acp"
  local patterns = {
    vim.fn.expand("~/.npm-global/lib/node_modules/@zed-industries/codex-acp/node_modules/@zed-industries/")
      .. native_package
      .. "/bin/"
      .. binary_name,
    vim.fn.expand("~/.local/share/pnpm/global/*/*/node_modules/.pnpm/node_modules/@zed-industries/")
      .. native_package
      .. "/bin/"
      .. binary_name,
    vim.fn.expand("~/.local/share/pnpm/global/*/node_modules/@zed-industries/codex-acp/node_modules/@zed-industries/")
      .. native_package
      .. "/bin/"
      .. binary_name,
  }

  if jit.os == "Windows" then
    local appdata = os.getenv("APPDATA")
    local localappdata = os.getenv("LOCALAPPDATA")
    local pnpm_home = os.getenv("PNPM_HOME")

    if appdata and appdata ~= "" then
      table.insert(patterns, vim.fs.joinpath(appdata, "npm", "node_modules", "@zed-industries", "codex-acp", "node_modules", "@zed-industries", native_package, "bin", binary_name))
      table.insert(patterns, vim.fs.joinpath(appdata, "npm", "node_modules", "@zed-industries", native_package, "bin", binary_name))
    end

    for _, root in ipairs({ localappdata and vim.fs.joinpath(localappdata, "pnpm") or nil, pnpm_home }) do
      if root and root ~= "" then
        table.insert(patterns, vim.fs.joinpath(root, "global", "*", "node_modules", "@zed-industries", "codex-acp", "node_modules", "@zed-industries", native_package, "bin", binary_name))
        table.insert(patterns, vim.fs.joinpath(root, "global", "*", "node_modules", ".pnpm", "node_modules", "@zed-industries", native_package, "bin", binary_name))
        table.insert(patterns, vim.fs.joinpath(root, "global", "*", "*", "node_modules", "@zed-industries", "codex-acp", "node_modules", "@zed-industries", native_package, "bin", binary_name))
        table.insert(patterns, vim.fs.joinpath(root, "global", "*", "*", "node_modules", ".pnpm", "node_modules", "@zed-industries", native_package, "bin", binary_name))
      end
    end
  end
  local real_wrapper = (vim.uv or vim.loop).fs_realpath(wrapper)

  if real_wrapper then
    local package_root = vim.fs.dirname(vim.fs.dirname(real_wrapper))
    table.insert(
      patterns,
      1,
      vim.fs.joinpath(
        package_root,
        "node_modules",
        "@zed-industries",
        native_package,
        "bin",
        binary_name
      )
    )
  end

  for _, pattern in ipairs(patterns) do
    for _, native_bin in ipairs(vim.fn.glob(pattern, false, true)) do
      if vim.fn.executable(native_bin) == 1 then
        return native_bin
      end
    end
  end

  return nil
end

local function resolve_codex_acp_command()
  local candidates = {
    vim.fn.expand("~/.local/share/pnpm/codex-acp"),
    vim.fn.expand("~/.npm-global/bin/codex-acp"),
  }

  if jit.os == "Windows" then
    for _, candidate in ipairs({
      os.getenv("APPDATA") and vim.fs.joinpath(os.getenv("APPDATA"), "npm", "codex-acp.cmd") or nil,
      os.getenv("LOCALAPPDATA") and vim.fs.joinpath(os.getenv("LOCALAPPDATA"), "pnpm", "bin", "codex-acp.cmd") or nil,
      os.getenv("PNPM_HOME") and vim.fs.joinpath(os.getenv("PNPM_HOME"), "codex-acp.cmd") or nil,
    }) do
      if candidate then table.insert(candidates, candidate) end
    end
  end

  for _, local_bin in ipairs(candidates) do
    if vim.fn.executable(local_bin) == 1 then
      return resolve_native_codex_acp(local_bin) or local_bin
    end
  end

  local path_bin = vim.fn.exepath("codex-acp")
  if path_bin ~= "" then
    return resolve_native_codex_acp(path_bin) or path_bin
  end

  return "codex-acp"
end

local function codex_acp_env()
  local env = {
    NODE_NO_WARNINGS = "1",
    HOME = os.getenv("HOME"),
  }

  local codex_home = os.getenv("CODEX_HOME")
  if codex_home and codex_home ~= "" then
    env.CODEX_HOME = codex_home
  end

  return env
end

local function env_or_default(name, default)
  local value = vim.env[name]
  return value and value ~= "" and value or default
end

local function codex_acp_args()
  local model = env_or_default("AVANTE_CODEX_MODEL", "gpt-5.4-mini")
  local reasoning_effort = env_or_default("AVANTE_CODEX_REASONING_EFFORT", "medium")
  return {
    "-c",
    "model=" .. vim.json.encode(model),
    "-c",
    "model_reasoning_effort=" .. vim.json.encode(reasoning_effort),
  }
end

return {
  "yetone/avante.nvim",
  enabled = true,
  version = "v0.2.3",
  build = vim.fn.has("win32") ~= 0
      and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
    or "make",
  init = function()
    vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
      group = vim.api.nvim_create_augroup("user_avante_input_insert", { clear = true }),
      callback = function()
        if vim.bo.filetype == "AvanteInput" and vim.bo.modifiable then
          vim.schedule(function()
            if vim.bo.filetype == "AvanteInput" and vim.bo.modifiable then
              vim.cmd("startinsert!")
            end
          end)
        end
      end,
    })
  end,
  -- build = "make BUILD_FROM_SOURCE=true luajit",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-tree/nvim-web-devicons",
    {
      "MeanderingProgrammer/render-markdown.nvim",
      opts = { file_types = { "Avante" }, latex = { enabled = false } },
      ft = { "Avante" },
    },
  },
  opts = {
    provider = "codex",
    selector = {
      provider = "snacks",
      provider_opts = {},
    },
    file_selector = {
      provider = "snacks",
      provider_opts = {
        layout = {
          layout = {
            box = "vertical",
            width = 0.8,
            min_width = 120,
            height = 0.85,
            {
              box = "vertical",
              border = true,
              title = "{title} {live} {flags}",
              title_pos = "center",
              { win = "input", height = 1, border = "bottom" },
              { win = "list", height = 0.35, border = "none" },
            },
            { win = "preview", title = "{preview}", border = true, height = 0.65 },
          },
        },
      },
    },
    input = {
      provider = "snacks",
      provider_opts = {
        title = "Avante Input",
      },
    },
    providers = {
      claude = {
        endpoint = "https://api.anthropic.com",
        model = "claude-3-5-sonnet-latest",
        proxy = "http://127.0.0.1:8888",
      },
      cerebras = {
        endpoint = "https://api.cerebras.ai/v1",
        model = "llama3.1-70b",
      },
    },
    acp_providers = {
      codex = {
        command = resolve_codex_acp_command(),
        args = codex_acp_args(),
        env = codex_acp_env(),
        auth_method = "chatgpt",
      },
    },
    behaviour = {
      auto_set_keymaps = false,
      enable_token_counting = false,
    },
    hints = { enabled = false },
    mappings = {
      diff = {
        ours = "co",
        theirs = "ct",
        all_theirs = "ca",
        both = "cb",
        cursor = "cc",
        next = ";x",
        prev = ",x",
      },
      jump = {
        next = ";x",
        prev = ",x",
      },
      submit = {
        normal = "<CR>",
        insert = "<CR>",
      },
      sidebar = {
        apply_all = "A",
        apply_cursor = "a",
        switch_windows = "<Tab>",
        reverse_switch_windows = "<S-Tab>",
      },
    },
    windows = {
      width = 40, -- default % based on available width
    sidebar_header = {
        enabled = true,
        include_model = true,
      },
    },
  },
  cmd = {
    "AvanteAsk",
    "AvanteBuild",
    "AvanteChat",
    "AvanteClear",
    "AvanteAddFile",
    "AvanteEdit",
    "AvanteFocus",
    "AvanteHistory",
    "AvanteModels",
    "AvanteRefresh",
    "AvanteShowRepoMap",
    "AvanteStop",
    "AvanteSwitchProvider",
    "AvanteToggle",
    "AvanteToggleToolMessages",
  },
  keys = {
    { "<leader>aa", false },
    { "<leader>ac", false },
    { "<leader>ae", false },
    { "<leader>af", false },
    { "<leader>ah", false },
    { "<leader>am", false },
    { "<leader>an", false },
    { "<leader>ap", false },
    { "<leader>ar", false },
    { "<leader>as", false },
    { "<leader>at", false },
    { "<leader>axq", "<cmd>AvanteAsk<CR>", desc = "Avante Ask" },
    { "<leader>axa", "<cmd>AvanteAddFile<CR>", desc = "Avante Add File" },
    {
      "<leader>axc",
      function() require("avante.api").ask({ ask = false }) end,
      desc = "Avante Chat",
      mode = { "n", "v" },
    },
    { "<leader>axe", "<cmd>AvanteEdit<CR>", desc = "Avante Edit", mode = { "n", "v" } },
    { "<leader>axf", "<cmd>AvanteFocus<CR>", desc = "Avante Focus" },
    { "<leader>axh", "<cmd>AvanteHistory<CR>", desc = "Avante History" },
    { "<leader>axm", "<cmd>AvanteModels<CR>", desc = "Avante Select Model" },
    { "<leader>axn", "<cmd>AvanteChatNew<CR>", desc = "Avante New Chat" },
    { "<leader>axp", "<cmd>AvanteSwitchProvider<CR>", desc = "Avante Switch Provider" },
    { "<leader>axT", "<cmd>AvanteToggleToolMessages<CR>", desc = "Avante Toggle Tool Messages" },
    { "<leader>axu", "<cmd>AvanteRefresh<CR>", desc = "Avante Refresh" },
    { "<leader>axs", "<cmd>AvanteStop<CR>", desc = "Avante Stop" },
    {
      "<leader>axt",
      function() require("avante").toggle_sidebar({ ask = false }) end,
      desc = "Toggle Avante",
      mode = { "n", "v" },
    },
    {
      "<leader>axv",
      function()
        local avante = require("avante")
        local Config = require("avante.config")

        Config.override({ windows = { position = "right" } })
        avante.toggle_sidebar({ ask = false })
      end,
      desc = "Toggle Avante (vertical)",
      mode = { "n", "v" },
    },
    {
      "<leader>axb",
      function()
        local avante = require("avante")
        local sidebar = avante.get()
        local Config = require("avante.config")

        Config.override({ windows = { position = "bottom" } })
        if sidebar and sidebar:is_open() then
          sidebar:close()
        end
        avante.open_sidebar({ ask = false })
      end,
      desc = "Toggle Avante (horizontal)",
      mode = { "n", "v" },
    },
  },
  config = function(_, opts)
    local function apply_avante_theme_highlights()
      local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
      local normal_float = vim.api.nvim_get_hl(0, { name = "NormalFloat", link = false })
      local fg = normal.fg or normal_float.fg
      local bg = normal.bg or normal_float.bg
      local theme_hl = {}

      if fg then theme_hl.fg = fg end
      if bg then theme_hl.bg = bg end

      vim.api.nvim_set_hl(0, "AvanteSidebarNormal", vim.tbl_extend("force", { link = "Normal" }, theme_hl))
      vim.api.nvim_set_hl(0, "AvantePromptInput", vim.tbl_extend("force", { link = "Normal" }, theme_hl))
      vim.api.nvim_set_hl(0, "AvantePromptInputBorder", vim.tbl_extend("force", { link = "WinSeparator" }, bg and { bg = bg } or {}))
      vim.api.nvim_set_hl(0, "AvanteTitle", theme_hl)
      vim.api.nvim_set_hl(0, "AvanteSubtitle", theme_hl)
      vim.api.nvim_set_hl(0, "AvanteThirdTitle", theme_hl)
      vim.api.nvim_set_hl(0, "AvanteReversedTitle", bg and { fg = bg } or {})
      vim.api.nvim_set_hl(0, "AvanteReversedSubtitle", bg and { fg = bg } or {})
      vim.api.nvim_set_hl(0, "AvanteReversedThirdTitle", bg and { fg = bg } or {})
    end

    local function patch_avante_skip_explorer_panel_auto_file()
      local ok_sidebar, sidebar = pcall(require, "avante.sidebar")
      local ok_config, Config = pcall(require, "avante.config")
      if not ok_sidebar or not ok_config or type(sidebar) ~= "table" then return end
      if type(sidebar.initialize) ~= "function" then return end
      if sidebar.__myneovim_skip_explorer_panel_auto_file_patch then return end

      local base_initialize = sidebar.initialize

      sidebar.initialize = function(self)
        local bufnr = vim.api.nvim_get_current_buf()
        local path = vim.api.nvim_buf_get_name(bufnr)

        if path:match("/lua/config/explorer%-panel%.lua$") then
          local previous = Config.behaviour.auto_add_current_file
          Config.behaviour.auto_add_current_file = false
          local ok, result = pcall(base_initialize, self)
          Config.behaviour.auto_add_current_file = previous
          if ok then return result end
          error(result)
        end

        return base_initialize(self)
      end

      sidebar.__myneovim_skip_explorer_panel_auto_file_patch = true
    end

    local function patch_avante_invalid_buffer_root()
      local ok, root = pcall(require, "avante.utils.root")
      if not ok or type(root) ~= "table" or type(root.get) ~= "function" then return end
      if root.__myneovim_invalid_buffer_root_patch then return end

      local base_get = root.get

      local function fallback_project_root(bufnr)
        local cached = type(bufnr) == "number" and root.cache and root.cache[bufnr] or nil
        if type(cached) == "string" and cached ~= "" then return cached end

        local cwd = vim.uv.cwd()
        if cwd and cwd ~= "" then return cwd end
        return vim.fn.getcwd()
      end

      root.get = function(root_opts)
        local bufnr = root_opts and root_opts.buf
        if type(bufnr) == "number" and bufnr ~= 0 and not vim.api.nvim_buf_is_valid(bufnr) then
          return fallback_project_root(bufnr)
        end

        local ok_get, project_root = pcall(base_get, root_opts)
        if ok_get and type(project_root) == "string" and project_root ~= "" then
          return project_root
        end

        return fallback_project_root(bufnr)
      end

      root.__myneovim_invalid_buffer_root_patch = true
    end

    local function patch_avante_horizontal_input_layout()
      local ok, sidebar = pcall(require, "avante.sidebar")
      if not ok or type(sidebar) ~= "table" then return end
      if sidebar.__avante_input_layout_patched then return end

      local base_create_input_container = sidebar.create_input_container
      local function disable_input_redraw_autocmds(instance)
        if vim.g.avante_compact_input == false then return end
        if not instance or not instance.augroup or not instance.containers or not instance.containers.input then return end

        local bufnr = instance.containers.input.bufnr
        if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then return end

        for _, autocmd in ipairs(vim.api.nvim_get_autocmds({
          group = instance.augroup,
          buffer = bufnr,
          event = { "TextChanged", "TextChangedI", "VimResized" },
        })) do
          pcall(vim.api.nvim_del_autocmd, autocmd.id)
        end
      end

      local function compact_input_container(instance)
        if vim.g.avante_compact_input == false then return end
        local container = instance and instance.containers and instance.containers.input
        if not container or not container.winid or not vim.api.nvim_win_is_valid(container.winid) then return end

        local bufnr = container.bufnr or vim.api.nvim_win_get_buf(container.winid)
        vim.wo[container.winid].signcolumn = "no"
        pcall(vim.fn.sign_unplace, "avante_input_prompt_group", { buffer = bufnr })
      end

      sidebar.create_input_container = function(self)
        local original_get_layout
        if self:get_layout() == "horizontal" then
          original_get_layout = self.get_layout
          self.get_layout = function()
            return "vertical"
          end
        end

        local ok, err = pcall(base_create_input_container, self)

        if original_get_layout then self.get_layout = original_get_layout end
        if not ok then
          vim.notify("Avante input layout patch failed: " .. tostring(err), vim.log.levels.WARN)
        end
        compact_input_container(self)
        disable_input_redraw_autocmds(self)
      end

      sidebar.__avante_input_layout_patched = true
    end

    local function patch_avante_compact_input_hint()
      local ok_sidebar, sidebar = pcall(require, "avante.sidebar")
      if not ok_sidebar or type(sidebar) ~= "table" then return end
      if sidebar.__myneovim_compact_input_hint_patch then return end

      local base_show_input_hint = sidebar.show_input_hint
      sidebar.show_input_hint = function(self)
        if vim.g.avante_compact_input ~= false then
          if self.close_input_hint then self:close_input_hint() end
          return
        end
        return base_show_input_hint(self)
      end

      sidebar.__myneovim_compact_input_hint_patch = true
    end

    local function patch_avante_escape_stop()
      local ok_sidebar, sidebar = pcall(require, "avante.sidebar")
      if not ok_sidebar or type(sidebar) ~= "table" then return end
      if sidebar.__myneovim_escape_stop_patch then return end

      local base_setup_window_navigation = sidebar.setup_window_navigation
      sidebar.setup_window_navigation = function(self, container)
        base_setup_window_navigation(self, container)
        if not container or not container.winid or not vim.api.nvim_win_is_valid(container.winid) then return end

        local bufnr = vim.api.nvim_win_get_buf(container.winid)
        vim.keymap.set({ "n", "i" }, "<Esc>", function()
          require("avante.api").stop()
          if vim.fn.mode() == "i" then
            local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
            vim.api.nvim_feedkeys(esc, "n", false)
          end
        end, { buffer = bufnr, noremap = true, silent = true, nowait = true, desc = "Avante Stop" })
      end

      sidebar.__myneovim_escape_stop_patch = true
    end

    local function patch_avante_hide_tool_messages()
      local ok_render, render = pcall(require, "avante.history.render")
      local ok_helpers, helpers = pcall(require, "avante.history.helpers")
      if not ok_render or not ok_helpers then return end
      if render.__myneovim_hide_tool_messages_patch then return end

      vim.g.avante_hide_tool_messages = vim.g.avante_hide_tool_messages ~= false

      local base_message_to_lines = render.message_to_lines
      local base_message_to_text = render.message_to_text

      render.message_to_lines = function(message, messages, expanded)
        if vim.g.avante_hide_tool_messages ~= false and helpers.is_tool_use_message(message) then
          return {}
        end
        return base_message_to_lines(message, messages, expanded)
      end

      render.message_to_text = function(message, messages)
        if vim.g.avante_hide_tool_messages ~= false and helpers.is_tool_use_message(message) then
          return ""
        end
        return base_message_to_text(message, messages)
      end

      render.__myneovim_hide_tool_messages_patch = true
    end

    local function patch_avante_openai_nil_tool_result_content()
      local ok, openai = pcall(require, "avante.providers.openai")
      if not ok or type(openai) ~= "table" or type(openai.parse_messages) ~= "function" then return end
      if openai.__myneovim_nil_tool_result_content_patch then return end

      local base_parse_messages = openai.parse_messages

      openai.parse_messages = function(self, parse_opts)
        if type(parse_opts) == "table" and type(parse_opts.messages) == "table" then
          for _, msg in ipairs(parse_opts.messages) do
            if type(msg.content) == "table" then
              for _, item in ipairs(msg.content) do
                if type(item) == "table" and item.type == "tool_result" and item.content == nil then
                  item.content = ""
                end
              end
            elseif msg.content == nil then
              msg.content = ""
            end
          end
        end

        return base_parse_messages(self, parse_opts)
      end

      openai.__myneovim_nil_tool_result_content_patch = true
    end

    local function clear_legacy_avante_keymaps()
      local mappings = {
        "<leader>aa",
        "<leader>an",
        "<leader>az",
        "<leader>ae",
        "<leader>ar",
        "<leader>af",
        "<leader>aS",
        "<leader>at",
        "<leader>ad",
        "<leader>aC",
        "<leader>aR",
        "<leader>a?",
        "<leader>ah",
        "<leader>aM",
        "<leader>am",
        "<leader>aB",
      }

      for _, lhs in ipairs(mappings) do
        pcall(vim.keymap.del, "n", lhs)
        pcall(vim.keymap.del, "v", lhs)
        pcall(vim.keymap.del, "i", lhs)
      end
    end

    clear_legacy_avante_keymaps()
    patch_avante_invalid_buffer_root()
    -- Disabled: this custom input-layout patch alters Avante input autocmds and can
    -- cause cursor/text jitter while typing in the prompt buffer.
    -- patch_avante_horizontal_input_layout()
    patch_avante_skip_explorer_panel_auto_file()
    patch_avante_compact_input_hint()
    patch_avante_escape_stop()
    patch_avante_hide_tool_messages()
    patch_avante_openai_nil_tool_result_content()
    require("avante").setup(opts)
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("MyNeovimAvanteInputKeyfix", { clear = true }),
      pattern = { "AvanteInput", "Avante" },
      callback = function(ev)
        vim.keymap.set("i", "<Space>", " ", { buffer = ev.buf, noremap = true, silent = true })
      end,
    })
    vim.api.nvim_create_user_command("AvanteAddFile", function()
      local ok, avante = pcall(require, "avante")
      if not ok or type(avante.get) ~= "function" then
        vim.notify("Avante indisponible", vim.log.levels.WARN)
        return
      end

      local sidebar = avante.get()
      if not sidebar or type(sidebar.is_open) ~= "function" or not sidebar:is_open() then
        avante.open_sidebar({ ask = false })
        sidebar = avante.get()
      end

      if sidebar and sidebar.file_selector and type(sidebar.file_selector.open) == "function" then
        sidebar.file_selector:open()
        return
      end

      vim.notify("File picker Avante indisponible", vim.log.levels.WARN)
    end, { desc = "Avante Add File", force = true })
    vim.api.nvim_create_user_command("AvanteToggleToolMessages", function()
      local currently_hidden = vim.g.avante_hide_tool_messages ~= false
      vim.g.avante_hide_tool_messages = not currently_hidden
      vim.notify(
        "Avante tool messages " .. (vim.g.avante_hide_tool_messages and "hidden" or "visible"),
        vim.log.levels.INFO
      )
    end, {})
    apply_avante_theme_highlights()
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("MyNeovimAvanteThemeHighlights", { clear = true }),
      callback = apply_avante_theme_highlights,
    })
  end,
}
