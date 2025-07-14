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

echo "Configurando fuso horário..."
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc

echo "Configurando locale..."
if ! grep -q "^$LOCALE" /etc/locale.gen; then
	sed -i "s/^#$LOCALE/$LOCALE/" /etc/locale.gen
fi
locale-gen
echo "LANG=\$LOCALE" > /etc/locale.conf
echo "KEYMAP=\$KEYMAP" > /etc/vconsole.conf

echo "Configurando hostname e hosts..."
echo "\$HOSTNAME" > /etc/hostname
cat <<HOSTS > /etc/hosts
127.0.0.1	localhost
::1		localhost
127.0.1.1	\$HOSTNAME.localdomain \$HOSTNAME
HOSTS

echo "Criando usuário '\$USERNAME' com senha padrão..."

# Define senha do root
echo root:"\$PASSWORD" | chpasswd
useradd -m -G wheel -s /bin/bash "\$USERNAME"
echo "\$USERNAME:\$PASSWORD" | chpasswd

echo "Configurando sudo para grupo wheel..."
if ! grep -q "^%wheel ALL=(ALL:ALL) ALL" /etc/sudoers; then
  echo '%wheel ALL=(ALL:ALL) ALL' >> /etc/sudoers
fi
EOF

echo "Configurações básicas aplicadas com sucesso!"
