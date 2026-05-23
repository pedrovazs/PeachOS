# $ZDOTDIR/.zshenv — variáveis sempre carregadas (interativo ou não)

# --- Editor ---
# EDITOR: terminal (git, rebase, sudoedit) — nvim
# VISUAL: gráfico — VS Code (ponto de atenção #7 no CLAUDE.md)
export EDITOR="nvim"
export VISUAL="code"
export PAGER="less"
export LESS="-R --use-color"

# --- Gerenciadores de linguagem (XDG-compliant) ---
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export PYENV_ROOT="$XDG_DATA_HOME/pyenv"
export FNM_DIR="$XDG_DATA_HOME/fnm"
export SDKMAN_DIR="$XDG_DATA_HOME/sdkman"

# --- Misc XDG ---
export GNUPGHOME="$XDG_DATA_HOME/gnupg"
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"
export WGETRC="$XDG_CONFIG_HOME/wgetrc"
export HISTFILE="$XDG_STATE_HOME/zsh/history"
export LESSHISTFILE="$XDG_STATE_HOME/less/history"

# --- PATH ---
typeset -U path PATH
path=(
    "$HOME/.local/bin"
    "$CARGO_HOME/bin"
    "$PYENV_ROOT/bin"
    $path
)
export PATH

# --- Locale ---
export LANG="pt_BR.UTF-8"
export LC_ALL="pt_BR.UTF-8"
