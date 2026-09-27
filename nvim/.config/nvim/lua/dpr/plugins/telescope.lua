return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    "nvim-tree/nvim-web-devicons",
    "folke/todo-comments.nvim",
  },
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")
    local transform_mod = require("telescope.actions.mt").transform_mod
    --
    local trouble = require("trouble")
    -- local trouble_telescope = require("trouble.sources.telescope")
    --
    --   -- or create your custom action
    local custom_actions = transform_mod({
      open_trouble_qflist = function(prompt_bufnr)
        trouble.toggle("quickfix")
      end,
    })
    vim.keymap.set("n", "<leader>fd", function()
      require("telescope.builtin").diagnostics({
        severity = vim.diagnostic.severity.ERROR,
        bufnr = nil, -- nil means all buffers
      })
    end, { desc = "Find all errors in project" })

    telescope.setup({
      pickers = {
        find_files = {
          theme = "ivy",
        },
        live_grep = {
          theme = "ivy",
        },
        grep_string = {
          theme = "ivy",
        },
        multigrep = {
          theme = "ivy",
        },
      },
      extensions = {
        fzf = {},
      },
      defaults = {

        path_display = { "smart" },
        mappings = {
          i = {
            ["<C-k>"] = actions.move_selection_previous, -- move to prev result
            ["<C-j>"] = actions.move_selection_next, -- move to next result
            ["<C-q>"] = actions.send_selected_to_qflist + custom_actions.open_trouble_qflist,
            ["<C-c>"] = "close", -- Ctrl+c to close immediately
            -- ["<C-t>"] = trouble_telescope.open,
          },
        },
      },
    })

    telescope.load_extension("fzf")

    -- set keymaps
    local keymap = vim.keymap -- for conciseness

    keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Fuzzy find files in cwd" })
    keymap.set("n", "<leader>fh", require("telescope.builtin").help_tags, { desc = "Find help tags" })
    keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Fuzzy find recent files" })
    keymap.set("n", "<leader>fs", "<cmd>Telescope live_grep<cr>", { desc = "Find string in cwd" })
    keymap.set("n", "<leader>fc", "<cmd>Telescope grep_string<cr>", { desc = "Find string under cursor in cwd" })
    keymap.set("n", "<leader>ft", "<cmd>TodoTelescope<cr>", { desc = "Find todos" })
    keymap.set("n", "<leader>en", function()
      require("telescope.builtin").find_files({
        cwd = vim.fn.stdpath("config"),
      })
    end, { desc = "edit config files in nvim " })
    keymap.set("n", "<leader>ep", function()
      require("telescope.builtin").find_files({
        cwd = tostring(vim.fs.joinpath(vim.fn.stdpath("data"), "lazy")),
      })
    end, { desc = "edit config files in nvim " })
    require("dpr.core.telescope.multigrep").setup()
  end,
}
