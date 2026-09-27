

# Use Arch packages so opening a shell never clones or updates plugins.
autoload -Uz compinit && compinit

# ~~~~~~~~~~~~~~~ History ~~~~~~~~~~~~~~~~~~~~~~~~
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt HIST_IGNORE_SPACE  # Don't save when prefixed with space
setopt HIST_IGNORE_DUPS   # Don't save duplicate lines
setopt SHARE_HISTORY      # Share history between sessions

#for vim keybindings
bindkey -v

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Aliases
alias ls='ls --color'
alias pf="fzf --preview='less {}' --bind shift-up:preview-page-up,shift-down:preview-page-down"
alias ll='ls -la'
alias docs="cd ~/Documents"
alias projects="cd ~/Projects"
alias downloads="cd ~/Downloads"
alias dpr="cd ~/DPR"
alias dtop="cd ~/Desktop"
alias mm="xdg-open https://mail.google.com"
alias ts="nvim -c 'Telescope find_files'"
alias yt="xdg-open https://youtube.com"
alias gg="xdg-open https://google.com"
alias mt="xdg-open https://monkeytype.com"
alias wa="xdg-open https://web.whatsapp.com"
alias ~="cd ~"
alias dots="cd ~/dots" 

# Shell integration
eval "$(starship init zsh)"

# PATH
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.config/scripts/utility/tmux/:$PATH"
export PATH="$HOME/go/bin:$PATH"
export GOPATH="$HOME/go"
export EDITOR=nvim
export VISUAL=nvim
# Wayland-first (do not force x11/cairo; ghostty runs native Wayland)
# NVM (only if installed)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

alias theme='~/.config/scripts/themes/set-theme.sh'

# ~~~~~~~~~~~~~~~ FZF Integration ~~~~~~~~~~~~~~~~~~~~~~~~
# Source FZF key bindings and completion for Arch Linux
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh

# Syntax highlighting must load after other ZLE plugins.
[[ -r /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
  source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -r /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh


# Use fd for faster file searching (optional)
if command -v fd > /dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi


bindkey -s '^F' 'tmux-sessionizer.sh\n'
export PATH=$PATH:$GOPATH/bin
alias secenv="source ~/security/tools/venv/bin/activate"
alias newtarget="~/security/scripts/new_target.sh"

# Security workspace aliases
alias sec='cd ~/security'
alias secenv='source ~/security/tools/venv/bin/activate'
alias kali='sudo ~/security/docker/run_kali.sh'
alias newtarget='~/security/scripts/new_target.sh'
alias backup='~/security/scripts/backup.sh'
alias secstart='~/security/scripts/start_day.sh'

# TryHackMe specific aliases
alias thm='cd ~/security/labs/tryhackme'
alias newroom='~/security/scripts/new_thm_room.sh'
alias thmip='echo "export IP=" >> commands.sh && nvim commands.sh'
