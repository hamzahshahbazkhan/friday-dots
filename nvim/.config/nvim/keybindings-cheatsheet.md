# Neovim Keybindings Cheatsheet

## Insert Mode

- `jk` - Exit insert mode with jk

## Normal Mode

### General

- `<leader>h` - Clear search highlights
- `<leader>w` - Save file
- `<leader>q` - Quit
- `<leader>h` - Clear highlights
- `<leader>fS` - Save all files
- `<leader>qq` - Quit all
- `<leader>qa` - Force quit all
- `<leader>o` - Insert line below
- `<leader>O` - Insert line above
- `J` - Join lines and keep cursor in place
- `n` - Next search result and center
- `N` - Previous search result and center

### Navigation

- `<C-h>` - Move to left window
- `<C-j>` - Move to bottom window
- `<C-k>` - Move to top window
- `<C-l>` - Move to right window
- `<C-d>` - Scroll down and center
- `<C-u>` - Scroll up and center
- `<leader>j` - Next quickfix item
- `<leader>k` - Previous quickfix item
- `gR` - Telescope LSP references
- `gD` - Go to declaration
- `gd` - Telescope LSP definitions
- `gi` - Telescope LSP implementations
- `gt` - Telescope LSP type definitions
- `[d` - Previous diagnostic
- `]d` - Next diagnostic
- `]t` - Next todo
- `[t` - Previous todo
- `]h` - Next git hunk
- `[h` - Previous git hunk

### Windows and Buffers

- `<C-Left>` - Resize window left
- `<C-Right>` - Resize window right
- `<C-Up>` - Resize window up
- `<C-Down>` - Resize window down
- `<S-l>` - Next buffer
- `<S-h>` - Previous buffer
- `<leader>bd` - Close buffer and switch to previous
- `<leader>bn` - Create new buffer
- `<leader>bD` - Delete all buffers except current
- `<leader>sv` - Split vertically
- `<leader>sh` - Split horizontally
- `<leader>se` - Make splits equal size

### File Operations

- `<leader>ee` - Toggle Neotree
- `-` - Open Oil
- `<leader>y` - Copy to system clipboard
- `<leader>Y` - Copy line to system clipboard
- `<leader>p` - Paste from system clipboard

### Search and Replace

- `<leader>r` - Replace word under cursor
- `<leader>fs` - Find string in cwd
- `<leader>fc` - Find string under cursor in cwd
- `<leader>ft` - Find todos
- `<leader>ff` - Fuzzy find files
- `<leader>fr` - Fuzzy find recent files
- `<leader>fh` - Find help tags
- `<leader>fd` - Find dotfiles
- `<leader>en` - Edit neovim config
- `<leader>ep` - Edit project

### LSP

- `<leader>lf` - Format file
- `<leader>la` - Code actions
- `<leader>lr` - Rename symbol
- `<leader>ld` - Go to definition
- `<leader>lh` - Show hover information
- `<leader>ca` - Code action
- `<leader>rn` - Rename
- `<leader>D` - Telescope diagnostics
- `<leader>d` - Open diagnostic float
- `K` - Hover
- `<leader>rs` - Restart LSP

### Git

- `<leader>hs` - Stage hunk
- `<leader>hr` - Reset hunk
- `<leader>hS` - Stage buffer
- `<leader>hR` - Reset buffer
- `<leader>hu` - Undo stage hunk
- `<leader>hp` - Preview hunk
- `<leader>hb` - Blame line
- `<leader>hB` - Toggle line blame
- `<leader>hd` - Diff this
- `<leader>hD` - Diff this ~

### Debugging

- `<Leader>dl` - Debugger step into
- `<Leader>dj` - Debugger step over
- `<Leader>dk` - Debugger step out
- `<Leader>dc` - Debugger continue
- `<Leader>db` - Debugger toggle breakpoint
- `<Leader>dd` - Debugger set conditional breakpoint
- `<Leader>de` - Debugger reset
- `<Leader>dr` - Debugger run last
- `<Leader>dt` - Debugger testables

### LaTeX (vimtex + Zathura)

- `<leader>tc` - LaTeX compile toggle (continuous latexmk)
- `<leader>tv` - LaTeX view in Zathura (forward search)
- `<leader>ts` - LaTeX stop compile
- `<leader>tx` - LaTeX clean aux files
- `<leader>te` - LaTeX show errors
- `<leader>tt` - LaTeX toggle TOC

### Other

- `<leader>l` - Lint
- `<leader>mp` - Format
- `<leader>wr` - Restore session
- `<leader>ws` - Save session
- `<C-f>` - Open tmux sessionizer

## Visual Mode

- `<` - Indent left
- `>` - Indent right
- `<A-j>` - Move text down
- `<A-k>` - Move text up
- `p` - Paste without yanking
- `<leader>r` - Replace selected text
- `<leader>y` - Copy selection to system clipboard
- `<leader>hs` - Stage hunk
- `<leader>hr` - Reset hunk

## Visual Block Mode

- `J` - Move line down
- `K` - Move line up
- `<A-j>` - Move line down
- `<A-k>` - Move line up

## Terminal Mode

- `<C-h>` - Move to left window
- `<C-j>` - Move to bottom window
- `<C-k>` - Move to top window
- `<C-l>` - Move to right window

## Operator/Visual/Select Mode

- `;` - Repeat last move
- `,` - Repeat last move opposite
- `f` - Builtin f
- `F` - Builtin F
- `t` - Builtin t
- `T` - Builtin T
- `ih` - Select git hunk

## Substitute

- `s` - Substitute with motion
- `ss` - Substitute line
  `S` - Substitute to end of line
- `s` (visual) - Substitute in visual mode

