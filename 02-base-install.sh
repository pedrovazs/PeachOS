#!/bin/bash

# 02-base-install.sh - Instala os pacotes base do ArchLinux

echo "[Etapa 02] Instalando o sistema base..."

# Verifica se /mnt esta montado corretamente
if ! mountpoint -q /mnt; then
	echo "/mnt não está montado! Execute o módulo 01-disk-setup.sh antes."
	exit 1
fi

# Instalação do sistema base
pacstrap -K /mnt \
	base \
	base-devel \
	linux-lts \
	linux-firmware \
	btrfs-progs \
	nano \
	networkmanager \
	grub \
	efibootmgr \
	sudo \
	git \
	curl \
	reflector \
	man-db \
	bash-completion

# Geração do fstab com UUIDs
genfstab -U /mnt >> /mnt/etc/fstab

echo "Sistema base instalado com sucesso!"
