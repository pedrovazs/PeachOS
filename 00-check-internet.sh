#!/bin/bash

# 00-check-internet.sh - Verirfica conectividade com a internet e sincronização de data/hora

echo "[Etapa 00] Verificando conexão com a internet..."

# Testa ping para o domínio archlinux.org

if ping -q -c 1 archlinux.org >/dev/null; then
	echo "Internet detectada!"
else
	echo "Sem conexão com a internet. verifique sua rede antes de prosseguir."
	exit 1
fi

echo "[Etapa 00] Verificando sincronização com o relógio da internet..."

# Verifica se o serviço de sincronização de tempo está ativo
timedatectl set-ntp true

# Espera 2 segundos para sincronizar
sleep 2

# Mostra o status atual do relógio
timedatectl status | grep -E "Time zone|Systme clock synchronized"

echo "Sincronização de tempo ativo"

# Testa resolução de DNS com curl
echo "[Etapa 0] Verificando resolução de DNS"

if curl -s --head https://archlinux.org | grep "HTTP/" >/dev/null; then
	echo "DNS funcionando corretamente."
else
	echo "DNS pode estar com problemas. Verifique suas configurações de rede."
	exit 1
fi
