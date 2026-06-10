-- [ENGINE] colorscheme — switch LazyVim from tokyonight to engine.
--
-- The colorscheme itself lives at colors/engine.lua (Neovim discovers
-- colorschemes at colors/<name>.lua in the runtime path). Its palette is
-- loaded from lua/engine/palette.lua (generated from tokens.toml).
return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "engine",
    },
  },
}
