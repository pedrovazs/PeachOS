# Fase 1 — Checklist: Preparar a VM

Use `[x]` para marcar o que já foi feito. Cada seção pode ser executada de forma independente.

---

## 1. Software de virtualização

- [ ] VirtualBox instalado (ou QEMU/KVM configurado)
- [ ] Extension Pack do VirtualBox instalado (necessário para UEFI e USB 3.0)
- [ ] ISO do Arch Linux baixada — https://archlinux.org/download/
- [ ] Hash SHA256 da ISO verificado

---

## 2. Criar e configurar a VM

- [ ] Nova VM criada com nome `PeachOS`
- [ ] Tipo: Linux / Arch Linux (64-bit)
- [ ] **RAM:** mínimo 4GB para instalação; 8GB para uso normal
- [ ] **Disco:** 60GB, formato VDI, alocação dinâmica
- [ ] **Modo EFI/UEFI habilitado** (Configurações → Sistema → Habilitar EFI)
- [ ] **VT-x / AMD-V habilitado** (Configurações → Sistema → Aceleração)
- [ ] ISO montada no drive óptico
- [ ] Rede: modo NAT (acesso à internet durante instalação)
- [ ] Clipboard bidirecional habilitado (facilita copiar comandos)
- [ ] Pasta compartilhada configurada (opcional — para transferir arquivos)

> **VirtualBox + UEFI:** a opção fica em Configurações → Sistema → Placa-mãe → Habilitar EFI.

---

## 3. Boot e verificação do ambiente

- [ ] VM bootou pela ISO do Arch Linux
- [ ] Confirmado modo UEFI ativo:
  ```
  ls /sys/firmware/efi/efivars
  ```
  Deve listar arquivos. Se o diretório não existir, está em modo BIOS — revisar passo 2.
- [ ] Internet funcionando:
  ```
  ping -c 3 archlinux.org
  ```
- [ ] Relógio sincronizado:
  ```
  timedatectl set-ntp true
  timedatectl status
  ```

---

## 4. Instalação base via archinstall

- [ ] `archinstall` executado
- [ ] **Mirrors:** selecionados mirrors do Brasil
- [ ] **Disco:** particionamento com Btrfs selecionado
- [ ] **Subvolumes Btrfs:** verificar se `@` e `@home` foram criados automaticamente
  - Se não criados: sair do archinstall, criar manualmente, retornar
  - Ver ponto de atenção #2 no CLAUDE.md
- [ ] **Bootloader:** GRUB selecionado (não systemd-boot)
- [ ] **Filesystem:** Btrfs com opções `compress=zstd,noatime`
- [ ] **Locale:** `pt_BR.UTF-8`
- [ ] **Timezone:** `America/Sao_Paulo`
- [ ] **Hostname:** `peachos`
- [ ] **Usuário comum** criado com senha
- [ ] **sudo** habilitado para o usuário
- [ ] Pacotes mínimos instalados: `base`, `base-devel`, `linux`, `linux-firmware`, `networkmanager`, `git`
- [ ] Instalação concluída sem erros
- [ ] Reboot efetuado (remover ISO antes)

---

## 5. Primeiro boot no sistema instalado

- [ ] Sistema bootou pelo GRUB (não pela ISO)
- [ ] Login efetuado com o usuário criado
- [ ] NetworkManager ativo e internet funcionando:
  ```
  systemctl status NetworkManager
  ping -c 3 archlinux.org
  ```
- [ ] Git instalado:
  ```
  git --version
  ```
- [ ] Repositório peachos-config clonado:
  ```
  git clone https://github.com/pedrovazs/peachos ~/peachos-config
  ```

---

## 6. Pronto para a Fase 2

- [ ] Todos os itens acima marcados
- [ ] Snapshot manual tirado antes de começar os scripts (via `btrfs subvolume snapshot` ou pela VM)
- [ ] Scripts de `scripts/` disponíveis no sistema (via clone do repo)

---

## Notas rápidas

| Problema | Verificação |
|----------|-------------|
| VM não boota em UEFI | Certifique que a ISO é para UEFI e que o EFI está habilitado nas config da VM |
| Sem internet no boot | `ip link` → `ip link set eth0 up` → `dhcpcd eth0` |
| Subvolumes @ não criados | `btrfs subvolume list /` após montar o disco manualmente |
| GRUB não aparece | Checar se a partição EFI foi montada em `/boot/efi` durante instalação |
