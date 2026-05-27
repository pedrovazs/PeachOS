#!/usr/bin/env bash
# PeachOS — install.sh
# Fase 3: instala pacotes, runtimes e dotfiles em cima de um Arch base.
#
# Pré-requisitos:
#   - Arch Linux instalado via archinstall e bootado
#   - Scripts da Fase 2 (scripts/*.sh) já executados (em particular o bloco 10
#     que habilita [multilib])
#
# O que faz:
#   1. Pré-checks (não-root, Arch, multilib, rede)
#   2. Instala pacotes oficiais (pacman -Syu)
#   3. Compila paru do AUR se faltar
#   4. Instala pacotes AUR (paru)
#   5. Configura runtimes: rustup, pyenv (Python 3 latest), fnm (Node LTS), sdkman
#   6. Troca shell padrão para zsh
#   7. Aplica dotfiles via stow
#
# Idempotente: rodar duas vezes não quebra.

set -euo pipefail
shopt -s nullglob

REPO_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
PKGLIST="$REPO_DIR/packages/pkglist.txt"
AURLIST="$REPO_DIR/packages/aurlist.txt"
DOTFILES_DIR="$REPO_DIR/dotfiles"

# Paleta PeachOS no terminal
PEACH=$'\033[38;2;232;149;109m'
LAVENDER=$'\033[38;2;196;168;212m'
RESET=$'\033[0m'

info() { printf "${LAVENDER}::${RESET} %s\n" "$*"; }
ok()   { printf "${PEACH}✓${RESET}  %s\n" "$*"; }
warn() { printf "${PEACH}⚠${RESET}  %s\n" "$*" >&2; }
die()  { printf "${PEACH}✗${RESET}  %s\n" "$*" >&2; exit 1; }

# Limpeza global de diretórios temporários (paru, stow err, etc.)
TMPDIRS=()
cleanup() {
    local d
    for d in "${TMPDIRS[@]:-}"; do
        [[ -n "$d" && -d "$d" ]] && rm -rf "$d"
    done
}
trap cleanup EXIT

# Filtra comentários e linhas em branco. tr -d '\r' defende contra CRLF.
read_pkglist() {
    tr -d '\r' < "$1" | grep -vE '^\s*(#|$)'
}

# ============================================================
# 1. Pré-checks
# ============================================================
preflight() {
    info "Pré-checks"
    [[ $EUID -ne 0 ]]            || die "Não rode como root. O script chama sudo quando precisa."
    [[ -f /etc/arch-release ]]   || die "PeachOS roda só em Arch Linux."
    command -v sudo &>/dev/null  || die "sudo não está instalado."
    [[ -f "$PKGLIST" ]]          || die "Lista de pacotes não encontrada: $PKGLIST"
    [[ -f "$AURLIST" ]]          || die "Lista AUR não encontrada: $AURLIST"
    [[ -d "$DOTFILES_DIR" ]]     || die "Diretório de dotfiles não encontrado: $DOTFILES_DIR"

    grep -q '^\[multilib\]' /etc/pacman.conf \
        || die "[multilib] não habilitado. Rode: sudo bash scripts/10-mirrors-pacman.sh"

    # HTTPS em vez de ping (ICMP costuma ser bloqueado)
    curl -fsSI --max-time 5 https://archlinux.org >/dev/null \
        || die "Sem conexão com archlinux.org. Verifica a rede."

    info "Solicitando privilégios sudo (cache de senha)..."
    sudo -v
    ok "Pré-checks passaram."
}

# ============================================================
# 2. Pacotes oficiais
# ============================================================
install_pacman() {
    info "Atualizando sistema e instalando pacotes oficiais"
    mapfile -t pkgs < <(read_pkglist "$PKGLIST")
    [[ ${#pkgs[@]} -gt 0 ]] || die "pkglist.txt sem pacotes válidos."
    info "${#pkgs[@]} pacotes na lista."
    sudo pacman -Syu --needed --noconfirm "${pkgs[@]}"
    ok "Pacotes oficiais OK."
}

# ============================================================
# 3. paru (AUR helper)
# ============================================================
bootstrap_paru() {
    if command -v paru &>/dev/null; then
        ok "paru já instalado."
        return
    fi
    info "Bootstrap do paru (AUR helper)"
    local tmp
    tmp=$(mktemp -d)
    TMPDIRS+=("$tmp")
    git clone --depth=1 https://aur.archlinux.org/paru.git "$tmp/paru"
    (cd "$tmp/paru" && makepkg -si --noconfirm)
    ok "paru instalado."
}

# ============================================================
# 4. Pacotes AUR
# ============================================================
install_aur() {
    mapfile -t pkgs < <(read_pkglist "$AURLIST")
    if [[ ${#pkgs[@]} -eq 0 ]]; then
        info "aurlist.txt vazio, pulando AUR."
        return
    fi
    info "Instalando ${#pkgs[@]} pacotes do AUR"
    paru -S --needed --noconfirm "${pkgs[@]}"
    ok "Pacotes AUR OK."
}

# ============================================================
# 5. Runtimes
# ============================================================
setup_rustup() {
    command -v rustup &>/dev/null || die "rustup deveria estar no pkglist."
    if rustup default 2>/dev/null | grep -q '^stable'; then
        ok "rustup já tem toolchain stable como default."
        return
    fi
    info "Instalando toolchain stable do Rust"
    rustup default stable
    ok "Rust stable OK."
}

setup_pyenv() {
    if ! command -v pyenv &>/dev/null; then
        warn "pyenv não disponível, pulando configuração do Python."
        return
    fi
    local latest
    latest=$(pyenv install --list 2>/dev/null \
        | awk '/^[[:space:]]*3\.[0-9]+\.[0-9]+$/ { gsub(/ /, ""); v=$0 } END { print v }')

    if [[ -z "$latest" ]]; then
        warn "pyenv: não consegui detectar última versão do Python 3."
        return
    fi
    if pyenv versions --bare 2>/dev/null | grep -qx "$latest"; then
        ok "pyenv: Python $latest já instalado."
        return
    fi
    info "pyenv: instalando Python $latest (compila do source, vai demorar)..."
    pyenv install "$latest"
    pyenv global "$latest"
    ok "Python $latest instalado e global."
}

setup_fnm() {
    if ! command -v fnm &>/dev/null; then
        warn "fnm não disponível, pulando configuração do Node."
        return
    fi
    # shellcheck disable=SC1090  # source de saída de processo local e conhecido
    source <(fnm env --shell bash) 2>/dev/null || true
    if fnm list 2>/dev/null | grep -qE 'v[0-9]+\.[0-9]+\.[0-9]+'; then
        ok "fnm: alguma versão do Node já instalada."
        return
    fi
    info "fnm: instalando Node LTS"
    fnm install --lts
    fnm default lts-latest
    ok "Node LTS instalado."
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
    # Risco: sdkman não publica checksums oficiais; este pipe-to-bash é um vetor
    # de ataque em caso de DNS poisoning ou servidor comprometido. HTTPS mitiga,
    # mas não elimina. Para reinstalações em ambiente hostil, verificar o hash
    # em https://github.com/sdkman/sdkman-cli/releases antes de executar.
    export SDKMAN_DIR="$sdkman_dir"
    curl -fsSL "https://get.sdkman.io?rcupdate=false" | bash
    ok "sdkman instalado. Use \`sdk install java 21-tem\` (ou outra versão)."
}

# ============================================================
# 6. Shell padrão
# ============================================================
set_zsh_default() {
    local zsh_path
    zsh_path=$(command -v zsh) || die "zsh não está instalado."
    grep -qFx "$zsh_path" /etc/shells \
        || die "$zsh_path não está em /etc/shells. Adicione-o e rode de novo."
    if [[ "$(getent passwd "$USER" | cut -d: -f7)" == "$zsh_path" ]]; then
        ok "zsh já é o shell padrão."
        return
    fi
    info "Mudando shell padrão para zsh (chsh vai pedir sua senha)"
    chsh -s "$zsh_path"
    warn "Logout/login necessário pra entrar no zsh."
}

# ============================================================
# 7. Dotfiles
# ============================================================
apply_dotfiles() {
    command -v stow &>/dev/null || die "stow não está instalado (deveria estar no pkglist)."
    info "Aplicando dotfiles via stow ($DOTFILES_DIR → \$HOME)"

    local stow_tmp stow_err pkg conflicts=0
    stow_tmp=$(mktemp -d)
    TMPDIRS+=("$stow_tmp")
    stow_err="$stow_tmp/stow.err"

    for pkg in "$DOTFILES_DIR"/*/; do
        pkg=$(basename "$pkg")
        if stow -d "$DOTFILES_DIR" -t "$HOME" --no-folding --simulate "$pkg" >/dev/null 2>"$stow_err"; then
            stow -d "$DOTFILES_DIR" -t "$HOME" --no-folding -R "$pkg"
            ok "  $pkg"
        else
            warn "  $pkg — conflito:"
            sed 's/^/      /' "$stow_err" >&2
            conflicts=$((conflicts + 1))
        fi
    done
    rm -f "$stow_err"

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
    setup_pyenv
    setup_fnm
    setup_sdkman

    set_zsh_default
    apply_dotfiles

    printf "\n${PEACH}━━━ Concluído ━━━${RESET}\n\n"
    info "Próximos passos manuais:"
    info "  1. Logout/login para entrar no zsh."
    info "  2. (Opcional) sdk install java 21-tem"
    info "  3. Instalar extensões do VS Code listadas em CLAUDE.md nota 16."
    info "  4. Aplicar tema visual (Fase 5):"
    info "       ./apply-theme.sh                  (user + system, recomendado)"
    info "       ./apply-theme.sh --user-only      (só sessão do usuário)"
    info "       ./apply-theme.sh --system-only    (só GRUB + Plymouth + GDM)"
}

main "$@"
