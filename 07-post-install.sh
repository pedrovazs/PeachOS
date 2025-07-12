#!/bin/bash

# 07-post-install.sh - Otimizações, segurança e ajustes finais

echo "[Etapa 07] Aplicando configurações de segurança e desempenho..."

arch-chroot /mnt /bin/bash <<EOF

USERNAME="peach"

echo "Instalando pacotes de segurança..."
pacman -S --noconfirm \
  ufw fail2ban apparmor firejail auditd \
  timeshift grub-btrfs logwatch cronie \
  dtrace systemtap bpftrace

echo "Ativando firewall UFW..."
ufw default deny incoming
ufw default allow outgoing
ufw enable
systemctl enable ufw

echo "Ativando AppArmor..."
systemctl enable apparmor
aa-complain /etc/apparmor.d/*

echo "Ativando Fail2ban..."
systemctl enable fail2ban

echo "Protegendo apps com Firejail..."
firecfg

echo "Ativando auditoria de sistema..."
systemctl enable auditd

echo "Habilitando snapshots automáticos com Timeshift..."
timeshift --create --comments \"Instalação inicial do PeachOS\" --tags D

echo "Integrando Timeshift ao GRUB via grub-btrfs..."
mkdir -p /etc/grub.d
grub-mkconfig -o /boot/grub/grub.cfg

echo "Ativando cron para tarefas agendadas..."
systemctl enable cronie

echo "Limpando pacotes órfãos e atualizando..."
pacman -Rns --noconfirm \$(pacman -Qtdq) || true
pacman -Syu --noconfirm

EOF

echo "✅ Segurança, desempenho e manutenção configurados!"
