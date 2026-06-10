-- [ENGINE] platform — systems-engineering tooling (spec XVIII.7)
return {
  -- LSP / tool installs. rust-analyzer is provided by rustup, not Mason.
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "clangd",
        "lua-language-server",
        "stylua",
        "shfmt",
      })
    end,
  },

  -- Debug Adapter Protocol (gdb / lldb / engine-debug)
  { "mfussenegger/nvim-dap" },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
  },

  -- Formatting
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        rust = { "rustfmt" },
        lua = { "stylua" },
        sh = { "shfmt" },
      },
    },
  },
}
