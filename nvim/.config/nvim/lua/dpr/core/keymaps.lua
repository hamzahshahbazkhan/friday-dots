vim.g.mapleader = " "

local keymap = vim.keymap -- for conciseness

keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })
-- keymap.set("v", "jk", "<ESC>", { desc = "Exit insert mode with jk" })

keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
-- -- In plugins/keymaps.lua

-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- local keymap = vim.keymap
local opts = { noremap = true, silent = true }

-- Directory navigation
keymap.set("n", "<leader>ee", ":Neotree toggle<CR>", opts)
keymap.set("n", "-", "<cmd>Oil<CR>")
-- keymap.set("n", "<leader>f", ":NvimTreeFocus<CR>", opts)

-- Window navigation
keymap.set("n", "<C-h>", "<C-w>h", opts)
keymap.set("n", "<C-j>", "<C-w>j", opts)
keymap.set("n", "<C-k>", "<C-w>k", opts)
keymap.set("n", "<C-l>", "<C-w>l", opts)

-- Resize windows
keymap.set("n", "<C-Left>", ":vertical resize -2<CR>", opts)
keymap.set("n", "<C-Right>", ":vertical resize +2<CR>", opts)
keymap.set("n", "<C-Up>", ":resize +2<CR>", opts)
keymap.set("n", "<C-Down>", ":resize -2<CR>", opts)

-- Buffer navigation
keymap.set("n", "<S-l>", ":bnext<CR>", opts)
keymap.set("n", "<S-h>", ":bprevious<CR>", opts)
keymap.set("n", "<leader>bd", ":bp|bd #<CR>", { desc = "Close buffer and switch to previous" })

-- Keep cursor centered while scrolling
keymap.set("n", "<C-d>", "<C-d>zz", opts)
keymap.set("n", "<C-u>", "<C-u>zz", opts)

-- Visual mode indenting
keymap.set("v", "<", "<gv", opts)
keymap.set("v", ">", ">gv", opts)

-- Move text up and down
keymap.set("v", "<A-j>", ":m .+1<CR>==", opts)
keymap.set("v", "<A-k>", ":m .-2<CR>==", opts)
keymap.set("v", "p", '"_dP', opts)

-- Visual Block --
keymap.set("x", "J", ":move '>+1<CR>gv-gv", opts)
keymap.set("x", "K", ":move '<-2<CR>gv-gv", opts)
keymap.set("x", "<A-j>", ":move '>+1<CR>gv-gv", opts)
keymap.set("x", "<A-k>", ":move '<-2<CR>gv-gv", opts)

-- Terminal navigation
keymap.set("t", "<C-h>", "<C-\\><C-N><C-w>h", opts)
keymap.set("t", "<C-j>", "<C-\\><C-N><C-w>j", opts)
keymap.set("t", "<C-k>", "<C-\\><C-N><C-w>k", opts)
keymap.set("t", "<C-l>", "<C-\\><C-N><C-w>l", opts)

-- Enhanced file operations
keymap.set("n", "<leader>w", ":w<CR>", { desc = "Save file" })
keymap.set("n", "<leader>q", ":q<CR>", { desc = "Quit" })
keymap.set("n", "<leader>h", ":nohlsearch<CR>", { desc = "Clear highlights" })
keymap.set("n", "<leader>fS", ":wa<CR>", { desc = "Save all files" })
keymap.set("n", "<leader>qq", ":qa<CR>", { desc = "Quit all" })
keymap.set("n", "<leader>qa", ":qa!<CR>", { desc = "Force quit all" })

-- Extra navigation
keymap.set("n", "J", "mzJ`z", { desc = "Join lines and keep cursor in place" })
keymap.set("n", "n", "nzzzv", { desc = "Next search result and center" })
keymap.set("n", "N", "Nzzzv", { desc = "Previous search result and center" })

-- Quick fix navigation
keymap.set("n", "<leader>j", ":cnext<CR>zz", { desc = "Next quickfix item" })
keymap.set("n", "<leader>k", ":cprev<CR>zz", { desc = "Previous quickfix item" })

-- Buffer operations
keymap.set("n", "<leader>bn", ":enew<CR>", { desc = "Create new buffer" })
keymap.set("n", "<leader>bD", ":%bd|e#|bd#<CR>", { desc = "Delete all buffers except current" })

-- Search and replace
keymap.set(
  "n",
  "<leader>r",
  ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>",
  { desc = "Replace word under cursor" }
)
keymap.set("v", "<leader>r", '"hy:%s/<C-r>h//gc<left><left><left>', { desc = "Replace selected text" })

-- System clipboard operations
keymap.set("n", "<leader>y", '"+y', { desc = "Copy to system clipboard" })
keymap.set("v", "<leader>y", '"+y', { desc = "Copy selection to system clipboard" })
keymap.set("n", "<leader>Y", '"+Y', { desc = "Copy line to system clipboard" })
keymap.set("n", "<leader>p", '"+p', { desc = "Paste from system clipboard" })

-- Split management
keymap.set("n", "<leader>sv", ":vsplit<CR>", { desc = "Split vertically" })
keymap.set("n", "<leader>sh", ":split<CR>", { desc = "Split horizontally" })
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })

-- LSP keymaps (if LSP is configured)
keymap.set("n", "<leader>lf", ":lua vim.lsp.buf.format()<CR>", { desc = "Format file" })
keymap.set("n", "<leader>la", ":lua vim.lsp.buf.code_action()<CR>", { desc = "Code actions" })
keymap.set("n", "<leader>lr", ":lua vim.lsp.buf.rename()<CR>", { desc = "Rename symbol" })
keymap.set("n", "<leader>ld", ":lua vim.lsp.buf.definition()<CR>", { desc = "Go to definition" })
keymap.set("n", "<leader>lh", ":lua vim.lsp.buf.hover()<CR>", { desc = "Show hover information" })

-- Insert empty lines
keymap.set("n", "<leader>o", "o<Esc>", { desc = "Insert line below" })
keymap.set("n", "<leader>O", "O<Esc>", { desc = "Insert line above" })

-- Nvim DAP
keymap.set("n", "<Leader>dl", "<cmd>lua require'dap'.step_into()<CR>", { desc = "Debugger step into" })
keymap.set("n", "<Leader>dj", "<cmd>lua require'dap'.step_over()<CR>", { desc = "Debugger step over" })
keymap.set("n", "<Leader>dk", "<cmd>lua require'dap'.step_out()<CR>", { desc = "Debugger step out" })
keymap.set("n", "<Leader>dc", "<cmd>lua require'dap'.continue()<CR>", { desc = "Debugger continue" })
keymap.set("n", "<Leader>db", "<cmd>lua require'dap'.toggle_breakpoint()<CR>", { desc = "Debugger toggle breakpoint" })
keymap.set(
  "n",
  "<Leader>dd",
  "<cmd>lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>",
  { desc = "Debugger set conditional breakpoint" }
)
keymap.set("n", "<Leader>de", "<cmd>lua require'dap'.terminate()<CR>", { desc = "Debugger reset" })
keymap.set("n", "<Leader>dr", "<cmd>lua require'dap'.run_last()<CR>", { desc = "Debugger run last" })

-- rustaceanvim
keymap.set("n", "<Leader>dt", "<cmd>lua vim.cmd('RustLsp testables')<CR>", { desc = "Debugger testables" })

-- LaTeX (vimtex + zathura)
keymap.set("n", "<leader>tc", "<cmd>VimtexCompile<CR>", { desc = "LaTeX compile toggle" })
keymap.set("n", "<leader>tv", function()
  local running = false
  pcall(function()
    running = vim.b.vimtex.compiler.is_running() == 1
  end)
  if not running then
    vim.cmd("VimtexCompile")
  end
  vim.cmd("VimtexView")
end, { desc = "LaTeX live compile+view" })
keymap.set("n", "<leader>ts", "<cmd>VimtexStop<CR>", { desc = "LaTeX stop compile" })
keymap.set("n", "<leader>tx", "<cmd>VimtexClean<CR>", { desc = "LaTeX clean aux files" })
keymap.set("n", "<leader>te", "<cmd>VimtexErrors<CR>", { desc = "LaTeX show errors" })
keymap.set("n", "<leader>tt", "<cmd>VimtexTocToggle<CR>", { desc = "LaTeX toggle TOC" })

-- for sessionizer
-- vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer.sh<CR>")
-- vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww ~/.config/scripts/utility/tmux/tmux-sessionizer.sh")
-- keymap.set("n", "<C-f>", "<cmd>silent !tmux neww ~/.config/scripts/utility/tmux/tmux-sessionizer.sh<CR>")
--
-- vim.keymap.set("n", "<C-f>", "<cmd>silent !bash -lc 'tmux neww ~/.config/scripts/utility/tmux/tmux-sessionizer.sh'<CR>")
keymap.set("n", "<C-f>", "<cmd>silent !tmux neww ~/.config/scripts/utility/tmux/tmux-sessionizer.sh<CR>")
-- ~/.config/nvim/lua/your_name/keymaps.lua

-- -- increment/decrement numbers
-- keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number" }) -- increment
-- keymap.set("n", "<leader>-", "<C-x>", { desc = "Decrement number" }) -- decrement
--
-- -- window management
-- keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" }) -- split window vertically
-- keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" }) -- split window horizontally
-- keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" }) -- make split windows equal width & height
-- keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" }) -- close current split window
--
-- keymap.set("n", "<leader>bo", "<cmd>tabnew<CR>", { desc = "Open new tab" }) -- open new tab
-- keymap.set("n", "<leader>bd", "<cmd>tabclose<CR>", { desc = "Close current tab" }) -- close current tab
-- keymap.set("n", "<leader>bn", "<cmd>tabn<CR>", { desc = "Go to next tab" }) --  go to next tab
-- keymap.set("n", "<leader>bp", "<cmd>tabp<CR>", { desc = "Go to previous tab" }) --  go to previous tab
-- keymap.set("n", "<leader>bf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" }) --  move current buffer to new tab
