return {
  "nvim-neo-tree/neo-tree.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  enabled = false, -- Keep the plugin enabled so you can use it with keybindings
  config = function()
    require("neo-tree").setup({
      close_if_last_window = true, -- Close Neo-tree if it is the last window left in the tab
      popup_border_style = "rounded",
      window = {
        position = "left",
        width = 28,
        mappings = {
          ["<space>"] = "none", -- Disable space mapping to avoid conflicts
        },
        auto_close = true, -- Close when file is opened
      },
      filesystem = {
        follow_current_file = {
          enabled = true, -- Follow the current file when changing directories
        },
        hijack_netrw_behavior = "open_current", -- Only hijack the current window netrw, not auto-open
      },
      event_handlers = {
        {
          event = "neo_tree_buffer_enter",
          handler = function(_)
            vim.opt_local.signcolumn = "auto"
          end,
        },
      },
    })
    -- Only open when explicitly requested with keybinding
    vim.keymap.set("n", "<leader>ee", "<cmd>Neotree toggle<CR>", { desc = "Toggle file explorer" })
  end,
}
