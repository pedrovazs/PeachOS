# CLAUDE.md — PeachOS

> Briefing do projeto para o Claude Code. Este arquivo é o contexto permanente.
> Leia por inteiro antes de qualquer tarefa. Mantenha-o atualizado conforme o projeto avança.

---

## O que é o PeachOS

PeachOS é um ambiente desktop baseado em **Arch Linux + GNOME**, voltado para
desenvolvimento de software e projetos pessoais, com identidade visual própria e
uma camada de IA integrada. O projeto é primeiro validado em máquina virtual e
depois migrado para máquina física em dual boot com Windows.

**Importante — natureza do projeto:** isto NÃO é um sistema operacional escrito do
zero. É uma distribuição/configuração construída sobre o Arch Linux. O kernel é o
do Linux. Toda a customização acontece em userspace, desktop e ferramentas.

## O que é este repositório

Este repositório é o **`peachos-config`**: a configuração reproduzível do PeachOS.
Contém scripts de instalação, dotfiles, temas e arquivos de configuração de sistema.
Todo o ambiente do PeachOS pode ser recriado a partir daqui.

O daemon de IA (`peachd`, ver Fase 8) terá repositório próprio no futuro — não vive aqui.

## Papel do Claude Code neste projeto

Você (Claude Code) trabalha **no repositório**: gera e mantém os scripts de
configuração, os dotfiles, os arquivos de tema e a documentação. Você NÃO instala
o sistema operacional — isso roda na VM/máquina do usuário. Seu produto são os
arquivos versionados aqui.

---

## Perfil do desenvolvedor

- Desenvolvedor de software: JavaScript, Java, Python; aprendendo Rust.
- Formação em Direito, prepara concursos públicos (carreiras policiais).
- Baseado em Planaltina, Brasília (DF). Comunica-se em português brasileiro.
- Preferências: respostas diretas, informais, sem rodeios. Quer opiniões dadas com
  clareza. Prefere perguntas de esclarecimento antes de tarefas abertas.

---

## Decisões de arquitetura (fixas — não reabrir sem o usuário pedir)

### Base do sistema
- **Distro base:** Arch Linux, instalada via `archinstall`.
- **Filesystem:** Btrfs com subvolumes `@` e `@home`, montagem `compress=zstd,noatime`.
- **Bootloader:** GRUB (não systemd-boot — escolhido pelo suporte a tema e dual boot).
- **Desktop:** GNOME, instalado minimamente (pacote por pacote, sem os grupos
  `gnome`/`gnome-extra`).
- **Hardware alvo:** desktop com GPU AMD integrada (drivers open source `amdgpu`).

### Linguagem dos scripts
- **Bash** para todos os scripts de sistema e instalação. É o padrão do ecossistema
  Arch e evita dependência circular (não precisa de runtime instalado para rodar).
- **Python** apenas para o `peachd` (Fase 8) e para o gerador de wallpaper (Cairo).

### Camada de IA (Fase 8)
- Daemon `peachd` em Python, roda como serviço **systemd de usuário**.
- Acesso à IA **via nuvem** (API Anthropic). Roteamento local/nuvem fica como
  gancho para o futuro, não é implementado agora.
- Clientes (terminal, GTK4, extensão GNOME) são leves e falam com o daemon via
  socket Unix local.

### Princípio de automação
Scripts de instalação são **modulares e idempotentes**, executados por bloco com
verificação humana entre eles. NÃO criar um script único "faz tudo". Particionamento
e configuração de LUKS NÃO são automatizados — risco alto, exigem decisão humana.

---

## Identidade visual

### Paleta oficial (fonte da verdade: `themes/palette.json`)

| Nome        | Hex       | Uso                          |
|-------------|-----------|------------------------------|
| Cream       | `#FFF8F5` | Background primário          |
| Peach Mist  | `#FDEEE8` | Superfícies e cards          |
| Peach       | `#E8956D` | Accent primário              |
| Peach Rose  | `#F4C2B0` | Cursor do terminal           |
| GRUB Accent | `#F1B098` | Destaque do bootloader       |
| Lavender    | `#C4A8D4` | Accent secundário            |
| Blossom     | `#E8A0B8` | Accent terciário             |
| Deep Plum   | `#2D2433` | Texto primário               |
| Muted Plum  | `#6B5B7A` | Texto secundário             |

Toda cor usada em qualquer config (GRUB, Ghostty, zellij, tmux, VS Code, etc.)
deriva desta paleta. O `palette.json` é lido pelo gerador de wallpaper e pelo
`apply-theme.sh`. Mudança de cor é feita só nesse arquivo e propaga.

### Logo
Pêssego circular salmão com meia-lua escura à direita e duas folhas verdes no topo.
SVG versionado em `themes/logo/`. Variantes: ícone só, ícone + texto, inline.

### Direção visual
Minimalista, clean, pastel. Sem excesso de elementos. Tema claro e escuro,
alternados pelo Night Theme Switcher.

---

## Estrutura do repositório

```
peachos-config/
├── CLAUDE.md               # este arquivo
├── README.md               # porta de entrada para humanos
├── docs/
│   └── PeachOS-Plano-Completo.docx   # plano detalhado das 8 fases
│
├── bootstrap.sh            # orquestrador: clona e roda install + apply-theme
├── install.sh              # instala pacotes + configs de sistema
├── apply-theme.sh          # orquestra apply-theme-user + apply-theme-system
├── apply-theme-user.sh     # tema na sessão do usuário (gsettings, gradience...)
├── apply-theme-system.sh   # tema com sudo (GRUB, Plymouth, GDM)
│
├── scripts/                # scripts de bloco da Fase 2 (pós-instalação base)
│   ├── 10-mirrors-pacman.sh
│   ├── 20-audio.sh
│   ├── 30-amd-drivers.sh
│   ├── 40-btrfs-snapshots.sh
│   ├── 50-grub-dualboot.sh
│   ├── 60-security.sh
│   ├── 70-performance.sh
│   ├── 80-logs.sh
│   ├── 90-network.sh
│   ├── 95-locale-bt-fonts.sh
│   └── 99-pacman-hooks.sh
│
├── dotfiles/               # configs de apps (aplicadas via stow)
│   ├── zsh/.config/zsh/
│   ├── starship/.config/starship.toml
│   ├── ghostty/.config/ghostty/config
│   ├── lazygit/.config/lazygit/config.yml
│   ├── zellij/.config/zellij/config.kdl
│   ├── tmux/.tmux.conf
│   ├── vscode/settings.json
│   └── peachd/.config/peachos/   # config do daemon + index-ignore (Fase 8)
│
├── themes/
│   ├── palette.json
│   ├── logo/               # SVGs da logo
│   ├── gradience/          # preset libadwaita
│   ├── gnome-shell/        # CSS do shell theme
│   ├── grub/               # theme.txt + logo.png
│   ├── plymouth/
│   └── wallpapers/
│       └── generate.py     # gerador Python + Cairo
│
├── sounds/PeachOS/stereo/  # som de notificação
│
├── system/                 # arquivos copiados para /etc e afins
│   ├── os-release
│   ├── hostname
│   ├── sysctl.conf
│   ├── journald.conf
│   ├── zram-generator.conf
│   ├── reflector.conf
│   ├── docker/daemon.json
│   ├── udev/60-ioschedulers.rules
│   ├── grub                # /etc/default/grub
│   ├── snapper/{root,home}.conf
│   └── pacman/{pacman.conf,paru.conf,hooks/}
│
├── security/
│   ├── firewalld/
│   ├── aide.conf
│   └── sshd_config
│
└── packages/
    ├── pkglist.txt         # pacotes oficiais (pacman)
    └── aurlist.txt         # pacotes AUR
```

---

## As 8 fases — roadmap de implementação

Cada fase está detalhada no `docs/PeachOS-Plano-Completo.docx`. Resumo do escopo e
do estado de cada uma. Atualize o STATUS conforme avançar.

### Fase 1 — Preparar a VM
VirtualBox/QEMU, 8GB RAM, 60GB disco, UEFI, VT-x/AMD-V.
**STATUS: concluída.** Artefato: `docs/fase1-checklist.md`.

### Fase 2 — Instalação e configuração base
12 blocos. Instalação base via `archinstall` (manual), depois scripts de bloco em
`scripts/`. Cobre: mirrors, áudio (PipeWire), drivers AMD, Btrfs+snapshots+grub-btrfs,
GRUB dual boot, segurança, performance, logs, rede, locale/bluetooth/fontes, pacman hooks.
**STATUS: concluída.** Artefatos: `scripts/*.sh` (11 blocos), `system/*`, `security/*`.

### Fase 3 — Ambiente de desenvolvimento
Rust (rustup), Python (pyenv), Node (fnm), Java (sdkman). Terminal: zellij, tmux,
fzf, ripgrep, fd, bat, eza, zoxide, neovim. Shell: zsh + starship + plugins.
**STATUS: concluída.** Artefatos: `dotfiles/{zsh,starship,zellij,tmux,ghostty,lazygit,vscode}/`,
`packages/{pkglist,aurlist}.txt`, `install.sh`.

### Fase 4 — GNOME
GNOME mínimo, apps (Ghostty, Nautilus+Yazi, Loupe, Evince, VS Code, Bruno,
Portainer+Lazydocker, Beekeeper, Lazygit, Firefox), fontes (JetBrains Mono Nerd +
Noto), Papirus, 13 extensões, theming.
**STATUS: planejada.** Artefatos: `pkglist.txt`, `aurlist.txt`, `dotfiles/`.

### Fase 5 — Identidade visual
Paleta, logo, wallpaper (Python+Cairo), Plymouth, GDM, GRUB tema, sons, VS Code
(Catppuccin), Ghostty.
**STATUS: paleta definida em CLAUDE.md (fonte definitiva até `themes/palette.json` ser criado).
Logo planejada.** Artefatos: tudo em `themes/`, `sounds/`, `apply-theme*.sh` — a criar.

### Fase 6 — Configuração das ferramentas
Bruno, Lazygit, Beekeeper, Portainer, Zellij, tmux, Starship — cada um com config
e tema próprios.
**STATUS: parcialmente coberta pela Fase 3** (lazygit, zellij, tmux, starship já têm dotfiles).
Pendentes: Bruno, Beekeeper, configurações específicas de Portainer.

### Fase 7 — Estabilização e documentação
README, MIGRATION.md, snapshots estratégicos, checklist de migração, scripts
`install.sh`/`apply-theme.sh`/`bootstrap.sh` finalizados.
**STATUS: planejada.** Artefatos: `README.md` (existe, parcial), `docs/MIGRATION.md`, scripts raiz.

### Fase 8 — Camada de IA
Daemon `peachd` (Python, systemd de usuário, socket Unix, API Anthropic), clientes
(ai-cli, peach-ask GTK4, extensão GNOME), busca semântica (reusa stack do projeto
`rag-pf`: PyMuPDF, embeddings, ChromaDB).
**STATUS: planejada.** O código do `peachd` vai para repositório próprio; aqui ficam
só `dotfiles/peachd/` e o service file.

---

## Pontos de atenção (achados nas revisões — não esquecer)

1. **Docker + firewalld:** portas publicadas com `-p` ficam acessíveis independente
   do firewalld. Sempre publicar como `127.0.0.1:porta:porta` para limitar ao localhost.
2. **archinstall + LUKS + Btrfs:** dependendo da versão, o archinstall pode não criar
   os subvolumes `@`/`@home` automaticamente quando a criptografia está ativa.
   Verificar e criar manualmente se necessário.
3. **os-prober:** desabilitado por padrão no GRUB. Para o dual boot detectar o
   Windows, é obrigatório `GRUB_DISABLE_OS_PROBER=false` em `/etc/default/grub`.
4. **grub-btrfs:** instalar e rodar `grub-mkconfig` SÓ depois do snapper configurado
   e com pelo menos um snapshot criado. Ordem inversa deixa o submenu vazio.
5. **PipeWire:** verificar e remover `pulseaudio` antes de instalar — não coexistem.
6. **Hook do Plymouth no mkinitcpio:** ordem `base udev plymouth autodetect ...`.
   No hardware físico, o hook `encrypt` (LUKS) vem antes de `filesystems` e depois
   de `keyboard`.
7. **EDITOR vs VISUAL:** `EDITOR=nvim` (ferramentas de terminal — git, rebase),
   `VISUAL=code` (contextos gráficos). Não usar `code` como EDITOR.
8. **apply-theme.sh:** parte de usuário (gsettings) roda sem sudo; parte de sistema
   (GRUB, Plymouth, GDM) roda com sudo. São scripts separados, orquestrados.
9. **Extensões do GNOME** quebram entre versões do Shell. Na migração VM→hardware,
   se as versões diferirem, podem precisar de ajuste no `metadata.json`.
10. **peachd e rag-pf:** compartilham stack Python mas devem ter virtualenvs e
    bancos ChromaDB isolados. Fixar versões no `pyproject.toml` do `peachd`.
11. **pip-audit:** o `arch-audit` não cobre dependências instaladas via pip. Auditar
    o virtualenv do `peachd` com `pip-audit` separadamente.
12. **peachd como serviço de usuário:** só roda dentro da sessão gráfica, não em
    TTY puro antes do login. Decisão consciente.
13. **Cores ANSI 2 (green) e 6 (cyan):** a paleta PeachOS não tem verde nem ciano.
    Em zellij e ghostty, essas posições ANSI são mapeadas para `muted_plum (#6B5B7A)`
    e `grub_accent (#F1B098)` respectivamente. Decisão consciente — fica documentado
    no próprio arquivo de config de cada ferramenta.
14. **delta como pager do lazygit:** requer `delta` instalado (`pacman -S git-delta`).
    Incluir em `packages/pkglist.txt` quando esse arquivo for criado.
15. **wl-clipboard:** dependência de runtime de tmux, zellij e lazygit para copy/paste
    no Wayland. Incluir em `packages/pkglist.txt` (`pacman -S wl-clipboard`).
16. **Extensões obrigatórias do VS Code** (referenciadas no `settings.json`):
    `Catppuccin.catppuccin-vsc`, `Catppuccin.catppuccin-vsc-icons`,
    `esbenp.prettier-vscode`, `charliermarsh.ruff`, `rust-lang.rust-analyzer`.
    Quando `packages/` for criado, adicionar uma lista `vscode-extensions.txt`.

---

## Decisões que foram descartadas (não reintroduzir sem o usuário pedir)

- **opensnitch** — removido. Três ferramentas mexendo no nftables (firewalld +
  Docker + opensnitch) causavam instabilidade. Ficou só firewalld + firejail.
- **Auto Move Windows** (extensão GNOME) — removido. Disputava posicionamento de
  janela com o gTile. O gTile gerencia sozinho.
- **systemd-boot** — descartado em favor do GRUB (tema e dual boot).
- **Hook do reflector no pacman** — descartado. Trava atualizações. Ficou só o
  `reflector.timer` semanal.

---

## Convenções de trabalho

- Scripts de bloco da Fase 2 são numerados e idempotentes — rodar duas vezes não quebra.
- Todo script começa com `set -euo pipefail` e tem comentário de cabeçalho dizendo
  o que faz e a qual fase/bloco pertence.
- Verificações antes de ações destrutivas. Nunca assumir que um passo deu certo.
- Cores em qualquer arquivo de config derivam do `palette.json`.
- Dotfiles são aplicados via `stow` — cada pasta em `dotfiles/` espelha o `$HOME`.
- Commits em português, descritivos.
- Ao concluir trabalho de uma fase, atualizar o STATUS dela neste arquivo.

## Próximas tarefas (estado atual: maio 2026)

Fases 1, 2 e 3 concluídas. Próxima ordem sugerida:

1. Criar `themes/palette.json` (Fase 5 — desbloqueia `apply-theme.sh`).
2. Avançar Fase 4: revisar lista provisória de GNOME no `pkglist.txt`, definir
   as 13 extensões finais, theming via gradience.
3. Escrever `apply-theme.sh`, `apply-theme-user.sh`, `apply-theme-system.sh` (Fase 5).
4. Escrever `bootstrap.sh` (Fase 7).
5. Escrever `docs/MIGRATION.md` (Fase 7).

Consulte o `docs/PeachOS-Plano-Completo.docx` para o detalhamento de cada item.
