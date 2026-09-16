return {
  "folke/which-key.nvim",
  enabled = true,
  optional = true,
  init = function()
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      once = true,
      callback = function()
        vim.schedule(function()
          local ok, view = pcall(require, "which-key.view")
          if not ok or view._dotfiles_submenu_spacing_patched then
            return
          end
          view._dotfiles_submenu_spacing_patched = true

          local orig_item = view.item
          view.item = function(node, opts)
            local item = orig_item(node, opts)
            local parent_path = opts and opts.parent and opts.parent.path or {}
            local is_submenu = #parent_path > 1

            if
              is_submenu
              and item
              and item.icon
              and item.icon ~= ""
              and item.desc
              and item.desc ~= ""
              and not item.desc:match("^%s")
            then
              item.desc = " " .. item.desc
            end

            return item
          end
        end)
      end,
    })
  end,
  opts = {
    icons = {
      rules = {
        { pattern = "ai", icon = "󰚩", color = "purple" },
        { pattern = "cheat", icon = "󰈙", color = "yellow" },
        { pattern = "keywordprg", icon = "", color = "azure" },
        { pattern = "neotree", icon = "", color = "blue" },
      },
    },
    spec = {
      { "<leader>a",     group = "AI", icon = "󰚩" },
      { "<leader>ac",    group = "Claude", icon = "󰋦" },
      { "<leader>ag",    group = "Gemini", icon = "󰊭" },
      { "<leader>aj",    group = "Agentic", icon = "󰚩" },
      { "<leader>ak",    group = "Codex", icon = "󰚩" },
      { "<leader>au",    group = "Augment", icon = "󰘦" },
      { "<leader>ax",    group = "Avante", icon = "󰚩" },
      { "<leader>e",     group = "Explorer", icon = "" },
      { "<leader><tab>", group = "Tabs", icon = "󰓩" },
      { "<leader>b",     group = "Buffer", icon = "󰈔" },
      { "<leader>c",     group = "Code", icon = "" },
      { "<leader>d",     group = "Debug", icon = "󰃤" },
      { "<leader>dp",    group = "Profiler", icon = "󰊕" },
      { "<leader>f",     group = "File/Find", icon = "" },
      { "<leader>g",     group = "Git", icon = "󰊢" },
      { "<leader>G",     group = "Github", icon = "󰊤" },
      { "<leader>gh",    group = "Hunks", icon = "" },
      { "<leader>m",     group = "Mail/Markdown", icon = "󰇮" },
      { "<leader>q",     group = "Quit/Session", icon = "" },
      { "<leader>s",     group = "Search", icon = "" },
      { "<leader>t",     group = "Terminal", icon = "" },
      { "<leader>u",     group = "UI", icon = "󰙵" },
      { "<leader>w",     group = "Windows", icon = "" },
      { "<leader>r",     desc = "Reload changed files", icon = "󰑐" },
      { "<leader>R",     desc = "Reload Neovim config and UI", icon = "󰑐" },
      { "<leader>n",     group = "Notifications", icon = "󰎟" },
      { "<leader>x",     group = "Diagnostics/Quickfix", icon = "󰒡" },
      { "[",             group = "Prev", icon = "" },
      { "]",             group = "Next", icon = "" },
      { "g",             group = "Goto", icon = "󰁔" },
      { "gs",            group = "Surround", icon = "󰅪" },
      { "z",             group = "Fold", icon = "󰘖" },
    },
  },
}
