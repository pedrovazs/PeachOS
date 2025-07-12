#!/bin/bash

# 05-desktop-env.sh - Instala o ambiente gráfico GNOME com personalização para PeachOS

echo "[Etapa 05] Instalando o ambiente GNOME..."

# Executa dentro do sistema recém-instalado
arch-chroot /mnt /bin/bash <<EOF

echo "Instalando GNOME e componentes essenciais..."
pacman -S --noconfirm gdm gnome-shell gnome-shell-extensions gnome-tweaks xdg-user-dirs-gtk

echo "Instalando temas, ícones e fontes..."
pacman -S --noconfirm arc-gtk-theme papirus-icon-theme ttf-fira-code ttf-roboto ttf-ubuntu-font-family ttf-jetbrains-mono

echo "Habilitando o GDM (GNOME Display Manager)..."
systemctl enable gdm

echo "Criando diretórios padrão do usuário..."
su - peach -c "xdg-user-dirs-update"

EOF

echo "Ambiente GNOME instalado com sucesso!"
