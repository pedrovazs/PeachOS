#!/bin/bash

# 06-dev-tools.sh - Instala ferramentas de desenvolvimento e produtividade para PeachOS

echo "[Etapa 06] Instalando ferramentas de desenvolvimento"

arch-chroot /mnt/peachos /bin/bash <<EOF

USERNAME="peach"

# Ativa repositório multilib
sed -i '/\\[multilib]/,/Include/ s/^#//' /etc/pacman.conf
pacman -Sy --noconfirm

# Instalando pacotes oficiais

pacman -S --noconfirm \
    git wget curl unzip \
    base-devel \
    docker docker-compose \
    nodejs npm \
    flatpak \
    flameshot \
    network-manager-applet \
    openssh \
    gparted \
    bat neofetch \
    cmake clang make \
    python python-pip \

# Ativa o Docker para usuário padrão
usermod -aG docker "\$USERNAME"

# Instala o rustup (Ambiente Rust)
su - \$USERNAME -c "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"

# Configura ambiente Rust com componentes úteis
su - \$USERNAME -c "\$HOME/.cargo/bin/rustup default stable"
su - \$USERNAME -c "\$HOME/.cargo/bin/rustup component add clippy rustfmt"
su - \$USERNAME -c "\$HOME/.cargo/bin/cargo install cargo-watch"

# Cria alias para carg-watch
echo "alias cwatch='cargo watch -x run'" >> /home/\$USERNAME/.bashrc

# Instala o yay para pacotes AUR
cd /opt
git clone https://aur.archlinux.org/yay.git
chown -R "\$USERNAME:\$USERNAME" yay
cd yay
su - \$USERNAME -c "cd /opt/yay && makepkg -si --noconfirm"
cd /
rm -rf /opt/yay

# Instala apps AUR (com verificação)
AUR_PKGS=(
    obsidian
    joplin
    ulauncher
    todoist-electron
    clockify-desktop
    ticktick-electron
    habitica-desktop-app
    rescuetime
)

for pkg in \${AUR_PKGS[@]}; do
  if su - \$USERNAME -c "yay -Ss --color never \$pkg | grep -q ^aur/"; then
    su - \$USERNAME -c "yay -S --noconfirm \$pkg"
  else
    echo "⚠️  Pacote AUR '\$pkg' não encontrado. Pulando..."
  fi
done

EOF

echo "Ferramentas de desenvolvimento instaladas com sucesso!"
