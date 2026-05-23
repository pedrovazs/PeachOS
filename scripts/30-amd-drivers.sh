#!/usr/bin/env bash
# Fase 2 — Bloco 3: Drivers AMD (amdgpu open source)
# Instala mesa, Vulkan e suporte a VA-API/VDPAU para GPU AMD integrada.
set -euo pipefail

echo "==> [30] Drivers AMD"

AMD_PKGS=(
    mesa
    lib32-mesa
    vulkan-radeon
    lib32-vulkan-radeon
    libva-mesa-driver
    lib32-libva-mesa-driver
    mesa-vdpau
    lib32-mesa-vdpau
)

echo "  -> Instalando pacotes Mesa/AMD..."
pacman -S --noconfirm --needed "${AMD_PKGS[@]}"

# xf86-video-amdgpu é opcional — o driver modesetting (embutido no xorg-server) é o recomendado
# para GPUs AMD modernas (GCN 1.2+). Instale xf86-video-amdgpu só se encontrar problemas
# específicos de tearing ou se usar hardware mais antigo (Southern Islands).
echo "  -> NOTA: xf86-video-amdgpu NÃO instalado (modesetting é o padrão recomendado)."
echo "     Se tiver problemas de renderização 2D, instale manualmente: pacman -S xf86-video-amdgpu"

# Habilitar multilib se necessário (para pacotes lib32)
if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
    echo ""
    echo "  ATENÇÃO: repositório [multilib] não está habilitado no pacman.conf."
    echo "  Habilite-o e rode: pacman -Sy"
    echo "  Os pacotes lib32-* não serão instalados até lá."
fi

# Verificar se amdgpu está carregado (só faz sentido em hardware físico ou VM com passthrough)
if lspci | grep -qi 'amd\|radeon'; then
    echo "  -> GPU AMD detectada."
    if lsmod | grep -q amdgpu; then
        echo "  -> Módulo amdgpu carregado."
    else
        echo "  -> Módulo amdgpu não carregado ainda (normal em VM sem passthrough)."
    fi
else
    echo "  -> Nenhuma GPU AMD detectada (esperado em VM sem passthrough)."
fi

echo "==> [30] Concluído."
