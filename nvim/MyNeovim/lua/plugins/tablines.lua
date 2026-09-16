return {
  {
    "nanozuki/tabby.nvim",
    enabled = true,
    event = "VeryLazy",
    config = function()
      vim.o.showtabline = 2

      local colors = {
        fill = { fg = "#727169", bg = "#1F1F28" },
        explorer = { fg = "#C8C093", bg = "#16161D", style = "bold" },
        panel = { fg = "#C8C093", bg = "#16161D" },
        workspace = { fg = "#1F1F28", bg = "#957FB8", style = "bold" },
        current = { fg = "#1F1F28", bg = "#9CABCA", style = "bold" },
        buffer = { fg = "#C8C093", bg = "#2A2A37" },
      }

      local panel_filetypes = {
        ["neo-tree"] = "Explorateur",
        NvimTree = "Explorateur",
        undotree = "Undo",
        Trouble = "Trouble",
        qf = "Quickfix",
        aerial = "Symboles",
        Outline = "Symboles",
        Avante = "Avante",
        AvanteInput = "Avante",
        ["no-neck-pain"] = "",
      }

      local panel_buftypes = {
        help = "Aide",
        quickfix = "Quickfix",
      }

      local function panel_label_for(win)
        local buf = vim.api.nvim_win_get_buf(win)
        local ft = vim.bo[buf].filetype
        local bt = vim.bo[buf].buftype
        local name = vim.api.nvim_buf_get_name(buf):match("[^/\\]+$") or ""

        if panel_filetypes[ft] ~= nil then
          return panel_filetypes[ft]
        end
        if panel_buftypes[bt] ~= nil then
          return panel_buftypes[bt]
        end
        if name:find("^undotree_", 1, false) then
          return "Undo"
        end
        if name:find("^diffpanel_", 1, false) then
          return "Diff"
        end

        return nil
      end

      local function side_from_position(win)
        if vim.api.nvim_win_get_config(win).relative ~= "" then
          return nil
        end

        local width = vim.api.nvim_win_get_width(win)
        if width >= vim.o.columns then
          return nil
        end

        local col = vim.api.nvim_win_get_position(win)[2]
        if col == 0 then
          return "left"
        end
        if col + width >= vim.o.columns then
          return "right"
        end

        return nil
      end

      local function add_side_panel(offsets, side, width, label)
        if not side then
          return
        end

        offsets[side].width = math.max(offsets[side].width, width + 1)
        if label and label ~= "" then
          offsets[side].labels[label] = true
        end
      end

      local function sidebar_offsets()
        local offsets = {
          left = { width = 0, labels = {} },
          right = { width = 0, labels = {} },
        }

        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          local label = panel_label_for(win)
          if label ~= nil then
            add_side_panel(offsets, side_from_position(win), vim.api.nvim_win_get_width(win), label)
          end
        end

        local picker = package.loaded["snacks.picker.core.picker"]
        if picker and type(picker.get) == "function" then
          for _, active in ipairs(picker.get({ source = "explorer", tab = true })) do
            local win = active.list and active.list.win and active.list.win.win
            if win and vim.api.nvim_win_is_valid(win) then
              add_side_panel(offsets, side_from_position(win), vim.api.nvim_win_get_width(win), "Explorateur")
            end
          end
        end

        return offsets
      end

      local function labels_for(offset)
        local labels = vim.tbl_keys(offset.labels)
        table.sort(labels)
        if #labels == 0 then
          return "Panneau"
        end
        if #labels == 1 then
          return labels[1]
        end
        return "Panneaux"
      end

      local function side_label(offset, opts)
        local width = offset.width
        if width == 0 then
          return { "", hl = colors.fill }
        end
        local label = labels_for(offset)
        local left = math.max(0, math.floor((width - vim.fn.strdisplaywidth(label)) / 2))
        local right = math.max(0, width - vim.fn.strdisplaywidth(label) - left)
        return { string.rep(" ", left) .. label .. string.rep(" ", right), hl = opts.hl }
      end

      require("tabby").setup({
        line = function(line)
          local tabs = vim.api.nvim_list_tabpages()
          local offsets = sidebar_offsets()
          local usable_width = vim.o.columns - offsets.left.width - offsets.right.width
          local compact = usable_width < 28
          local current_buf = vim.api.nvim_get_current_buf()
          local buffers = {}

          for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
            if vim.bo[bufnr].buflisted then
              table.insert(buffers, bufnr)
            end
          end

          if compact then
            buffers = { current_buf }
          end

          return {
            side_label(offsets.left, { hl = colors.explorer }),
            line
              .tabs()
              .filter(function(tab)
                return tab.is_current()
              end)
              .foreach(function(tab)
                if compact then
                  return { " E" .. tab.number() .. " ", hl = colors.workspace }
                end
                return {
                  { " Espace " .. tab.number() .. "/" .. #tabs .. " ", hl = colors.workspace },
                  { tab.name() .. " ", hl = colors.workspace },
                }
              end),
            { "  ", hl = colors.fill },
            { "%<", hl = colors.fill },
            vim.tbl_map(function(bufnr)
              local hl = bufnr == current_buf and colors.current or colors.buffer
              local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")
              if name == "" then
                name = "[No Name]"
              end
              return {
                " ",
                name,
                vim.bo[bufnr].modified and "*" or "",
                " ",
                hl = hl,
                margin = " ",
              }
            end, buffers),
            line.spacer(),
            side_label(offsets.right, { hl = colors.panel }),
            hl = colors.fill,
          }
        end,
        option = {
          buf_name = { mode = "unique" },
          tab_name = {
            name_fallback = function(tabid)
              for index, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
                if tabpage == tabid then
                  return "Espace " .. index
                end
              end
              return "Espace"
            end,
          },
        },
      })
    end,
  },
  { "willothy/nvim-cokeline", enabled = false, lazy = true, dependencies = { "nvim-tree/nvim-web-devicons" } },
  { "romgrk/barbar.nvim", enabled = false, lazy = true, dependencies = { "nvim-tree/nvim-web-devicons" } },
}
