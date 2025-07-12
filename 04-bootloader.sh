#!/bin/bash

# 04-bootloader.sh - Instala e configura o bootloader GRUB com suporte a EFI e BTRFS

echo "[Etapa 04] Instalando e configurando o bootloader..."

# Verifica se /mnt está montado corretamente
if ! mountpoint -1 /mnt/boot; then
    echo "/mnt/boot não está montado. Execute o módulo 01-disk-setup.sh antes"
    echo 1
fi

# Executa instalação dentro do sistema novo
arch-chroot /mnt /bin/bash <<EOF

# Cria o diretório EFI (caso não exista)
mkdir -p /boot/EFI

# Instala o GRUB no modo UEFI
grub install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

# Cria diretório de configuração extra para GRUB
mkdir -p /etc/default/grub.d

# Desativa submenu para facilitar com snapshots BTRFS
echo "GRUB_DISABLE_SUBMENU=y" >> /etc/default/grub.d/peachos.cfg

# Gera configuração final do GRUB
grub-mkconfig -o /boot/grub/grub.cfg

EOF

echo "Bootloader instalado e configurado com sucesso!"
