# $ZDOTDIR/aliases.zsh

# --- eza substitui ls ---
alias ls='eza --group-directories-first --icons'
alias ll='eza -l --git --group-directories-first --icons'
alias la='eza -la --git --group-directories-first --icons'
alias lt='eza --tree --level=2 --icons'

# --- bat substitui cat ---
alias cat='bat --paging=never --style=plain'

# --- Git ---
alias g='git'
alias gst='git status'
alias gco='git checkout'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gp='git push'
alias gl='git pull'
alias glog='git log --oneline --graph --decorate'
alias gd='git diff'
alias gds='git diff --staged'

# --- pacman / paru ---
alias pi='sudo pacman -S --needed'
alias pu='sudo pacman -Syu'
alias pr='sudo pacman -Rns'
alias pss='pacman -Ss'
alias pai='paru -S --needed'
alias pau='paru -Syu'

# --- Segurança: pede confirmação ---
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# --- Misc ---
alias v='nvim'
alias zj='zellij'
alias tf='tmux new-session -A -s main'       # attach or new
alias clr='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
