#!/usr/bin/env bash
# install.sh — instala pacotes e configura o ambiente PeachOS.
# Fase 3 (e suporte para Fase 2). Idempotente: pode rodar quantas vezes precisar.
# Pré-requisito: sistema base já instalado via archinstall, usuário com sudo.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
PKGLIST="$REPO_DIR/packages/pkglist.txt"
AURLIST="$REPO_DIR/packages/aurlist.txt"
DOTFILES_DIR="$REPO_DIR/dotfiles"

# Paleta PeachOS no terminal
PEACH='\033[38;2;232;149;109m'
LAVENDER='\033[38;2;196;168;212m'
RESET='\033[0m'

info()  { printf "${LAVENDER}::${RESET} %s\n" "$*"; }
ok()    { printf "${PEACH}✓${RESET}  %s\n" "$*"; }
warn()  { printf "${PEACH}⚠${RESET}  %s\n" "$*" >&2; }
die()   { printf "${PEACH}✗${RESET}  %s\n" "$*" >&2; exit 1; }

# ============================================================
# Pré-checks
# ============================================================

preflight() {
    [[ -f /etc/arch-release ]] || die "PeachOS roda só em Arch Linux."
    [[ $EUID -ne 0 ]]          || die "Não rode como root. O script chama sudo quando precisa."
    command -v sudo &>/dev/null || die "sudo não está instalado."
    [[ -f "$PKGLIST" ]] || die "Lista de pacotes não encontrada: $PKGLIST"
    [[ -f "$AURLIST" ]] || die "Lista AUR não encontrada: $AURLIST"
    ping -c1 -W2 archlinux.org &>/dev/null || die "Sem conexão. Verifica a rede."
    ok "Pré-checks passaram."
}

# ============================================================
# Pacotes — filtra comentários e linhas em branco
# ============================================================

read_pkglist() { grep -vE '^\s*(#|$)' "$1"; }

install_pacman() {
    info "Atualizando sistema e instalando pacotes oficiais"
    local pkgs
    pkgs=$(read_pkglist "$PKGLIST" | tr '\n' ' ')
    [[ -z "${pkgs// }" ]] && { warn "pkglist.txt vazio."; return; }
    # shellcheck disable=SC2086
    sudo pacman -Syu --needed --noconfirm $pkgs
    ok "Pacotes oficiais OK."
}

bootstrap_paru() {
    if command -v paru &>/dev/null; then
        ok "paru já instalado."
        return
    fi
    info "Bootstrap do paru (AUR helper)"
    local tmp
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' RETURN
    git clone https://aur.archlinux.org/paru.git "$tmp/paru"
    (cd "$tmp/paru" && makepkg -si --noconfirm)
    ok "paru instalado."
}

install_aur() {
    local pkgs
    pkgs=$(read_pkglist "$AURLIST" | tr '\n' ' ')
    if [[ -z "${pkgs// }" ]]; then
        info "Nenhum pacote AUR a instalar nesta fase."
        return
    fi
    info "Instalando pacotes AUR"
    # shellcheck disable=SC2086
    paru -S --needed --noconfirm $pkgs
    ok "Pacotes AUR OK."
}

# ============================================================
# Gerenciadores de linguagem
# ============================================================

setup_rustup() {
    command -v rustup &>/dev/null || die "rustup deveria estar no pkglist."
    if rustup default 2>/dev/null | grep -q '^stable'; then
        ok "rustup já tem toolchain stable como default."
        return
    fi
    info "Instalando toolchain stable do Rust"
    rustup default stable
    ok "Rust stable OK. Use \`rustup install nightly\` se precisar do nightly."
}

setup_sdkman() {
    : "${XDG_DATA_HOME:=$HOME/.local/share}"
    local sdkman_dir="$XDG_DATA_HOME/sdkman"
    if [[ -s "$sdkman_dir/bin/sdkman-init.sh" ]]; then
        ok "sdkman já instalado em $sdkman_dir."
        return
    fi
    info "Bootstrap do sdkman em $sdkman_dir"
    # rcupdate=false: não toca em ~/.zshrc; a integração já está em dotfiles/zsh
    export SDKMAN_DIR="$sdkman_dir"
    curl -s "https://get.sdkman.io?rcupdate=false" | bash
    ok "sdkman instalado. Use \`sdk install java 21-tem\` (ou outra versão)."
}

# pyenv e fnm não precisam de bootstrap pós-install:
# - pyenv: binário no PATH via $PYENV_ROOT em .zshenv. Instale versões: `pyenv install 3.12`.
# - fnm:   binário do pacman, stateless. Instale versões: `fnm install --lts`.

# ============================================================
# Shell padrão e dotfiles
# ============================================================

set_zsh_default() {
    local zsh_path
    zsh_path=$(command -v zsh) || die "zsh não está instalado."
    if [[ "$(getent passwd "$USER" | cut -d: -f7)" == "$zsh_path" ]]; then
        ok "zsh já é o shell padrão."
        return
    fi
    info "Mudando shell padrão para zsh (chsh vai pedir sua senha)"
    chsh -s "$zsh_path"
    warn "Logout/login necessário pra entrar no zsh."
}

apply_dotfiles() {
    command -v stow &>/dev/null || die "stow não está instalado (deveria estar no pkglist)."
    info "Aplicando dotfiles via stow ($DOTFILES_DIR → \$HOME)"
    local pkg conflicts=0
    for pkg in "$DOTFILES_DIR"/*/; do
        pkg=$(basename "$pkg")
        if stow -t "$HOME" -d "$DOTFILES_DIR" "$pkg" 2>/tmp/peachos-stow-err; then
            ok "  $pkg"
        else
            warn "  $pkg — conflito:"
            sed 's/^/      /' /tmp/peachos-stow-err >&2
            conflicts=$((conflicts + 1))
        fi
    done
    rm -f /tmp/peachos-stow-err
    if (( conflicts > 0 )); then
        warn "$conflicts pacote(s) com conflito. Mova/remova os arquivos existentes e rode de novo."
    else
        ok "Dotfiles aplicados."
    fi
}

# ============================================================
# Main
# ============================================================

main() {
    printf "\n${PEACH}━━━ PeachOS install.sh ━━━${RESET}\n\n"

    preflight

    install_pacman
    bootstrap_paru
    install_aur

    setup_rustup
    setup_sdkman

    set_zsh_default
    apply_dotfiles

    printf "\n${PEACH}━━━ Concluído ━━━${RESET}\n\n"
    info "Próximos passos:"
    info "  1. logout/login para entrar no zsh"
    info "  2. pyenv install 3.12 && pyenv global 3.12"
    info "  3. fnm install --lts && fnm default lts-latest"
    info "  4. sdk install java 21-tem"
    info "  5. rode \`./apply-theme.sh\` quando os arquivos da Fase 5 estiverem prontos"
}

main "$@"
