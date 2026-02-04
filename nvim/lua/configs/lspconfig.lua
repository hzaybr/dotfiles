require("nvchad.configs.lspconfig").defaults()

local servers = {
  "bashls",
  "cssls",
  "dockerls",
  "html",
  "jsonls",
  "lua_ls",
  "marksman",
  "pyright",
  "svelte",
  "tailwindcss",
  "ts_ls",
  "yamlls",
  "zls",
}
vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers
