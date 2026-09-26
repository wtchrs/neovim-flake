-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Set highlight
local function set_custom_highlights()
  -- Change inlay hint color
  vim.api.nvim_set_hl(0, "NonText", { fg = "#50586E" })
  -- Change completion menu color
  vim.api.nvim_set_hl(0, "Pmenu", { bg = "#2e3440" })
  -- Make quotation marks easier to see
  vim.api.nvim_set_hl(0, "Quote", { link = "String" })

  -- Match Neo-tree's Git status colors in Snacks explorer.
  local git_highlights = {
    Added = { link = "GitSignsAdd" },
    Modified = { link = "GitSignsChange" },
    Deleted = { link = "GitSignsDelete" },
    Renamed = { link = "GitSignsChange" },
    Copied = { link = "GitSignsChange" },
    Staged = { link = "GitSignsAdd" },
    Untracked = { fg = "#ff8700", italic = true },
    Ignored = { fg = "#626262" },
    Unmerged = { fg = "#ff8700", italic = true, bold = true },
  }
  for status, highlight in pairs(git_highlights) do
    vim.api.nvim_set_hl(0, "SnacksPickerGitStatus" .. status, highlight)
  end
end

set_custom_highlights()

vim.api.nvim_create_autocmd({ "ColorScheme", "LspAttach" }, {
  pattern = "*",
  callback = set_custom_highlights,
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
