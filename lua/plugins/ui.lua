local bufferline = require("bufferline")

return {
  {
    "akinsho/bufferline.nvim",

    opts = function(_, opts)
      opts.options.always_show_bufferline = true

      opts.options.style_preset = {
        bufferline.style_preset.no_italic,
        bufferline.style_preset.minimal,
      }

      opts.options.separator_style = { "", "" }

      for _, offset in ipairs(opts.options.offsets or {}) do
        if offset.filetype == "snacks_layout_box" then
          offset.text = "Explorer"
          offset.highlight = "Directory"
          offset.text_align = "left"
          offset.separator = true
        end
      end
    end,
  },

  {
    "Bekaboo/dropbar.nvim",

    dependencies = {
      "nvim-telescope/telescope-fzf-native.nvim",
    },

    opts = {
      bar = {
        enable = false, -- Disable winbar
        hover = false,
        padding = { left = 0, right = 0 },
      },

      sources = {
        path = {
          relative_to = function(buf)
            return LazyVim.root.get({ buf = buf })
          end,
        },
      },

      menu = {
        win_configs = {
          -- Open the first menu above the statusline; submenus stay beside it.
          relative = function(menu)
            return menu.prev_menu and "win" or "editor"
          end,

          win = function(menu)
            return menu.prev_menu and menu.prev_menu.win or menu.prev_win
          end,

          anchor = function(menu)
            return menu.prev_menu and "NW" or "SW"
          end,

          row = function(menu)
            if menu.prev_menu then
              local clicked_at = menu.prev_menu.clicked_at
              return clicked_at and clicked_at[1] - vim.fn.line("w0") or 0
            end

            if vim.o.laststatus == 3 then
              return vim.o.lines - vim.o.cmdheight - 1
            end

            local position = vim.api.nvim_win_get_position(menu.prev_win)
            return position[1] + vim.api.nvim_win_get_height(menu.prev_win)
          end,

          col = function(menu)
            if menu.prev_menu then
              local width = menu.prev_menu._win_configs.width
              local scrollbar = menu.prev_menu.scrollbar
              if scrollbar and scrollbar.background then
                width = width + 1
              end
              return width
            end

            local mouse = vim.fn.getmousepos()
            if mouse.line == 0 and mouse.winid == menu.prev_win then
              return mouse.screencol - 1
            end

            return vim.api.nvim_win_get_position(menu.prev_win)[2]
          end,
        },
      },
    },

    config = function(_, opts)
      local on_click = require("dropbar.configs").opts.symbol.on_click
      assert(type(on_click) == "function", "Expected dropbar symbol.on_click to be a function")

      opts.symbol = {
        on_click = function(symbol, ...)
          local bar = symbol.bar
          local picking = bar and bar.in_pick_mode
          if bar then
            -- Let menu.win_configs position keyboard picks in the statusline.
            -- Dropbar otherwise overrides these with winbar coordinates.
            bar.in_pick_mode = false
          end

          local ok, err = pcall(on_click, symbol, ...)
          if bar then
            bar.in_pick_mode = picking
          end
          if not ok then
            error(err)
          end
        end,
      }
      require("dropbar").setup(opts)

      local dropbar_api = require("dropbar.api")
      vim.keymap.set("n", "<Leader>;", dropbar_api.pick, { desc = "Pick breadcrumb symbols" })
      vim.keymap.set("n", "[;", dropbar_api.goto_context_start, { desc = "Go to start of current context" })
      vim.keymap.set("n", "];", dropbar_api.select_next_context, { desc = "Select next context" })
    end,
  },

  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "Bekaboo/dropbar.nvim" },

    opts = function(_, opts)
      local ignore_focus = opts.options.ignore_focus
      opts.options.ignore_focus = function(win)
        local filetype = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
        if filetype == "dropbar_menu" or filetype == "dropbar_menu_fzf" then
          return true
        end

        if type(ignore_focus) == "function" then
          return ignore_focus(win)
        end

        return vim.tbl_contains(ignore_focus or {}, filetype)
      end

      -- Replace LazyVim default pretty_path with dropbar.nvim breadcrumb
      opts.sections.lualine_c[4] = {
        function(self)
          local buf = vim.api.nvim_get_current_buf()
          local win = vim.api.nvim_get_current_win()
          if not vim.g.loaded_dropbar or vim.bo[buf].buftype ~= "" or vim.fn.win_gettype(win) ~= "" then
            return ""
          end

          local utils = require("dropbar.utils.bar")
          local bar = utils.get_current()
          if not bar then
            _G.dropbar()
            bar = utils.get_current()
          end

          if not bar or #bar.components == 0 then
            return ""
          end

          -- Evaluate on every redraw so pick pivots bypass lualine's cache.
          -- Keep dropbar's symbol highlights and individual click callbacks.
          return "%{%v:lua.dropbar()%}" .. self:get_default_hl()
        end,

        padding = { left = 1, right = 1 },
      }
    end,
  },
}
