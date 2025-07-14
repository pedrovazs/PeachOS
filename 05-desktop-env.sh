#!/bin/bash

# 05-desktop-env.sh - Instala o ambiente gráfico GNOME com personalização para PeachOS

echo "[Etapa 05] Instalando o ambiente GNOME..."

# Executa dentro do sistema recém-instalado
arch-chroot /mnt /bin/bash <<EOF

echo "Instalando GNOME e componentes essenciais..."
pacman -S --noconfirm gdm gnome-shell gnome-shell-extensions gnome-tweaks xdg-user-dirs-gtk

echo "Instalando temas, ícones e fontes..."
pacman -S --noconfirm papirus-icon-theme ttf-fira-code ttf-roboto ttf-ubuntu-font-family ttf-jetbrains-mono

echo "Criando diretórios padrão do usuário..."

USERNAME="momotaro"

if id "\$USERNAME" &>/dev/null; then
	su - "\$USERNAME" -c "xdg-user-dirs-update"
else
	echo "Usuário '\$USERNAME' não existe. Pulando a criação dos diretórios padrão."
fi

EOF

if [ $? -eq 0 ]; then
	echo "Ambiente GNOME instalado com sucesso!"
else
	echo "Falha na instalação do ambiente GNOME."
fi
