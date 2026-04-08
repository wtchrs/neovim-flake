-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Set highlight
vim.api.nvim_create_autocmd({ "ColorScheme", "LspAttach" }, {
  pattern = "*",
  callback = function()
    -- Change inlay hint color
    vim.api.nvim_set_hl(0, "NonText", { fg = "#50586E" })
    -- Change completion menu color
    vim.api.nvim_set_hl(0, "Pmenu", { bg = "#2e3440" })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "snacks*",
  callback = function()
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
    vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none" })
    -- vim.api.nvim_set_hl(0, "SnacksPicker", { bg = "none", nocombine = true })
    -- vim.api.nvim_set_hl(0, "SnacksPickerBorder", { bg = "none", nocombine = true })
  end,
})

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  pattern = { "*.vs", "*.fs" },
  callback = function()
    vim.bo.filetype = "glsl"
  end,
})

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  pattern = { "*.nix" },
  callback = function()
    vim.bo.filetype = "nix"
  end,
})
