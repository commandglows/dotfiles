return {
  "tadmccorkle/markdown.nvim",
  enabled = true,
  ft = "markdown",
  opts = {
    mappings = {
      inline_surround_toggle = "gs",
      inline_surround_toggle_line = "gss",
      inline_surround_delete = "ds",
      inline_surround_change = "cs",
      link_add = "gl",
      link_follow = "gx",
      go_curr_heading = "]c",
      go_parent_heading = "]p",
      go_next_heading = "]]",
      go_prev_heading = "[[",
    },
    toc = {
      omit_heading = "toc omit heading",
      omit_section = "toc omit section",
    },
  },
}
