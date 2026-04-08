return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre", -- uncomment for format on save
    opts = require "configs.conform",
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },
  {
    "github/copilot.vim",
    lazy = false,
    config = function()
      vim.g.copilot_enable = true
      vim.g.copilot_no_tab_map = true
      vim.g.copilot_assume_mapped = true

      local map = vim.keymap.set
      map("i", "<C-g>", function()
        vim.fn.feedkeys(vim.fn["copilot#Accept"](), "")
      end, { desc = "Copilot Accept All" })
      map("i", "<C-y>", "<Plug>(copilot-accept-line)", { desc = "Copilot Accept Line" })
      map("i", "<C-]>", "<Plug>(copilot-next)")
      map("i", "<C-x>", "<Plug>(copilot-dismiss)")
    end,
  },

  {
    "nvim-tree/nvim-tree.lua",
    opts = {
      actions = {
        change_dir = {
          enable = true,
          restrict_above_cwd = false,
        },
      },
    },
  },

  {
    "lewis6991/gitsigns.nvim",
    opts = require "configs.gitsigns",
  },

  -- test new blink
  -- { import = "nvchad.blink.lazyspec" },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim",
        "lua",
        "vimdoc",
        "html",
        "css",
        "svelte",
        "markdown",
        "markdown_inline",
        "typescript",
        "tsx",
        "javascript",
        "python",
        "rust",
        "bash",
        "json",
        "yaml",
        "dockerfile",
        "zig",
      },
    },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    ft = { "markdown" },
    opts = {},
  },
  {
    "3rd/image.nvim",
    cond = vim.fn.has "mac" == 1,
    lazy = false,
    opts = {
      backend = "kitty",
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          only_render_image_at_cursor = false,
        },
      },
      hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" },
    },
  },
}
