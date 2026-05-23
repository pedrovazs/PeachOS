# $ZDOTDIR/.zshrc — config interativa

# --- Histórico ---
HISTSIZE=50000
SAVEHIST=50000
mkdir -p "${HISTFILE:h}"

setopt EXTENDED_HISTORY        # timestamp por entrada
setopt HIST_EXPIRE_DUPS_FIRST  # ao limpar, dups vão primeiro
setopt HIST_IGNORE_DUPS        # não grava cmd igual ao anterior
setopt HIST_IGNORE_SPACE       # cmd com espaço inicial não é gravado
setopt HIST_VERIFY             # ao expandir !!, mostra antes de executar
setopt SHARE_HISTORY           # compartilha entre sessões
setopt INC_APPEND_HISTORY      # grava na hora, não no fim da sessão

# --- Navegação ---
setopt AUTO_CD                 # `cd dir` sem digitar `cd`
setopt AUTO_PUSHD              # cd empilha em dirs
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
setopt EXTENDED_GLOB

# --- Completion ---
autoload -Uz compinit
mkdir -p "$XDG_CACHE_HOME/zsh"
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"

# --- Keybindings (Emacs por padrão; setas pra histórico fuzzy) ---
bindkey -e
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^[[1;5C' forward-word        # Ctrl+→
bindkey '^[[1;5D' backward-word       # Ctrl+←
bindkey '^H' backward-kill-word       # Ctrl+Backspace
bindkey '^[[3;5~' kill-word           # Ctrl+Delete

# --- Plugins (do repo oficial Arch) ---
[[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

[[ -f /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh ]] && \
    source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

# syntax-highlighting precisa ser o ÚLTIMO source (limitação conhecida)
[[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# --- Ferramentas ---
command -v starship &>/dev/null && eval "$(starship init zsh)"
command -v zoxide   &>/dev/null && eval "$(zoxide init zsh)"
command -v fzf      &>/dev/null && source <(fzf --zsh)

# --- Gerenciadores de linguagem ---
[[ -d "$PYENV_ROOT/bin" ]] && eval "$(pyenv init - zsh)"
[[ -s "$FNM_DIR/fnm"   ]] && eval "$(fnm env --use-on-cd --shell zsh)"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

# --- Aliases e funções (arquivos separados) ---
for file in "$ZDOTDIR"/{aliases,functions}.zsh; do
    [[ -f "$file" ]] && source "$file"
done
