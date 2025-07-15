#!/bin/bash

# 07-post-install.sh - Otimizações, segurança e ajustes finais

echo "[Etapa 07] Aplicando configurações de segurança e desempenho..."

arch-chroot /mnt /bin/bash <<EOF


echo "Instalando pacotes de segurança..."
pacman -S --noconfirm \
  ufw fail2ban apparmor firejail auditd \
  timeshift grub-btrfs logwatch cronie \
  systemtap bpftrace

echo "Ativando firewall UFW..."
ufw default deny incoming
ufw default allow outgoing
ufw enable
systemctl enable ufw

echo "Ativando AppArmor..."
systemctl enable apparmor
find /etc/apparmor.d/ -type f -exec aa-enforce {} \;

echo "Ativando Fail2ban..."
systemctl enable fail2ban

echo "Protegendo apps com Firejail..."
firecfg

echo "Ativando auditoria de sistema..."
systemctl enable auditd

echo "Habilitando snapshots automáticos com Timeshift..."
systemctl enable timeshift.timer

echo "Integrando Timeshift ao GRUB via grub-btrfs..."
# Atualizando configuração do GRUB; execute 'update-grub' se necessário em sua distribuição
grub-mkconfig -o /boot/grub/grub.cfg
# update-grub  # Descomente se sua distribuição utiliza este comando

echo "Ativando cron para tarefas agendadas..."
systemctl enable cronie

echo "Ativando GDM"
systemctl enable gdm

echo "Limpando pacotes órfãos e atualizando..."
orphans=\$(pacman -Qtdq)
if [ -n "\$orphans" ]; then
  pacman -Rns --noconfirm \$orphans
fi
pacman -Syu --noconfirm

EOF

echo "Segurança, desempenho e manutenção configurados!"
