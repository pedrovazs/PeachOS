#!/usr/bin/env bash
# Fase 2 — Bloco 7: Performance (zram, sysctl, I/O scheduler, systemd-oomd)
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> [70] Performance"

# --- zram-generator ---
if ! pacman -Qi zram-generator &>/dev/null; then
    echo "  -> Instalando zram-generator..."
    pacman -S --noconfirm zram-generator
fi

echo "  -> Copiando zram-generator.conf..."
cp "$REPO_DIR/system/zram-generator.conf" /etc/systemd/zram-generator.conf

echo "  -> Reiniciando systemd-zram-setup..."
systemctl daemon-reload
systemctl start "systemd-zram-setup@zram0.service" 2>/dev/null || true

if [[ -b /dev/zram0 ]]; then
    echo "  -> zram0 ativo: $(zramctl /dev/zram0 2>/dev/null || swapon --show | grep zram || echo 'verifique com: zramctl')"
fi

# --- sysctl ---
echo "  -> Copiando sysctl.conf..."
cp "$REPO_DIR/system/sysctl.conf" /etc/sysctl.d/99-peachos.conf
sysctl --system 2>/dev/null | grep -E 'vm\.|net\.' | head -10 || true
echo "  -> Parâmetros sysctl aplicados."

# --- I/O scheduler (udev rule) ---
echo "  -> Copiando regra udev de I/O scheduler..."
cp "$REPO_DIR/system/udev/60-ioschedulers.rules" /etc/udev/rules.d/60-ioschedulers.rules
udevadm control --reload-rules
udevadm trigger --type=devices --subsystem-match=block
echo "  -> Regras udev recarregadas."

# --- systemd-oomd ---
echo "  -> Habilitando systemd-oomd (OOM killer do userspace)..."
systemctl enable --now systemd-oomd

echo "==> [70] Concluído."
echo "    zram: zramctl"
echo "    sysctl: sysctl -a | grep vm.swappiness"
