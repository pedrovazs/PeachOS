# 🍑 PeachOS Installer

Bem-vindo ao instalador oficial do **PeachOS** – um sistema operacional baseado no Arch Linux com foco em **desenvolvimento de software**, **produtividade** e **desempenho**. Este script automatiza toda a instalação do sistema, utilizando uma arquitetura modular e personalizações GNOME modernas.

---

## 🚀 Objetivo

Automatizar a instalação do PeachOS com:

- Kernel LTS e sistema de arquivos Btrfs
- Interface GNOME personalizada
- Ferramentas de desenvolvimento (Rust, Docker, VS Code, etc.)
- Segurança aprimorada (AppArmor, UFW, Fail2ban, Timeshift)
- Aparência moderna com ícones, temas e fontes otimizadas

---

## 📁 Estrutura

O projeto é dividido em scripts numerados, que executam cada etapa da instalação:

```bash
.
├── install.sh                # Script principal
├── 00-check-internet.sh     # Verifica internet e NTP
├── 01-disk-setup.sh         # Particiona e formata disco com Btrfs
├── 02-base-install.sh       # Instala base do Arch Linux
├── 03-system-config.sh      # Configura locale, timezone e usuário
├── 04-bootloader.sh         # Instala GRUB com suporte a EFI/Btrfs
├── 05-desktop-env.sh        # Instala GNOME, temas, ícones
├── 06-dev-tools.sh          # Instala ferramentas de desenvolvimento
├── 07-post-install.sh       # Otimizações, segurança e snapshots
