#!/usr/bin/env bash
# Fase 2 — Bloco 9: Rede (NetworkManager, ferramentas de diagnóstico)
set -euo pipefail

echo "==> [90] Rede"

# --- NetworkManager ---
if ! systemctl is-enabled NetworkManager &>/dev/null; then
    echo "  -> Habilitando NetworkManager..."
    systemctl enable --now NetworkManager
else
    echo "  -> NetworkManager já habilitado."
fi

# Garantir que systemd-networkd e systemd-resolved não conflitam
if systemctl is-enabled systemd-networkd &>/dev/null; then
    echo "  -> Desabilitando systemd-networkd (usar NetworkManager)..."
    systemctl disable --now systemd-networkd
fi

# --- ferramentas de rede ---
NET_PKGS=(
    networkmanager-openvpn  # suporte VPN
    nss-mdns                # mDNS / .local hostnames
    bind-tools              # dig, nslookup, host
    traceroute
    nmap
    wget
    curl
)

echo "  -> Instalando ferramentas de rede..."
pacman -S --noconfirm --needed "${NET_PKGS[@]}"

# --- mDNS (Avahi) ---
if ! pacman -Qi avahi &>/dev/null; then
    pacman -S --noconfirm --needed avahi
fi
systemctl enable --now avahi-daemon

# Habilitar mDNS no nsswitch.conf se não estiver
if ! grep -q 'mdns_minimal' /etc/nsswitch.conf; then
    sed -i 's/^hosts:.*$/hosts: mymachines mdns_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] files myhostname dns/' /etc/nsswitch.conf
    echo "  -> nsswitch.conf atualizado para mDNS."
fi

echo "  -> Status da rede:"
networkctl status 2>/dev/null || ip link show

echo "==> [90] Concluído."
