-- [ENGINE] platform — polyglot language tooling.
--
-- Companion to systems.lua: that file wires the C/Rust/Lua/shell systems
-- stack; this file wires the rest of the polyglot pipeline (Go, Zig, Python,
-- TypeScript, JVM, Ruby, TOML). LazyVim/lazy.nvim merge these specs with the
-- ones in systems.lua, so the two files are additive — no duplication.
return {
  -- Mason-managed LSP servers, debug adapters and formatters. clangd /
  -- lua-language-server / stylua / shfmt are owned by systems.lua.
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        -- LSP servers
        "gopls",
        "zls",
        "pyright",
        "ruff",
        "typescript-language-server",
        "jdtls",
        "taplo", -- TOML (Cargo.toml, engine.toml, *.kdl-adjacent)
        "bash-language-server", -- shell: the sl-* tools · bootstrap · scenes
        -- Debug adapters
        "codelldb", -- Rust / C / C++ / Zig
        "delve", -- Go
        "debugpy", -- Python
        -- Formatters
        "goimports",
        "prettier",
      })
    end,
  },

  -- Register the language servers with nvim-lspconfig. LazyVim enables every
  -- server listed under opts.servers; rust-analyzer comes from the Rust extra
  -- / rustup and clangd from systems.lua, so neither is repeated here.
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        gopls = {},
        zls = {},
        pyright = {},
        ruff = {},
        ts_ls = {},
        jdtls = {},
        taplo = {},
        bashls = {},
      },
    },
  },

  -- Treesitter grammars for syntax + structural editing.
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "go",
        "gomod",
        "zig",
        "python",
        "typescript",
        "tsx",
        "javascript",
        "java",
        "kotlin",
        "ruby",
        "toml",
        "json",
      })
    end,
  },

  -- Formatters per filetype (deep-merged with systems.lua's conform opts).
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        go = { "goimports", "gofmt" },
        zig = { "zigfmt" },
        python = { "ruff_format" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        json = { "prettier" },
        toml = { "taplo" },
      },
    },
  },
}
