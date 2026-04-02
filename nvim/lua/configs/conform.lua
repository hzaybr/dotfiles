local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    css = { "prettierd", "prettier" },
    html = { "prettierd", "prettier" },
    json = { "fixjson" },
    markdown = { "prettierd", "prettier" },
    python = { "ruff_format", "ruff_organize_imports" },
    sh = { "shfmt" },
    svelte = { "prettierd", "prettier" },
    typescript = { "prettierd", "prettier" },
    zig = { "zigfmt" },
  },

  format_on_save = {
    --   -- These options will be passed to conform.format()
    timeout_ms = 2000,
    lsp_fallback = true,
  },
}

return options
