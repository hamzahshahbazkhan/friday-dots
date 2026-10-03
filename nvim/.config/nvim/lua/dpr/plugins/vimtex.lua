return {
  "lervag/vimtex",
  lazy = false,
  init = function()
    vim.g.vimtex_view_method = "zathura"
    vim.g.vimtex_compiler_method = "latexmk"
    vim.g.maplocalleader = " "

    vim.g.vimtex_compiler_latexmk = {
      build_dir = "",
      callback = 1,
      continuous = 1,
      executable = "latexmk",
      options = {
        "-pdf",
        "-verbose",
        "-file-line-error",
        "-synctex=1",
        "-interaction=nonstopmode",
        "-shell-escape",
      },
    }

    vim.g.vimtex_view_general_viewer = "zathura"
    vim.g.vimtex_view_zathura_use_synctex = 1
    vim.g.vimtex_quickfix_mode = 0
    vim.g.tex_flavor = "latex"
  end,
}
