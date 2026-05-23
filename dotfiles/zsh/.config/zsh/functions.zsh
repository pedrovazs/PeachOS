# $ZDOTDIR/functions.zsh

# Cria diretório e entra nele
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extrai qualquer arquivo comprimido
extract() {
    [[ -f "$1" ]] || { echo "Arquivo não encontrado: $1" >&2; return 1; }
    case "$1" in
        *.tar.bz2|*.tbz2) tar xjf "$1" ;;
        *.tar.gz|*.tgz)   tar xzf "$1" ;;
        *.tar.xz|*.txz)   tar xJf "$1" ;;
        *.tar.zst)         tar --zstd -xf "$1" ;;
        *.tar)             tar xf "$1" ;;
        *.zip)             unzip "$1" ;;
        *.gz)              gunzip "$1" ;;
        *.bz2)             bunzip2 "$1" ;;
        *.7z)              7z x "$1" ;;
        *.rar)             unrar x "$1" ;;
        *)                 echo "Formato não suportado: $1" >&2; return 1 ;;
    esac
}

# fzf: navega em diretórios com preview
fcd() {
    local dir
    dir=$(fd --type d --hidden --exclude .git | fzf --preview 'eza --tree --level=2 {}') \
        && cd "$dir"
}

# fzf: abre arquivo no nvim
fv() {
    local file
    file=$(fd --type f --hidden --exclude .git | fzf --preview 'bat --style=numbers --color=always {}') \
        && nvim "$file"
}

# Mostra processos com fzf e mata o selecionado
fkill() {
    local pid
    pid=$(ps -eo pid,comm,args --no-headers | fzf | awk '{print $1}') \
        && kill -9 "$pid"
}
