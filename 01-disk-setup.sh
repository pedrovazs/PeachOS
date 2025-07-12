#!/bin/bash

# 01-disk-setup.sh - Prepara o disco para instalação do PeachOS usando o Btrfs

echo "[Etapa-01 Iniciando a preparação do disco...]"

# Exibe os discos disponíveis
lsblk -d -e 7,11 -o NAME,SIZE,MODEL

# Solicita ao usuário o disco de destino
read -rp "Digite o caminho do disco (ex: /dev/sda ou /dev/nvme0n1): " DISK

# Confirmação
read -rp "Todos os dados em $DISK serão apagados. Deseja continuar? (s/N): " CONFIRMA
if [[ "$CONFIRMA" != "s" && "$CONFIRMA" != "S" ]]; then
	echo "Instalação abortada pelo usuário."
	exit 1
fi

echo "Apagando tabela de partição e criando novas partições em GPT..."

# Criação das partições
parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart ESP fat32 1MiB 512MiB
parted -s "$DISK" set 1 esp on
parted -s "$DISK" mkpart primary btrfs 512MiB 100%

# Identifica partições
ESP="${DISK}1"
ROOT="${DISK}2"

# Formatação das partições
mkfs.fat -F32 "$ESP"
mkfs.btrfs -f "$ROOT"

# Montagem temporária
mount "$ROOT" /mnt

# Criação dos subvolumes
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@pkg
btrfs subvolume create /mnt/@snapshots

umount /mnt

# Montagem definitiva com subvolumes
mount -o noatime,compress=zstd,space_cache=v2,subvol=@ "$ROOT" /mnt

mkdir -p /mnt/{boot,home,var/log,var/cache/pacman/pkg,.snapshots}

mount -o noatime,compress=zstd,space_cache=v2,subvol=@home "$ROOT" /mnt/home
mount -o noatime,compress=zstd,space_cache=v2,subvol=@log "$ROOT" /mnt/var/log
mount -o noatime,compress=zstd,space_cache=v2,subvol=@pkg "$ROOT" /mnt/var/cache/pacman/pkg
mount -o noatime,compress=zstd,space_cache=v2,subvol=@snapshots "$ROOT" /mnt/.snapshots
mount "$ESP" /mnt/boot

echo "Disco $DISK particionado, formatado e montado com sucesso!"

