#!/bin/bash

# 06-dev-tools.sh - Instala ferramentas de desenvolvimento e produtividade para PeachOS

echo "[Etapa 06] Instalando ferramentas de desenvolvimento"

arch-chroot /mnt/home /bin/bash <<EOF

USERNAME="momotaro"

# Ativa repositório multilib
# Garante que [multilib] e Include estejam descomentados
sed -i '/^\s*#\s*\[multilib\]/s/^#\s*//; /^\s*#\s*Include = \/etc\/pacman.d\/mirrorlist/s/^#\s*//' /etc/pacman.conf
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
grep -qxF "alias cwatch='cargo watch -x run'" /home/\$USERNAME/.bashrc || echo "alias cwatch='cargo watch -x run'" >> /home/\$USERNAME/.bashrc

# Instala o yay para pacotes AUR
cd /opt
git clone https://aur.archlinux.org/yay.git
chown -R "\$USERNAME:\$USERNAME" yay
cd yay
su - \$USERNAME -c "cd /opt/yay && makepkg -si --noconfirm"
cd /

# Verifica se yay foi instalado corretamente antes de remover o diretório
if su - $USERNAME -c "command -v yay" >/dev/null 2>&1; then
  rm -rf /opt/yay
else
  echo "Atenção: yay não foi instalado corretamente. Diretório /opt/yay não será removido."
fi

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
    echo "Pacote AUR '\$pkg' não encontrado. Pulando..."
  fi
done

EOF

echo "Ferramentas de desenvolvimento instaladas com sucesso!"

sleep 2
