-- Python debugging via nvim-dap + debugpy (Dedicated venv python).
-- The system python is uv-managed / externally-managed, so debugpy lives in
-- a dedicated venv. Adapter + interpreter both use that venv.
return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "rcarriga/nvim-dap-ui",
    "theHamsta/nvim-dap-virtual-text",
    "mfussenegger/nvim-dap-python",
  },
  config = function()
    local VENV_PYTHON = "C:/Users/Diane/.shipglows/toolchains/python-dap/Scripts/python.exe"

    local dap = require("dap")
    local dapui = require("dapui")
    require("nvim-dap-virtual-text").setup({})

    -- Registers the debugpy adapter (python -m debugpy.adapter) using the venv python.
    require("dap-python").setup(VENV_PYTHON)
    dapui.setup({})

    dap.configurations.python = {
      {
        type = "python",
        request = "launch",
        name = "Debug current file",
        program = "${file}",
        cwd = "${workspaceFolder}",
        python = VENV_PYTHON,
        console = "internalConsole",
        justMyCode = false,
      },
    }

    local function dap_run()
      local session = dap.active_debug_session()
      if session then
        dap.continue()
      else
        local configs = dap.configurations.python
        dap.run(configs and configs[1] or nil)
      end
    end

    local opts = { noremap = true, silent = true }
    vim.keymap.set("n", "<leader>dr", dap_run, opts)
    vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, opts)
    vim.keymap.set("n", "<leader>dB", function()
      dap.set_breakpoint(vim.fn.input("Breakpoint condition: ") or nil)
    end, opts)
    vim.keymap.set("n", "<leader>dg", dap.step_over, opts)
    vim.keymap.set("n", "<leader>Ds", dap.step_into, opts)
    vim.keymap.set("n", "<leader>Do", dap.step_out, opts)
    vim.keymap.set("n", "<leader>dP", dap.pause, opts)
    vim.keymap.set("n", "<leader>du", dapui.toggle, opts)
    vim.keymap.set("n", "<leader>dl", function()
      vim.cmd("DapOutput")
    end, opts)
    vim.keymap.set("n", "<leader>dt", dap.terminate, opts)

    -- IDE-style function keys.
    vim.keymap.set("n", "<F5>", dap_run, opts)
    vim.keymap.set("n", "<F10>", dap.step_over, opts)
    vim.keymap.set("n", "<F11>", dap.step_into, opts)
    vim.keymap.set("n", "<F12>", dap.step_out, opts)
  end,
}