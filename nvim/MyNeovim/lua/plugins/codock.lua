local function selected_range()
  local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.")
  local sn = vim.fn.line("'<")
  local en = vim.fn.line("'>")
  if vim.fn.visualmode() == "" then
    sn = vim.fn.line(".")
    en = sn
  end
  return file, sn, en
end

local function selected_lines(sn, en)
  local ok, lines = pcall(vim.api.nvim_buf_get_lines, 0, sn - 1, en, false)
  return ok and table.concat(lines, "\n") or ""
end

return {
  "gitsang/codock.nvim",
  keys = {
    { "<leader>CC", "<cmd>Codock<cr>", desc = "Codock toggle", mode = { "n", "v" } },
    { "<leader>CA", ":'<,'>CodockActions<cr>", desc = "Codock actions", mode = { "n", "v" } },
    { "<leader>CY", ":'<,'>CodockFilePosYank<cr>", desc = "Codock yank file position", mode = { "n", "v" } },
    { "<leader>CP", ":'<,'>CodockFilePosPaste<cr>", desc = "Codock paste file position", mode = { "n", "v" } },
  },
  opts = {
    width = 80,
    codock_cmd = "claude --permission-mode bypassPermissions",
    copy_to_clipboard = false,
    header = true,
    actions = {
      {
        name = "Expliquer la selection",
        description = "Demander a l'agent d'expliquer la selection",
        prompts = function()
          local file, sn, en = selected_range()
          return string.format(
            "Explique-moi ce code en detail.\nFichier: %s\nLignes %d-%d\n\n%s",
            file,
            sn,
            en,
            selected_lines(sn, en)
          )
        end,
      },
      {
        name = "Corriger la selection",
        description = "Demander a l'agent de corriger la selection",
        prompts = function()
          local file, sn, en = selected_range()
          return string.format(
            "Corrige les problemes dans ce code et explique tes modifications.\nFichier: %s\nLignes %d-%d\n\n%s",
            file,
            sn,
            en,
            selected_lines(sn, en)
          )
        end,
      },
      {
        name = "Analyzer et corriger les diagnostics",
        description = "Envoyer les diagnostics de la selection a l'agent",
        prompts = function()
          local file, sn, en = selected_range()
          local result = string.format("%s:L%d-L%d\n\n", file, sn, en)
          local diagnostics = vim.diagnostic.get(0)
          for _, diag in ipairs(diagnostics) do
            if diag.lnum >= sn - 1 and diag.lnum <= en - 1 then
              result = result
                .. string.format("L%d: [%s] %s\n", diag.lnum + 1, diag.source or "unknown", diag.message)
            end
          end
          if result:match(":L%d-%d\n\n$") then
            result = result .. "Aucun diagnostic dans la selection."
          end
          return result
        end,
      },
      {
        name = "Ajouter le fichier courant",
        description = "Envoyer le chemin du fichier courant a l'agent",
        prompts = function()
          local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.")
          return "@" .. file
        end,
      },
      {
        name = "Envoyer avec prefixe",
        description = "Envoyer un prompt avec un prefixe personnalise",
        execute = function(context)
          vim.ui.input({ prompt = "Prefixe: ", default = "@" }, function(prefix)
            if prefix ~= nil then
              context.send(prefix .. "\nRelis ce fichier et reponds.")
            end
          end)
        end,
      },
    },
  },
}