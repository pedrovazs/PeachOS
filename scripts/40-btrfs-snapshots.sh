#!/usr/bin/env bash
# Fase 2 — Bloco 4: Snapshots Btrfs com snapper e grub-btrfs
# Configura snapper para / e /home, habilita timers e integra ao GRUB.
# ATENÇÃO: rodar ANTES de 50-grub-dualboot.sh e SÓ após ter pelo menos um snapshot.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> [40] Btrfs + snapper + grub-btrfs"

PKGS=(snapper snap-pac grub-btrfs inotify-tools)
echo "  -> Instalando pacotes..."
pacman -S --noconfirm --needed "${PKGS[@]}"

# --- snapper: config para root ---
if [[ ! -f /etc/snapper/configs/root ]]; then
    echo "  -> Criando config snapper para root..."
    snapper -c root create-config /
else
    echo "  -> Config snapper 'root' já existe, pulando criação."
fi

echo "  -> Copiando config snapper root..."
cp "$REPO_DIR/system/snapper/root.conf" /etc/snapper/configs/root

# --- snapper: config para home ---
if [[ ! -f /etc/snapper/configs/home ]]; then
    echo "  -> Criando config snapper para home..."
    snapper -c home create-config /home
else
    echo "  -> Config snapper 'home' já existe, pulando criação."
fi

echo "  -> Copiando config snapper home..."
cp "$REPO_DIR/system/snapper/home.conf" /etc/snapper/configs/home

# --- permissões do diretório .snapshots ---
# Snapper cria /.snapshots como subvolume separado, que pode conflitar com @.snapshots
# Verificar e ajustar se necessário
if btrfs subvolume list / | grep -q '\.snapshots'; then
    echo "  -> Subvolume .snapshots detectado (correto)."
else
    echo "  AVISO: subvolume .snapshots não detectado. Snapper pode não ter conseguido criar."
    echo "  Verifique manualmente: btrfs subvolume list /"
    echo "  Se faltar, pode ser necessário criar: btrfs subvolume create /.snapshots"
fi

# --- timers ---
echo "  -> Habilitando timers do snapper..."
systemctl enable --now snapper-timeline.timer
systemctl enable --now snapper-cleanup.timer

# --- grub-btrfs ---
# grub-btrfs.path foi depreciado; o daemon correto é grub-btrfsd.service (requer inotify-tools)
echo "  -> Habilitando grub-btrfsd.service (monitora novos snapshots)..."
systemctl enable --now grub-btrfsd.service

# Criar snapshot inicial antes de gerar GRUB
echo "  -> Criando snapshot inicial de root..."
snapper -c root create --description "pós-instalação fase2-bloco4"

echo ""
echo "  -> Gerando grub.cfg com entradas de snapshots..."
grub-mkconfig -o /boot/grub/grub.cfg

echo "==> [40] Concluído."
echo "    Snapshots disponíveis: snapper -c root list"
