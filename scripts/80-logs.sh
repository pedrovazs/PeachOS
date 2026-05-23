#!/usr/bin/env bash
# Fase 2 — Bloco 8: Logs (journald compactado, limite de tamanho)
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> [80] Logs (journald)"

echo "  -> Copiando journald.conf..."
cp "$REPO_DIR/system/journald.conf" /etc/systemd/journald.conf

echo "  -> Reiniciando systemd-journald..."
systemctl restart systemd-journald

echo "  -> Limpando logs antigos acima do limite configurado..."
journalctl --vacuum-size=200M

echo "  -> Estado atual do journal:"
journalctl --disk-usage

echo "==> [80] Concluído."
