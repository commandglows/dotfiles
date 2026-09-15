return {
  {
    "y3owk1n/time-machine.nvim",
    version = "*",
    cmd = {
      "TimeMachineToggle",
      "TimeMachinePurgeBuffer",
      "TimeMachinePurgeAll",
      "TimeMachineLogShow",
    },
    keys = {
      {
        "<leader>uT",
        "<cmd>TimeMachineToggle<cr>",
        desc = "Historique d'edition",
      },
    },
    opts = {
      -- Keep large generated files out of persistent undo history.
      ignore_filesize = 5 * 1024 * 1024,
      diff_tool = "native",
    },
  },
}
-- verification transient time-machine
