#!/usr/bin/env bash
# Fase 2 — Bloco 5: GRUB com dual boot Windows
# Habilita os-prober e regenera grub.cfg para detectar o Windows.
# Rodar DEPOIS do bloco 40 (grub-btrfs já configurado).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> [50] GRUB dual boot"

# --- os-prober ---
if ! pacman -Qi os-prober &>/dev/null; then
    echo "  -> Instalando os-prober..."
    pacman -S --noconfirm os-prober
fi

# --- /etc/default/grub ---
echo "  -> Copiando /etc/default/grub..."
cp "$REPO_DIR/system/grub" /etc/default/grub

# Verificar se GRUB_DISABLE_OS_PROBER está desabilitado (deve ser false)
if grep -q 'GRUB_DISABLE_OS_PROBER=false' /etc/default/grub; then
    echo "  -> os-prober habilitado no grub config."
else
    echo "  ERRO: GRUB_DISABLE_OS_PROBER=false não encontrado em /etc/default/grub."
    exit 1
fi

# --- detectar partições Windows ---
echo "  -> Rodando os-prober para detectar outros sistemas..."
os-prober || true  # os-prober retorna 1 se não encontrar nada, não é erro fatal

# --- regenerar grub.cfg ---
echo "  -> Gerando grub.cfg..."
mountpoint -q /boot || { echo "  ERRO: /boot não está montado. Monte antes de gerar o grub.cfg."; exit 1; }
grub-mkconfig -o /boot/grub/grub.cfg

# Verificar se Windows foi detectado
if grep -qi 'windows' /boot/grub/grub.cfg; then
    echo "  -> Windows detectado no grub.cfg."
else
    echo ""
    echo "  AVISO: Windows não detectado."
    echo "  Possíveis causas:"
    echo "    - VM sem partição Windows montável"
    echo "    - Partição EFI do Windows não visível"
    echo "    - Normal se estiver só na VM (dual boot só na máquina física)"
fi

echo "==> [50] Concluído."
