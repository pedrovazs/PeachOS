# PeachOS — Checklist de migração VM → hardware físico

> Use este documento na hora da migração. Marque cada item conforme avança.
> Refs entre parênteses apontam para os "Pontos de atenção" numerados no CLAUDE.md.

---

## 0. Pré-requisitos — ter em mãos antes de começar

- [ ] Pen drive bootável com ISO Arch Linux (último release)
- [ ] Pen drive de backup do Windows (ou imagem via Macrium/Clonezilla)
- [ ] Espaço livre no disco ou segundo disco para o Arch (~60 GB mínimo)
- [ ] Anotado: tamanho da partição EFI existente do Windows (geralmente 100–260 MB)
- [ ] Anotado: senha do LUKS que será usada (forte, guardada em cofre)
- [ ] Repositório `PeachOS` clonado ou pen drive com o repo (para offline)
- [ ] Conexão ethernet disponível durante a instalação (Wi-Fi pede driver extra)

---

## 1. Pré-migração: validar tudo na VM antes de migrar

Não migrar com itens pendentes aqui.

- [ ] `bootstrap.sh` roda do início ao fim sem erros na VM
- [ ] `apply-theme.sh` aplica tema completo: GRUB, Plymouth, extensões GNOME, Gradience
- [ ] Todas as 12 extensões GNOME ativas e sem erro no `gnome-extensions list --enabled`
- [ ] Ghostty abre, tema PeachOS correto (cores do `palette.json`)
- [ ] VS Code com extensões do `packages/vscode-extensions.txt` instaladas (ref. ponto #16)
- [ ] `lazygit` abre sem erro de configuração (`delta` presente — ref. ponto #14)
- [ ] Copy/paste funciona no zellij e tmux via `wl-clipboard` (ref. ponto #15)
- [ ] Snapshot Btrfs limpo criado na VM antes de qualquer mudança de migração
- [ ] Commit de tudo no repo (nada pendente em `git status`)

---

## 2. Preparação do hardware físico

### 2.1 Backup do Windows

- [ ] Criar imagem completa do Windows (Macrium Reflect Free ou similar)
- [ ] Verificar que o backup restaura em teste
- [ ] Anotar a letra e tamanho da partição EFI atual (`diskpart → list vol`)

### 2.2 UEFI / BIOS

- [ ] Desabilitar **Secure Boot** (Arch não precisa; facilita a instalação)
- [ ] Desabilitar **Fast Startup** do Windows (`Painel de Controle → Opções de Energia → Desligar`)
  — sem isso a partição NTFS é montada como "suja" e o os-prober pode falhar
- [ ] Habilitar **VT-x / AMD-V** (virtualização — para uso futuro com containers)
- [ ] Verificar modo de boot: **UEFI** (não Legacy/CSM)
- [ ] Anotar a ordem de boot atual para restaurar se necessário

### 2.3 Liberar espaço para o Arch

- [ ] No Windows: **Gerenciar Discos** → encolher a partição C: (ou outra)
- [ ] Deixar o espaço **não alocado** — o archinstall vai criar as partições do Arch

---

## 3. Instalação do Arch via archinstall

> Particionamento e LUKS são manuais — não automatizados (risco alto).

### 3.1 Boot

- [ ] Boot pelo pen drive Arch
- [ ] Confirmar modo UEFI: `ls /sys/firmware/efi/efivars` deve listar arquivos
- [ ] Configurar teclado se necessário: `loadkeys br-abnt2`
- [ ] Testar rede: `ping -c 1 archlinux.org`

### 3.2 Particionamento com LUKS + Btrfs

Use `fdisk` ou `cfdisk` para criar as partições **sem** usar o archinstall para isso.

- [ ] Identificar o disco alvo: `lsblk -f`
- [ ] Criar partição EFI (se a existente do Windows for < 512 MB, criar nova de 512 MB)
  — **não formatar** a EFI do Windows; usar a existente ou criar uma dedicada
- [ ] Criar partição raiz (restante do espaço livre não alocado)
- [ ] Configurar LUKS na partição raiz:
  ```
  cryptsetup luksFormat /dev/sdXY
  cryptsetup open /dev/sdXY cryptroot
  ```
- [ ] Criar filesystem Btrfs no device mapeado:
  ```
  mkfs.btrfs /dev/mapper/cryptroot
  mount /dev/mapper/cryptroot /mnt
  ```
- [ ] Criar subvolumes `@` e `@home` **(ref. ponto #2 — archinstall pode não criar automaticamente com LUKS)**:
  ```
  btrfs subvolume create /mnt/@
  btrfs subvolume create /mnt/@home
  umount /mnt
  ```
- [ ] Montar com as opções corretas:
  ```
  mount -o compress=zstd,noatime,subvol=@ /dev/mapper/cryptroot /mnt
  mkdir -p /mnt/home
  mount -o compress=zstd,noatime,subvol=@home /dev/mapper/cryptroot /mnt/home
  ```
- [ ] Montar a partição EFI em `/mnt/boot`

### 3.3 Archinstall

Usar archinstall **após** o particionamento manual, apontando para os mounts já feitos.

- [ ] Selecionar: **Use existing/pre-mounted partition layout**
- [ ] Bootloader: **GRUB** (não systemd-boot — ref. decisão arquitetural)
- [ ] Locale: `pt_BR.UTF-8`
- [ ] Keymap: `br-abnt2`
- [ ] Hostname: `peachos`
- [ ] Usuário: criar com senha forte, adicionar ao grupo `wheel`
- [ ] Confirmar que `/etc/mkinitcpio.conf` terá o hook `encrypt` **após** `keyboard` e **antes** de `filesystems`:
  `HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt filesystems fsck)`
  — o Plymouth será adicionado depois (ref. ponto #6)
- [ ] Concluir instalação e reiniciar para o novo sistema

---

## 4. Fase 2 no hardware físico

Execute os blocos em ordem, como root, **um por vez**, verificando o resultado antes de avançar.

### Bloco 10 — Mirrors e pacman
- [ ] `sudo bash scripts/10-mirrors-pacman.sh`
- [ ] Verificar: `pacman -Syu` funciona sem erro

### Bloco 20 — Áudio (PipeWire)
- [ ] Verificar e **remover pulseaudio** se instalado **(ref. ponto #5)**: `pacman -Qs pulseaudio`
- [ ] `sudo bash scripts/20-audio.sh`
- [ ] Verificar: `pactl info | grep "Server Name"` deve conter PipeWire

### Bloco 30 — Drivers AMD
- [ ] `sudo bash scripts/30-amd-drivers.sh`
- [ ] Verificar: `lspci -k | grep -A 2 VGA` deve mostrar `amdgpu` como kernel driver

### Bloco 40 — Btrfs + snapper + grub-btrfs
- [ ] `sudo bash scripts/40-btrfs-snapshots.sh`
- [ ] Verificar: `snapper -c root list` mostra ao menos 1 snapshot
- [ ] **Importante (ref. ponto #4):** o grub-mkconfig deste bloco cria as entradas de snapshot no GRUB; deve ser rodado SÓ após o snapshot existir

### Bloco 50 — GRUB dual boot
- [ ] `sudo bash scripts/50-grub-dualboot.sh`
- [ ] Verificar: `grep -i windows /boot/grub/grub.cfg` deve retornar resultado **(ref. ponto #3)**
- [ ] Se Windows não detectado: checar se Fast Startup do Windows está desativado e rodar `sudo os-prober && sudo grub-mkconfig -o /boot/grub/grub.cfg`

### Bloco 60 — Segurança
- [ ] `sudo bash scripts/60-security.sh`
- [ ] Verificar: `sudo firewall-cmd --state` retorna `running`

### Bloco 70 — Performance
- [ ] `sudo bash scripts/70-performance.sh`
- [ ] Verificar: `cat /sys/block/sda/queue/scheduler` (ou nvme) mostra scheduler ativo

### Bloco 80 — Logs
- [ ] `sudo bash scripts/80-logs.sh`

### Bloco 90 — Rede
- [ ] `sudo bash scripts/90-network.sh`

### Bloco 95 — Locale, Bluetooth, Fontes
- [ ] `sudo bash scripts/95-locale-bt-fonts.sh`
- [ ] Verificar: `localectl status` mostra `pt_BR.UTF-8`

### Bloco 99 — Pacman hooks (instala paru)
- [ ] `sudo bash scripts/99-pacman-hooks.sh`
- [ ] Verificar: `paru --version` funciona

### Plymouth — adicionar hook ao mkinitcpio **(ref. ponto #6)**
> Este passo é manual — risco alto de sistema não iniciar se errar a ordem.

- [ ] Editar `/etc/mkinitcpio.conf` e adicionar `plymouth` na posição correta:
  ```
  HOOKS=(base udev plymouth autodetect microcode modconf kms keyboard keymap consolefont block encrypt filesystems fsck)
  ```
  — `plymouth` imediatamente após `udev`, **antes** de `autodetect`
  — `encrypt` deve continuar **antes** de `filesystems`
- [ ] Regenerar initramfs: `sudo mkinitcpio -P`
- [ ] Verificar que `/boot/initramfs-linux.img` tem data recente

---

## 5. Bootstrap (Fases 3 + 5)

- [ ] Clonar o repositório no hardware:
  ```bash
  git clone https://github.com/pedrovazs/PeachOS
  cd PeachOS
  ```
- [ ] Rodar o bootstrap como usuário (não root):
  ```bash
  ./bootstrap.sh
  ```
  — Se ainda estiver em TTY (sem GNOME), o script aplica só a parte de sistema do tema
  e imprime o lembrete para `./apply-theme.sh --user-only` após o primeiro login gráfico
- [ ] Reiniciar para verificar GRUB com tema PeachOS e Plymouth no boot
- [ ] No primeiro login GNOME (se veio de TTY no bootstrap):
  ```bash
  cd PeachOS
  ./apply-theme.sh --user-only
  ```

---

## 6. Verificação pós-migração

### Sistema

- [ ] Dual boot: GRUB apresenta Windows e PeachOS como entradas
- [ ] Plymouth aparece no boot (fundo deep_plum, "PeachOS" com pulso)
- [ ] Tela de login GDM com fundo deep_plum
- [ ] Btrfs snapshots funcionando: `snapper -c root list`
- [ ] LUKS: ao reiniciar, pede senha antes do Plymouth
- [ ] Drivers AMD: `glxinfo | grep "OpenGL renderer"` mostra AMD

### Visual

- [ ] GNOME em modo escuro, tema Adwaita dark
- [ ] Ícones Papirus-Dark
- [ ] Fontes: Noto Sans na UI, JetBrains Mono Nerd no terminal
- [ ] Gradience aplicado: headerbar e cards com as cores PeachOS
  (se `gradience-cli` não instalado, verificar fallback — ref. ponto #20)
- [ ] Ghostty com tema PeachOS (testar cores ANSI: `ls --color=always`)

### Extensões GNOME **(ref. ponto #9)**

> Se a versão do GNOME Shell diferir da VM, extensões podem precisar de ajuste.

- [ ] `gnome-extensions list --enabled` mostra as 12 extensões ativas
- [ ] Se alguma não funcionar: verificar versão compatível no AUR ou ajustar `metadata.json`
  — campo `shell-version` pode precisar incluir a versão instalada

### Ferramentas

- [ ] `paru --version` OK
- [ ] `rustup show` mostra toolchain stable
- [ ] `pyenv versions` mostra Python instalado
- [ ] `fnm list` mostra Node LTS
- [ ] `sdk version` (sdkman) OK
- [ ] VS Code com todas as extensões do `packages/vscode-extensions.txt`
- [ ] `lazygit` abre e `delta` como pager funciona (ref. ponto #14)
- [ ] Copy/paste no zellij e tmux via Wayland (ref. ponto #15)
- [ ] GSConnect: parear com Android; se não conectar, verificar firewalld (ref. ponto #18)

### Windows

- [ ] Windows ainda inicia pelo GRUB sem erros
- [ ] Relógio correto no Windows após boot (pode precisar de `hwclock --systohc --utc` no Arch + ajuste de registro no Windows para UTC)

---

## 7. Diferenças conhecidas VM → hardware

| Aspecto | VM | Hardware físico |
|---|---|---|
| GPU | VirtIO/VESA (sem aceleração real) | AMD integrada, `amdgpu` |
| LUKS | Opcional na VM | Obrigatório (dado sensível) |
| Plymouth | Pode não aparecer em algumas VMs | Deve aparecer normalmente |
| Bluetooth | Geralmente sem hardware | Disponível (bloco 95) |
| Dual boot | Não aplicável | GRUB detecta Windows via os-prober |
| mkinitcpio hooks | Sem `encrypt` | `encrypt` obrigatório para LUKS |
| Performance | Limitada pelo hipervisor | Real (zram, I/O scheduler ativos) |

---

## 8. Rollback de emergência

Se algo der errado durante a migração:

- **Sistema não inicia após mkinitcpio:** boot pelo pen drive Arch → `arch-chroot` → corrigir HOOKS → `mkinitcpio -P`
- **GRUB não carrega:** boot pelo pen drive → reinstalar GRUB: `grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB && grub-mkconfig -o /boot/grub/grub.cfg`
- **LUKS: senha errada ou esquecida:** não há recuperação sem a senha ou chave de backup — **guarde a senha antes de começar**
- **Windows sumiu do GRUB:** `sudo os-prober && sudo grub-mkconfig -o /boot/grub/grub.cfg`
- **Btrfs corrompido:** boot pelo pen drive → `btrfs check /dev/mapper/cryptroot`; se necessário, restaurar snapshot

---

*Gerado em maio/2026. Atualizar conforme a migração for realizada.*
