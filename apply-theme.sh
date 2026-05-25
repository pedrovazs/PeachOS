#!/usr/bin/env bash
# apply-theme.sh — PeachOS
# Fase 5: orquestrador de tema — chama apply-theme-user.sh (sessão do usuário)
# e apply-theme-system.sh (GRUB, Plymouth, GDM, requer sudo).
#
# Rodar como usuário normal, sem sudo. A parte de sistema solicita sudo
# internamente quando necessário.
#
# Uso:
#   ./apply-theme.sh                  # aplica tudo (user + system)
#   ./apply-theme.sh --user-only      # só sessão do usuário
#   ./apply-theme.sh --system-only    # só sistema (GRUB, Plymouth, GDM)

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_SCRIPT="${REPO_DIR}/apply-theme-user.sh"
SYSTEM_SCRIPT="${REPO_DIR}/apply-theme-system.sh"

log()  { echo "[apply-theme] $*"; }
fail() { echo "ERRO: $*" >&2; exit 1; }

RUN_USER=true
RUN_SYSTEM=true

case "${1:-}" in
    --user-only)   RUN_SYSTEM=false ;;
    --system-only) RUN_USER=false   ;;
    "")            ;;
    *) echo "Uso: $0 [--user-only | --system-only]" >&2; exit 1 ;;
esac

if [[ ${EUID} -eq 0 ]]; then
    fail "Rode sem sudo. O script pede sudo para a parte de sistema quando necessário."
fi

[[ -x "${USER_SCRIPT}"   ]] || fail "${USER_SCRIPT} não encontrado ou não executável."
[[ -x "${SYSTEM_SCRIPT}" ]] || fail "${SYSTEM_SCRIPT} não encontrado ou não executável."

if ${RUN_USER}; then
    log "─── Parte de usuário ────────────────────────────────────────────────────"
    bash "${USER_SCRIPT}"
fi

if ${RUN_SYSTEM}; then
    log "─── Parte de sistema (requer sudo) ──────────────────────────────────────"
    sudo bash "${SYSTEM_SCRIPT}"
fi

log "Tema PeachOS aplicado. Reinicie o GNOME Shell (Alt+F2 → r) se necessário."
