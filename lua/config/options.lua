-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Set markdown rendering disable
vim.opt.conceallevel = 0

-- Set indent size
vim.opt.shiftwidth = 4

-- Set rounded border for default
vim.o.winborder = "rounded"

-- Align the cursor line number to the left and all other numbers to the right.
function _G.NeovimCustomStatuscolumn()
  local column = LazyVim.statuscolumn()
  if vim.v.virtnum == 0 then
    if vim.v.relnum == 0 and vim.wo.number then
      column = column:gsub("%%=(%d+) ", "%1%%=  ", 1)
    else
      column = column:gsub("%%=(%d+) ", " %%=%1 ", 1)
    end
  end
  return column
end

vim.opt.statuscolumn = "%!v:lua.NeovimCustomStatuscolumn()"
