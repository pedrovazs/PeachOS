#!/usr/bin/env bash
# Fase 2 — Bloco 2: Áudio via PipeWire
# Remove PulseAudio se presente e instala PipeWire completo.
set -euo pipefail

echo "==> [20] Áudio (PipeWire)"

# --- remover PulseAudio se instalado ---
PULSE_PKGS=(pulseaudio pulseaudio-alsa pulseaudio-bluetooth pulseaudio-jack)
for pkg in "${PULSE_PKGS[@]}"; do
    if pacman -Qi "$pkg" &>/dev/null; then
        echo "  -> Removendo $pkg..."
        pacman -Rns --noconfirm "$pkg"
    fi
done

# --- instalar PipeWire ---
PIPEWIRE_PKGS=(
    pipewire
    pipewire-alsa
    pipewire-pulse
    pipewire-jack
    wireplumber
    gst-plugin-pipewire
    libpulse
)

echo "  -> Instalando PipeWire..."
pacman -S --noconfirm --needed "${PIPEWIRE_PKGS[@]}"

# wireplumber e pipewire são serviços de usuário — habilitados pelo usuário, não pelo root
echo ""
echo "  ATENÇÃO: execute como usuário comum (não root):"
echo "    systemctl --user enable --now pipewire pipewire-pulse wireplumber"
echo ""
echo "  Para verificar:"
echo "    wpctl status"

echo "==> [20] Concluído."
