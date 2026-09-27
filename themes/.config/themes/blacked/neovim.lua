return {
  {
    "loctvl842/monokai-pro.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("monokai-pro").setup({ filter = "machine", transparent_background = false })
      vim.cmd.colorscheme("monokai-pro")
      vim.api.nvim_set_hl(0, "Normal", { bg = "#000000", fg = "#ffffff" })
      vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#111111", fg = "#ffffff" })
      vim.api.nvim_set_hl(0, "FloatBorder", { bg = "#111111", fg = "#00ccff" })
    end,
  },
}
