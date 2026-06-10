-- SlicedLabs · body · © 2026 SlicedLabs
-- snacks.nvim dashboard — the SLICEDLABS greeting inside the editor. Header art
-- mirrors the fastfetch wordmark (one design language, every surface); colours
-- come from colors/engine.lua SnacksDashboard* groups (tokens cascade).
return {
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
        preset = {
          header = table.concat({
            "█████  █      █████  █████  █████  ████ ",
            "█      █        █    █      █      █   █",
            "█████  █        █    █      ████   █   █",
            "    █  █        █    █      █      █   █",
            "█████  █████  █████  █████  █████  ████ ",
            "",
            "        █      █████  ████   █████",
            "        █      █   █  █   █  █    ",
            "        █      █████  ████   █████",
            "        █      █   █  █   █      █",
            "        █████  █   █  ████   █████",
          }, "\n"),
        },
        sections = {
          { section = "header" },
          { section = "keys", gap = 1, padding = 1 },
          { section = "recent_files", icon = " ", title = "Recent", indent = 2, padding = 1 },
          { section = "projects", icon = " ", title = "Projects", indent = 2, padding = 1 },
          { section = "startup" },
        },
      },
    },
  },
}
