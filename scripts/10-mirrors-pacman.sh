#!/usr/bin/env bash
# Fase 2 — Bloco 1: Mirrors e configuração do pacman
# Instala reflector, gera mirrorlist otimizado para o Brasil e aplica pacman.conf.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> [10] Mirrors e pacman"

# --- reflector ---
if ! pacman -Qi reflector &>/dev/null; then
    echo "  -> Instalando reflector..."
    pacman -S --noconfirm reflector
fi

echo "  -> Copiando reflector.conf..."
cp "$REPO_DIR/system/reflector.conf" /etc/xdg/reflector/reflector.conf

echo "  -> Gerando mirrorlist (pode levar alguns segundos)..."
reflector --config /etc/xdg/reflector/reflector.conf --save /etc/pacman.d/mirrorlist

echo "  -> Habilitando reflector.timer semanal..."
systemctl enable --now reflector.timer

# --- pacman.conf ---
echo "  -> Copiando pacman.conf..."
cp "$REPO_DIR/system/pacman/pacman.conf" /etc/pacman.conf

echo "  -> Sincronizando bases de dados..."
pacman -Sy

echo "==> [10] Concluído."
