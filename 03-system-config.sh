#!/bin/bash

# 03-system-config.sh - Configura fuso horário, locale, hostname e usuário

echo "[Etapa 03] Configurando o sistema..."

# Chroot para /mnt
arch-chroot /mnt /bin/bash <<EOF

# Definições básicas
HOSTNAME="PeachOS"
USERNAME="momotaro"
PASSWORD="peach123"
LOCALE="pt_BR.UTF-8"
KEYMAP="br-abnt2"

echo "Configurando timezone"

ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime

hwclock --systohc

echo "Configurando locale..."
sed -i "s/#$LOCALE/$LOCALE/" /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

echo "Configurando hosname e hosts..."
echo "$HOSTNAME" > /etc/hostname
cat <<HOSTS > /etc/hosts

127.0.0.1	localhost
::1		localhost
127.0.1.1	$HOSTNAME.localdomain $HOSTNAME
HOSTS

echo "Criando usuário '$USERNAME' com senha padrão..."

# Define senha do root
echo root:"$PASSWORD" | chpasswd

# Cria usuário comum e defino grupo wheel (sudo)
useradd -m -G wheel "$USERNAME"
echo "$USERNAME:$PASSWORD" | chpasswd

# Ativa sudo para o grupo wheel
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

EOF

echo "Configurações básicas aplicadas com sucesso!"
