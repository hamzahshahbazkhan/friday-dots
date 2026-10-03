return {
  "nvim-treesitter/nvim-treesitter",
  lazy = false,
  build = ":TSUpdate",
  dependencies = {
    "windwp/nvim-ts-autotag",
  },
  config = function()
    require("nvim-treesitter.install").prefer_git = true

    -- Handle version differences for module naming safely
    local status, treesitter_config = pcall(require, "nvim-treesitter.config")
    if not status then
      treesitter_config = require("nvim-treesitter.configs")
    end

    treesitter_config.setup({
      highlight = {
        enable = true,
        disable = {}, -- Strictly disable Lua rendering
      },
      indent = { enable = true },
      autotag = { enable = true },
      ensure_installed = {
        "lua",
        "json",
        "javascript",
        "typescript",
        "tsx",
        "yaml",
        "html",
        "css",
        "prisma",
        "markdown",
        "markdown_inline",
        "svelte",
        "graphql",
        "bash",
        "vim",
        "latex",
        "dockerfile",
        "gitignore",
        "query",
        "vimdoc",
        "c",
      },
    })
  end,
}
