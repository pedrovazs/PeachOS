#!/usr/bin/env bash
# Fase 2 — Bloco 6: Segurança (firewalld, firejail, AIDE, SSH hardening)
# NÃO instala opensnitch — decisão consciente (ver CLAUDE.md).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> [60] Segurança"

PKGS=(firewalld firejail aide ufw)
echo "  -> Instalando pacotes de segurança..."
pacman -S --noconfirm --needed "${PKGS[@]}"

# --- firewalld ---
echo "  -> Habilitando firewalld..."
systemctl enable --now firewalld

# Zona padrão: public
firewall-cmd --set-default-zone=public --permanent

# Docker: publicar portas apenas em 127.0.0.1 (ver ponto de atenção #1 no CLAUDE.md)
# Isso é lembrete de configuração — o Docker daemon.json cuida disso no bloco de instalação

echo "  -> Recarregando regras firewalld..."
firewall-cmd --reload

# --- firejail ---
echo "  -> Configurando firejail como sandbox padrão..."
# Ativa perfis para browsers e apps comuns
if [[ -f /usr/lib/firejail/firecfg.config ]]; then
    firecfg --fix-sound 2>/dev/null || true
fi

# --- AIDE ---
echo "  -> Copiando aide.conf..."
cp "$REPO_DIR/security/aide.conf" /etc/aide.conf

if [[ ! -f /var/lib/aide/aide.db.gz ]]; then
    echo "  -> Inicializando banco de dados AIDE (pode levar alguns minutos)..."
    aide --init
    mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
    echo "  -> Banco AIDE criado em /var/lib/aide/aide.db.gz"
else
    echo "  -> Banco AIDE já existe, pulando inicialização."
fi

# --- SSH hardening ---
echo "  -> Copiando sshd_config..."
cp "$REPO_DIR/security/sshd_config" /etc/ssh/sshd_config

# Verificar configuração antes de reiniciar
sshd -t && echo "  -> sshd_config válido."

if systemctl is-enabled sshd &>/dev/null; then
    systemctl restart sshd
    echo "  -> sshd reiniciado com nova config."
fi

echo "==> [60] Concluído."
echo "    Para checar estado do firewall: firewall-cmd --list-all"
