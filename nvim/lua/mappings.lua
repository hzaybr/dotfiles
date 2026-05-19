require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jj", "<ESC>")

-- Override leader-e to toggle instead of focus
map("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle NvimTree" })

-- image.nvim zoom
local function with_modifiable(buf, fn)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    fn()
    return
  end
  local was = vim.bo[buf].modifiable
  if not was then vim.bo[buf].modifiable = true end
  local ok, err = pcall(fn)
  if not was then vim.bo[buf].modifiable = false end
  if not ok then vim.notify(err, vim.log.levels.ERROR) end
end

local function image_zoom(factor)
  local ok, api = pcall(require, "image")
  if not ok then return end
  for _, img in ipairs(api.get_images()) do
    local g = img.geometry or {}
    local w = g.width or img.image_width
    local h = g.height or img.image_height
    with_modifiable(img.buffer, function()
      img:render({ width = math.floor(w * factor), height = math.floor(h * factor) })
    end)
  end
end

map("n", "<leader>i+", function() image_zoom(1.25) end, { desc = "Image zoom in" })
map("n", "<leader>i-", function() image_zoom(0.8) end, { desc = "Image zoom out" })
map("n", "<leader>i0", function()
  local ok, api = pcall(require, "image")
  if not ok then return end
  for _, img in ipairs(api.get_images()) do
    with_modifiable(img.buffer, function()
      img:render({ width = nil, height = nil })
    end)
  end
end, { desc = "Image reset size" })

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
