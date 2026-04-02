require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jj", "<ESC>")

-- Copilot mappings
map("i", "<C-g>", function()
  vim.fn.feedkeys(vim.fn["copilot#Accept"](), "")
end, { desc = "Copilot Accept All" })
map("i", "<C-y>", "<Plug>(copilot-accept-line)", { desc = "Copilot Accept Line" })
map("i", "<C-]>", "<Plug>(copilot-next)")
map("i", "<C-x>", "<Plug>(copilot-dismiss)")

-- Override leader-e to toggle instead of focus
map("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle NvimTree" })

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
