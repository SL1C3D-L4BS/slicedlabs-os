-- [ENGINE] platform — lualine as Liquid-Glass capsule pills (Track 9.1).
-- Colours come from the token-generated `engine.palette` module (SSOT: tokens.toml);
-- the mode + location caps BREATHE the focused workspace's hue via $SL_IDENTITY
-- (exported by scene.sh), falling back to the global accent. Powerline cap glyphs are
-- built with nr2char so this file carries no private-use bytes. Hairline restraint:
-- rounded section caps, no busy component dividers, weight on the mode pill only.

return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  opts = function(_, opts)
    local p = require("engine.palette")
    local id = vim.env.SL_IDENTITY
    if not id or id == "" then id = p.primary end

    local cap_left = vim.fn.nr2char(0xe0b6) -- rounded capsule start
    local cap_right = vim.fn.nr2char(0xe0b4) -- rounded capsule end

    -- identity-accented theme; status hues bind to the palette roles
    local theme = {
      normal = {
        a = { fg = p.bg, bg = id, gui = "bold" },
        b = { fg = p.fg, bg = p.bg_alt },
        c = { fg = p.fg_muted, bg = p.bg },
      },
      insert = { a = { fg = p.bg, bg = p.success, gui = "bold" } },
      visual = { a = { fg = p.bg, bg = p.tertiary, gui = "bold" } },
      replace = { a = { fg = p.bg, bg = p.error, gui = "bold" } },
      command = { a = { fg = p.bg, bg = p.secondary, gui = "bold" } },
      inactive = {
        a = { fg = p.fg_muted, bg = p.bg_alt },
        b = { fg = p.fg_muted, bg = p.bg },
        c = { fg = p.fg_muted, bg = p.bg },
      },
    }

    opts.options = vim.tbl_deep_extend("force", opts.options or {}, {
      theme = theme,
      globalstatus = true,
      component_separators = "",
      section_separators = { left = cap_right, right = cap_left },
    })

    opts.sections = {
      lualine_a = { { "mode", separator = { left = cap_left }, right_padding = 2 } },
      lualine_b = { "branch", "diff" },
      lualine_c = {
        { "filename", path = 1, color = { fg = p.fg } },
        {
          "diagnostics",
          diagnostics_color = {
            error = { fg = p.error },
            warn = { fg = p.honey },
            info = { fg = p.secondary },
            hint = { fg = p.mist },
          },
        },
        "%=",
      },
      lualine_x = { { "filetype", color = { fg = p.fg_muted } } },
      lualine_y = { "progress" },
      lualine_z = { { "location", separator = { right = cap_right }, left_padding = 2 } },
    }

    return opts
  end,
}
