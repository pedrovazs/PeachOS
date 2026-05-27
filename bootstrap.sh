#!/usr/bin/env bash
# bootstrap.sh — PeachOS
# Fase 7: orquestrador pós-instalação base.
#
# Pré-requisitos:
#   - Arch Linux instalado via archinstall e bootado
#   - Fase 2 concluída (scripts/10-99 executados; paru deve estar presente)
#
# O que faz:
#   1. Verifica pré-requisitos (Fase 2 concluída)
#   2. Roda install.sh   — pacotes, runtimes, dotfiles (Fase 3)
#   3. Roda apply-theme.sh — identidade visual (Fase 5)
#      Se não estiver em sessão GNOME, aplica só a parte de sistema
#      (GRUB + Plymouth + GDM) e imprime lembrete para a parte de usuário.
#
# Uso:
#   ./bootstrap.sh                 # fluxo completo
#   ./bootstrap.sh --install-only  # só install.sh
#   ./bootstrap.sh --theme-only    # só apply-theme.sh
#
# Idempotente: pode ser rodado mais de uma vez sem quebrar.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
INSTALL_SCRIPT="${REPO_DIR}/install.sh"
THEME_SCRIPT="${REPO_DIR}/apply-theme.sh"

# Paleta PeachOS (mesma do install.sh)
PEACH=$'\033[38;2;232;149;109m'
LAVENDER=$'\033[38;2;196;168;212m'
RESET=$'\033[0m'

info() { printf "${LAVENDER}::${RESET} %s\n" "$*"; }
ok()   { printf "${PEACH}✓${RESET}  %s\n" "$*"; }
warn() { printf "${PEACH}⚠${RESET}  %s\n" "$*" >&2; }
die()  { printf "${PEACH}✗${RESET}  %s\n" "$*" >&2; exit 1; }

RUN_INSTALL=true
RUN_THEME=true

case "${1:-}" in
    --install-only) RUN_THEME=false   ;;
    --theme-only)   RUN_INSTALL=false ;;
    "")             ;;
    *) printf "Uso: %s [--install-only | --theme-only]\n" "$0" >&2; exit 1 ;;
esac

# ============================================================
# Pré-checks exclusivos do bootstrap
# (root/arch/rede são verificados pelo install.sh no seu próprio preflight)
# ============================================================

check_not_root() {
    [[ $EUID -ne 0 ]] || die "Rode sem sudo. Os scripts filhos chamam sudo quando precisam."
}

check_phase2() {
    # paru é o último artefato instalado pela Fase 2 (bloco 99).
    # Se não existe, quase certamente a Fase 2 não foi concluída.
    if ! command -v paru &>/dev/null; then
        die "paru não encontrado — a Fase 2 precisa ser concluída primeiro.
     Execute em sequência os scripts em scripts/ (10 → 99) e rode o bootstrap novamente."
    fi
}

check_scripts() {
    [[ -x "${INSTALL_SCRIPT}" ]] || die "${INSTALL_SCRIPT} não encontrado ou não executável."
    [[ -x "${THEME_SCRIPT}"   ]] || die "${THEME_SCRIPT} não encontrado ou não executável."
}

# Sessão GNOME ativa: gsettings disponível + D-Bus de sessão presente.
# Mesma lógica usada por apply-theme-user.sh.
in_gnome_session() {
    command -v gsettings &>/dev/null && [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]]
}

# ============================================================
# main
# ============================================================

check_not_root
check_phase2
check_scripts

printf "\n${PEACH}━━━ PeachOS bootstrap ━━━${RESET}\n\n"
info "Diretório do repo: ${REPO_DIR}"

# ── Fase 3: install.sh ────────────────────────────────────────────────────────
if ${RUN_INSTALL}; then
    printf "\n${LAVENDER}▶ Fase 3 — install.sh${RESET}\n\n"
    bash "${INSTALL_SCRIPT}"
    ok "install.sh concluído"
fi

# ── Fase 5: apply-theme.sh ────────────────────────────────────────────────────
if ${RUN_THEME}; then
    printf "\n${LAVENDER}▶ Fase 5 — apply-theme.sh${RESET}\n\n"
    if in_gnome_session; then
        bash "${THEME_SCRIPT}"
        ok "Tema PeachOS aplicado (user + system)"
    else
        warn "Sessão GNOME não detectada — aplicando só a parte de sistema (GRUB + Plymouth + GDM)."
        bash "${THEME_SCRIPT}" --system-only
        ok "Tema de sistema aplicado"
        THEME_USER_PENDING=true
    fi
fi

# ── Resumo ────────────────────────────────────────────────────────────────────
printf "\n${PEACH}━━━ Concluído ━━━${RESET}\n\n"
info "Próximos passos:"
info "  1. Logout e login, ou reinicie, para entrar no zsh."
info "  2. Reinicie para ver o GRUB e o Plymouth com o tema PeachOS."
if [[ "${THEME_USER_PENDING:-}" == true ]]; then
    info "  3. No primeiro login GNOME, rode:"
    info "       ./apply-theme.sh --user-only"
    info "     para aplicar fontes, extensões, modo escuro e Gradience."
fi
printf "\n"
