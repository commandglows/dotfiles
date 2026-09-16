local function sessions_dir()
  local git_root = vim.fs.root(0, ".git") or vim.uv.cwd()
  return vim.fs.joinpath(git_root, "conversations-codecompanion")
end

return {
  "olimorris/codecompanion.nvim",
  enabled = true,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions" },
  opts = {
    interactions = {
      chat = {
        adapter = { name = "cerebras", model = "gpt-oss-120b" },
        sessions = {
          enabled = true,
          autosave = true,
          continuous_save = true,
          save_dir = sessions_dir(),
        },
      },
      inline = { adapter = { name = "cerebras", model = "gpt-oss-120b" } },
    },
    adapters = {
      http = {
        opts = { show_presets = false },
        cerebras = function()
          return require("codecompanion.adapters").extend("openai_compatible", {
            name = "cerebras",
            formatted_name = "Cerebras",
            env = {
              api_key = "CEREBRAS_API_KEY",
              url = "https://api.cerebras.ai",
              chat_url = "/v1/chat/completions",
              models_endpoint = "/v1/models",
            },
            schema = {
              model = { default = "gpt-oss-120b" },
            },
          })
        end,
      },
      acp = {
        opts = { show_presets = false },
        codex = function()
          return require("codecompanion.adapters").extend("codex", {
            defaults = { auth_method = "chat-gpt" },
          })
        end,
      },
    },
  },
  keys = {
    { "<leader>cc", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "v" }, desc = "CodeCompanion Chat" },
    { "<leader>ca", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "CodeCompanion Actions" },
    { "<leader>ci", "<cmd>CodeCompanion<cr>", mode = { "n", "v" }, desc = "CodeCompanion Inline" },
  },
}
