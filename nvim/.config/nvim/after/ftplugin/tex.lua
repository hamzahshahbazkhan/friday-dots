-- Live compile+view: Space lv starts continuous latexmk (if needed) then opens Zathura.
-- Repeated presses only re-forward-search, never stop the compiler (use Space lk to stop).
vim.keymap.set("n", "<localleader>lv", function()
  local running = false
  pcall(function()
    running = vim.b.vimtex.compiler.is_running() == 1
  end)
  if not running then
    vim.cmd("VimtexCompile")
  end
  vim.cmd("VimtexView")
end, { buffer = true, silent = true, desc = "Live compile+view" })
