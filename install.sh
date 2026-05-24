#!/usr/bin/env bash
# PeachOS — Fase 3: instalação de pacotes, runtimes e dotfiles
#
# Pré-requisitos:
#   - Arch Linux base já instalado (archinstall) e bootado
#   - Scripts da Fase 2 (scripts/*.sh) executados como root, um por um,
#     na ordem numérica. Em particular, o bloco 10 habilita [multilib].
#
# O que faz:
#   1. Sanity checks (usuário não-root, multilib ativo, listas presentes)
#   2. Instala pacotes do packages/pkglist.txt (pacman)
#   3. Compila paru do AUR se faltar
#   4. Instala pacotes do packages/aurlist.txt (paru)
#   5. Configura runtimes: rustup, pyenv, fnm, sdkman
#   6. Aplica dotfiles via stow
#
# Idempotente: rodar duas vezes não quebra.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# install.sh — instala pacotes e configura o ambiente PeachOS.
# Fase 3 (e suporte para Fase 2). Idempotente: pode rodar quantas vezes precisar.
# Pré-requisito: sistema base já instalado via archinstall, usuário com sudo.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
PKGLIST="$REPO_DIR/packages/pkglist.txt"
AURLIST="$REPO_DIR/packages/aurlist.txt"
DOTFILES_DIR="$REPO_DIR/dotfiles"

# === Helpers ===
log()  { printf '\n==> %s\n' "$*"; }
info() { printf '  -> %s\n' "$*"; }
warn() { printf '  AVISO: %s\n' "$*" >&2; }
fail() { printf '  ERRO: %s\n' "$*" >&2; exit 1; }

# Lê uma lista de pacotes ignorando comentários e linhas vazias
read_list() {
    grep -vE '^\s*(#|$)' "$1"
}

# === 1. Sanity checks ===
log "[1/6] Verificações iniciais"

[[ "$(id -u)" != "0" ]] || fail "Não rode como root. O script chama sudo quando precisa."
[[ -f /etc/arch-release ]] || fail "Só roda em Arch Linux."
[[ -f "$PKGLIST" ]] || fail "Não encontrei $PKGLIST."
[[ -f "$AURLIST" ]] || fail "Não encontrei $AURLIST."
[[ -d "$DOTFILES_DIR" ]] || fail "Não encontrei $DOTFILES_DIR."

if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
    fail "Repositório [multilib] não habilitado. Rode antes: sudo bash scripts/10-mirrors-pacman.sh"
fi

info "Solicitando privilégios sudo (cache de senha)..."
sudo -v

# === 2. Pacotes oficiais (pacman) ===
log "[2/6] Instalando pacotes oficiais"

mapfile -t PKGS < <(read_list "$PKGLIST")
[[ ${#PKGS[@]} -gt 0 ]] || fail "pkglist.txt sem pacotes válidos (só comentários ou vazio)."
info "${#PKGS[@]} pacotes na lista."
sudo pacman -S --needed --noconfirm "${PKGS[@]}"

# === 3. paru (AUR helper) ===
log "[3/6] Verificando paru"

if command -v paru >/dev/null 2>&1; then
    info "paru já instalado."
else
    info "Compilando paru do AUR..."
    PARU_TMP="$(mktemp -d)"
    trap 'rm -rf "$PARU_TMP"' EXIT
    git clone --depth=1 https://aur.archlinux.org/paru.git "$PARU_TMP/paru"
    (cd "$PARU_TMP/paru" && makepkg -si --noconfirm)
    rm -rf "$PARU_TMP"
    trap - EXIT
fi

# === 4. Pacotes AUR (paru) ===
log "[4/6] Instalando pacotes do AUR"

mapfile -t AUR_PKGS < <(read_list "$AURLIST")
if [[ ${#AUR_PKGS[@]} -eq 0 ]]; then
    info "aurlist.txt vazio, pulando AUR."
else
    info "${#AUR_PKGS[@]} pacotes no AUR list."
    paru -S --needed --noconfirm "${AUR_PKGS[@]}"
fi

# === 5. Runtimes de desenvolvimento ===
log "[5/6] Configurando runtimes (Rust, Python, Node, Java)"

# --- Rust ---
if command -v rustup >/dev/null 2>&1; then
    if rustup show active-toolchain 2>/dev/null | grep -q '^stable'; then
        info "rustup: toolchain stable já ativa."
    else
        info "rustup: instalando toolchain stable..."
        rustup default stable
    fi
else
    warn "rustup não disponível, pulando configuração do Rust."
fi

# --- Python ---
if command -v pyenv >/dev/null 2>&1; then
    PYENV_LATEST="$(pyenv install --list 2>/dev/null \
        | awk '/^\s*3\.[0-9]+\.[0-9]+$/ { gsub(/ /, ""); v=$0 } END { print v }')"

    if [[ -z "$PYENV_LATEST" ]]; then
        warn "pyenv: não consegui detectar última versão do Python 3."
    elif pyenv versions --bare 2>/dev/null | grep -qx "$PYENV_LATEST"; then
        info "pyenv: Python $PYENV_LATEST já instalado."
    else
        info "pyenv: instalando Python $PYENV_LATEST (vai demorar — compila do source)..."
        pyenv install "$PYENV_LATEST"
        pyenv global "$PYENV_LATEST"
    fi
else
    warn "pyenv não disponível, pulando configuração do Python."
fi

# --- Node ---
if command -v fnm >/dev/null 2>&1; then
    # fnm precisa do shell setup pra "default" funcionar fora de sessão zsh ativa.
    # Aqui só garantimos que o LTS está baixado; o setup de PATH já está no .zshrc.
    eval "$(fnm env --shell bash)" 2>/dev/null || true
    if fnm list 2>/dev/null | grep -qE 'v[0-9]+\.[0-9]+\.[0-9]+'; then
        info "fnm: alguma versão do Node já instalada."
    else
        info "fnm: instalando Node LTS..."
        fnm install --lts
        fnm default lts-latest
    fi
else
    warn "fnm não disponível, pulando configuração do Node."
fi

# --- Java (sdkman) ---
SDKMAN_DIR="${SDKMAN_DIR:-$HOME/.sdkman}"
if [[ -d "$SDKMAN_DIR" ]]; then
    info "sdkman: já instalado em $SDKMAN_DIR."
else
    info "sdkman: instalando via script oficial..."
    # rcupdate=false evita modificar ~/.zshrc — o nosso .zshrc já carrega sdkman
    curl -fsSL "https://get.sdkman.io?rcupdate=false" | bash
    info "Para instalar uma JDK depois: 'sdk install java' em um novo shell."
fi

# === 6. Dotfiles via stow ===
log "[6/6] Aplicando dotfiles via stow"

DOTFILE_PKGS=(ghostty lazygit starship tmux vscode zellij zsh)
for pkg in "${DOTFILE_PKGS[@]}"; do
    if [[ ! -d "$DOTFILES_DIR/$pkg" ]]; then
        warn "Dotfile '$pkg' não existe em $DOTFILES_DIR, pulando."
        continue
    fi

    # Simula primeiro para detectar conflitos com arquivos já existentes
    if ! stow -d "$DOTFILES_DIR" -t "$HOME" --no-folding --simulate "$pkg" >/dev/null 2>&1; then
        warn "Conflito em '$pkg'. Faça backup dos arquivos em $HOME que colidem e rode de novo:"
        stow -d "$DOTFILES_DIR" -t "$HOME" --no-folding --simulate "$pkg" || true
        continue
    fi

    info "stow $pkg"
    stow -d "$DOTFILES_DIR" -t "$HOME" --no-folding -R "$pkg"
done

# === Conclusão ===
log "Fase 3 concluída"
cat <<EOF

Próximos passos manuais:
  1. Trocar shell padrão para zsh:
       chsh -s "\$(command -v zsh)"
  2. Abrir um novo terminal para carregar zsh + pyenv + fnm + sdkman.
  3. (Opcional) Instalar uma JDK:
       sdk install java
  4. Instalar as extensões do VS Code listadas em CLAUDE.md nota 16.
  5. Aplicar tema visual (Fase 5):
       ./apply-theme.sh    (ainda a criar)

EOF
# Paleta PeachOS no terminal
PEACH='\033[38;2;232;149;109m'
LAVENDER='\033[38;2;196;168;212m'
RESET='\033[0m'

info()  { printf "${LAVENDER}::${RESET} %s\n" "$*"; }
ok()    { printf "${PEACH}✓${RESET}  %s\n" "$*"; }
warn()  { printf "${PEACH}⚠${RESET}  %s\n" "$*" >&2; }
die()   { printf "${PEACH}✗${RESET}  %s\n" "$*" >&2; exit 1; }

# Limpeza global de dirs temporários, garantida mesmo em erro
TMPDIRS=()
cleanup() {
    local d
    for d in "${TMPDIRS[@]}"; do
        [[ -n "$d" && -d "$d" ]] && rm -rf "$d"
    done
}
trap cleanup EXIT

# Estamos lendo dotfiles/* — habilita nullglob pra não iterar com literal vazio
shopt -s nullglob

# ============================================================
# Pré-checks
# ============================================================

preflight() {
    [[ -f /etc/arch-release ]] || die "PeachOS roda só em Arch Linux."
    [[ $EUID -ne 0 ]]          || die "Não rode como root. O script chama sudo quando precisa."
    command -v sudo &>/dev/null || die "sudo não está instalado."
    [[ -f "$PKGLIST" ]] || die "Lista de pacotes não encontrada: $PKGLIST"
    [[ -f "$AURLIST" ]] || die "Lista AUR não encontrada: $AURLIST"
    # HTTPS em vez de ping: ICMP costuma ser bloqueado em corp/firewall
    curl -fsSI --max-time 5 https://archlinux.org >/dev/null \
        || die "Sem conexão com archlinux.org. Verifica a rede."
    ok "Pré-checks passaram."
}

# ============================================================
# Pacotes — filtra comentários e linhas em branco
# ============================================================

read_pkglist() {
    # tr -d '\r' defende contra arquivos editados no Windows (CRLF colaria no nome)
    tr -d '\r' < "$1" | grep -vE '^\s*(#|$)'
}

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
    TMPDIRS+=("$tmp")   # limpeza fica a cargo do trap EXIT global
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
    # chsh recusa shell ausente em /etc/shells. Em Arch o pacote zsh já registra,
    # mas defendemos contra cenários onde isso falhou.
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
