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
  "rust_analyzer",
  "svelte",
  "tailwindcss",
  "ts_ls",
  "yamlls",
  "zls",
}
vim.lsp.config("cssls", {
  settings = {
    css = { lint = { unknownAtRules = "ignore" } },
  },
})

vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers
