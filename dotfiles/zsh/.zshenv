# ~/.zshenv — bootstrap mínimo que aponta ZDOTDIR para ~/.config/zsh
# Tudo o mais (variáveis, prompt, aliases) vive em $ZDOTDIR/.

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# Arquivos criados pelo usuário não ficam legíveis por outros (600/700).
# Ferramentas que precisem de 644 podem sobrescrever localmente.
umask 077
