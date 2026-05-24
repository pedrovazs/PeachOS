#!/usr/bin/env bash
# apply-theme-system.sh — PeachOS
# Fase 5: aplica tema do sistema (precisa de sudo).
# Cobertura atual: GRUB. Plymouth e GDM serão adicionados em iterações
# seguintes da Fase 5.
#
# Para a parte de usuário (gsettings, Gradience, extensões) ver
# apply-theme-user.sh.
# Executar: sudo ./apply-theme-system.sh

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GRUB_THEME_SRC="${REPO_DIR}/themes/grub"
GRUB_THEME_DEST="/boot/grub/themes/peachos"
GRUB_DEFAULTS="/etc/default/grub"
GRUB_CFG="/boot/grub/grub.cfg"

# Fonte do sistema usada para gerar os .pf2 do GRUB. DejaVu é dependência
# universal no Arch (puxada por várias coisas) e cobre acentos PT-BR.
FONT_REGULAR="/usr/share/fonts/TTF/DejaVuSans.ttf"
FONT_BOLD="/usr/share/fonts/TTF/DejaVuSans-Bold.ttf"

log()  { echo "  [theme-system] $*"; }
fail() { echo "ERRO: $*" >&2; exit 1; }

check_root() {
    if [[ ${EUID} -ne 0 ]]; then
        fail "Precisa de root. Rode com: sudo $0"
    fi
}

check_grub_installed() {
    if ! command -v grub-mkconfig &>/dev/null; then
        fail "grub-mkconfig não encontrado. GRUB não está instalado?"
    fi
    if [[ ! -f ${GRUB_DEFAULTS} ]]; then
        fail "${GRUB_DEFAULTS} não existe. Rode scripts/50-grub-dualboot.sh antes."
    fi
}

generate_grub_fonts() {
    if ! command -v grub-mkfont &>/dev/null; then
        log "grub-mkfont não encontrado — pulando geração de fontes (GRUB usará fallback)."
        return
    fi

    if [[ ! -f ${FONT_REGULAR} || ! -f ${FONT_BOLD} ]]; then
        log "DejaVu Sans não instalado (${FONT_REGULAR}) — pulando geração de fontes."
        log "Instale com: pacman -S ttf-dejavu"
        return
    fi

    log "Gerando .pf2 (DejaVu Sans Regular 11/12/14/16, Bold 24)"
    local size
    for size in 11 12 14 16; do
        grub-mkfont -s "${size}" -n "DejaVu Sans Regular" \
            -o "${GRUB_THEME_DEST}/dejavu-regular-${size}.pf2" \
            "${FONT_REGULAR}"
    done
    grub-mkfont -s 24 -n "DejaVu Sans Bold" \
        -o "${GRUB_THEME_DEST}/dejavu-bold-24.pf2" \
        "${FONT_BOLD}"
}

install_grub_theme() {
    log "Instalando tema em ${GRUB_THEME_DEST}"
    mkdir -p "${GRUB_THEME_DEST}"
    install -m 0644 "${GRUB_THEME_SRC}/theme.txt" "${GRUB_THEME_DEST}/theme.txt"
}

configure_grub_defaults() {
    # Garante que GRUB_THEME aponta para o tema PeachOS. Aceita tanto a linha
    # comentada quanto uma já existente (idempotente).
    local theme_line="GRUB_THEME=\"${GRUB_THEME_DEST}/theme.txt\""

    if grep -qE '^GRUB_THEME=' "${GRUB_DEFAULTS}"; then
        log "GRUB_THEME já definido, atualizando para o caminho PeachOS"
        sed -i -E "s|^GRUB_THEME=.*|${theme_line}|" "${GRUB_DEFAULTS}"
    elif grep -qE '^#\s*GRUB_THEME=' "${GRUB_DEFAULTS}"; then
        log "Descomentando GRUB_THEME em ${GRUB_DEFAULTS}"
        sed -i -E "s|^#\s*GRUB_THEME=.*|${theme_line}|" "${GRUB_DEFAULTS}"
    else
        log "Anexando GRUB_THEME em ${GRUB_DEFAULTS}"
        printf '\n%s\n' "${theme_line}" >> "${GRUB_DEFAULTS}"
    fi
}

regenerate_grub_config() {
    log "Regenerando ${GRUB_CFG}"
    grub-mkconfig -o "${GRUB_CFG}"
}

apply_grub_theme() {
    log "=== GRUB ==="
    check_grub_installed
    install_grub_theme
    generate_grub_fonts
    configure_grub_defaults
    regenerate_grub_config
}

# ── main ──────────────────────────────────────────────────────────────────────
check_root
log "Iniciando apply-theme-system (PeachOS)"

apply_grub_theme
# TODO Fase 5: apply_plymouth_theme, apply_gdm_theme

log "Tema de sistema aplicado. Reinicie para ver o novo GRUB."
