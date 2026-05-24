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
