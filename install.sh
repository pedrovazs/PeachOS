#!/bin/bash

# Instalador para o PeachOS - Scrip principal
# Este script orquestra a isntalação modular do PeachOS
# Cada etapa é dividida em scripts numerados na pasta atual
# Feito para estudos em conjunto com o ChatGPT

set -e

# Função para verificar dependências mínimas para o instalador
function check_dependencies() {
	for cmd in curl ping lsblk bash; do
		if ! command -v "$cmd" &>/dev/null; then
			echo "[ERRO] Dependência ausente: $cmd"
			exit 1
		fi
	done
}

# Função para executar os módulos de instalação
function run_modules() {
	for script in ./*.sh; do
		case "$script" in
			./install.sh) ;; # Ignorar o próprio script principal
			./*[0-9][0-9]-*.sh)
				echo "\n[PeachOS]~Executando módulo: $script"
				bash "$script"
				;;
		esac
	done
}

# Início da execução
clear
echo "=================================="
echo "       Instalador do PeachOS      "
echo "=================================="
echo "Este script irá instalar o PeachOS em seu sistema"
echo "Pressione ENTER para iniciar ou CTRL+C para cancelar"
read -r

check_dependencies
run_modules

echo "\nInstalação do PeachOS finalizada com sucesso! Reinicie o sistema."

