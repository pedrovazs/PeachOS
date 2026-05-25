#!/usr/bin/env bash
# apply-theme-user.sh — PeachOS
# Fase 5: aplica tema na sessão do usuário corrente (sem sudo).
# Cobre: modo escuro, accents, ícones, fontes, Gradience (libadwaita),
#        extensões GNOME e Night Theme Switcher.
#
# Requer: sessão GNOME ativa (gsettings e dconf precisam de D-Bus).
# Para a parte de sistema (GRUB, Plymouth, GDM) ver apply-theme-system.sh.
# Executar: ./apply-theme-user.sh

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRESET_SRC="${REPO_DIR}/themes/gradience/PeachOS.json"
PRESET_DEST="${HOME}/.config/presets/user/PeachOS.json"

log()  { echo "  [theme-user] $*"; }
fail() { echo "ERRO: $*" >&2; exit 1; }

check_gnome_session() {
    if ! command -v gsettings &>/dev/null; then
        fail "gsettings não encontrado. Rode dentro de uma sessão GNOME."
    fi
    if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
        fail "D-Bus não detectado. Execute o script dentro da sessão gráfica."
    fi
}

apply_gnome_base() {
    log "Modo escuro + accents"
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null || \
        gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
    gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
    gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita'
    gsettings set org.gnome.desktop.interface cursor-size 24

    log "Fontes"
    gsettings set org.gnome.desktop.interface font-name          'Noto Sans 11'
    gsettings set org.gnome.desktop.interface document-font-name 'Noto Sans 11'
    gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 12'
    gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Noto Sans Bold 11'

    log "Comportamento de janelas"
    gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
    gsettings set org.gnome.desktop.interface enable-animations true

    log "Workspaces"
    gsettings set org.gnome.mutter dynamic-workspaces true
    gsettings set org.gnome.desktop.wm.preferences num-workspaces 4
}

apply_gradience() {
    if ! command -v gradience-cli &>/dev/null; then
        log "gradience-cli não instalado — pulando preset libadwaita."
        return
    fi

    log "Instalando preset Gradience"
    mkdir -p "$(dirname "${PRESET_DEST}")"
    cp "${PRESET_SRC}" "${PRESET_DEST}"

    log "Aplicando preset PeachOS"
    gradience-cli apply --preset-path "${PRESET_DEST}" --gtk all
}

enable_extensions() {
    if ! command -v gnome-extensions &>/dev/null; then
        log "gnome-extensions não encontrado — pulando ativação automática."
        return
    fi

    # IDs das 12 extensões PeachOS (devem estar instaladas via paru)
    local extensions=(
        "user-theme@gnome-shell-extensions.gcampax.github.com"
        "appindicatorsupport@rgcjonas.gmail.com"
        "nightthemeswitcher@romainvigier.fr"
        "gTile@vibou"
        "dash-to-panel@jderose9.github.com"
        "caffeine@patapon.info"
        "clipboard-indicator@tudmotu.com"
        "blur-my-shell@aunetx"
        "just-perfection-desktop@just-perfection"
        "gsconnect@andyholmes.github.io"
        "Vitals@CoreCoding.com"
        "rounded-window-corners@fxgn"
    )

    log "Ativando extensões"
    for ext_id in "${extensions[@]}"; do
        if gnome-extensions list --installed | grep -qF "${ext_id}"; then
            gnome-extensions enable "${ext_id}" 2>/dev/null && \
                log "  ✓ ${ext_id}" || \
                log "  ! falha ao ativar ${ext_id}"
        else
            log "  - ${ext_id} não instalado, pulando"
        fi
    done
}

configure_night_theme_switcher() {
    local schema="org.gnome.shell.extensions.nightthemeswitcher"
    if ! gsettings list-schemas 2>/dev/null | grep -qF "${schema}"; then
        log "Night Theme Switcher não instalado — pulando configuração."
        return
    fi

    log "Night Theme Switcher: modo manual por horário"
    # Sunset/sunrise automático: desativado. Horário fixo para Brasil Central.
    gsettings set "${schema}.time" enabled true
    gsettings set "${schema}.time" sunrise '06:00'
    gsettings set "${schema}.time" sunset  '18:00'
    gsettings set "${schema}.gtk-variants" day   'default'
    gsettings set "${schema}.gtk-variants" night 'dark'
}

# ── main ──────────────────────────────────────────────────────────────────────
check_gnome_session
log "Iniciando apply-theme-user (PeachOS)"

apply_gnome_base
apply_gradience
enable_extensions
configure_night_theme_switcher

log "Tema de usuário aplicado. Reinicie o GNOME Shell (Alt+F2 → r) se necessário."
