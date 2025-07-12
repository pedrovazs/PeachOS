#!/bin/bash

# 05-desktop-env.sh - Instala o ambiente gráfico GNOME com personalização para PeachOS

echo "[Etapa 05] Instalando o ambiente GNOME..."

# Executa dentro do sistema recém-instalado
arch-chroot /mnt /bin/bash <<EOF

echo "Instalando GNOME e componentes essenciais..."
GNOME_PACKAGES=(gdm gnome-shell gnome-shell-extensions gnome-tweaks xdg-user-dirs-gtk)
pacman -S --noconfirm "${GNOME_PACKAGES[@]}"
echo "Instalando temas, ícones e fontes..."
THEME_PACKAGES="arc-gtk-theme papirus-icon-theme"
FONT_PACKAGES="ttf-fira-code ttf-roboto ttf-ubuntu-font-family ttf-jetbrains-mono"
pacman -S --noconfirm $THEME_PACKAGES $FONT_PACKAGES
THEME_PACKAGES=(arc-gtk-theme papirus-icon-theme ttf-fira-code ttf-roboto ttf-ubuntu-font-family ttf-jetbrains-mono)
pacman -S --noconfirm "${THEME_PACKAGES[@]}"

echo "Habilitando o GDM (GNOME Display Manager)..."
systemctl enable gdm

echo "Criando diretórios padrão do usuário..."

# Defina o nome do usuário (pode ser passado como argumento ou definido aqui)
USERNAME="${1:-peach}"

if id "$USERNAME" &>/dev/null; then
	su - "$USERNAME" -c "xdg-user-dirs-update"
else
	echo "Usuário '$USERNAME' não existe. Pule a criação dos diretórios padrão."
EOF

if [ $? -eq 0 ]; then
	echo "Ambiente GNOME instalado com sucesso!"
else
	echo "Falha na instalação do ambiente GNOME."
fi
