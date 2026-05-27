<div align="center">

# 🍑 PeachOS

**Ambiente desktop baseado em Arch Linux + GNOME, com identidade visual própria e camada de IA integrada.**

</div>

---

## O que é

PeachOS é uma configuração reproduzível de um ambiente desktop voltado para
desenvolvimento de software e projetos pessoais. É construído sobre o **Arch Linux**
com o **GNOME**, com tema próprio em tons pastel de pêssego e lilás, ferramentas de
desenvolvimento pré-configuradas e uma camada de IA integrada ao sistema.

Não é um sistema operacional escrito do zero — é uma distribuição/configuração sobre
o Arch. Este repositório (`peachos-config`) contém tudo que é necessário para recriar
o ambiente: scripts de instalação, dotfiles, temas e configurações de sistema.

## Status

🚧 **Em desenvolvimento ativo.** Fases 1–4 concluídas. Fase 5 (identidade visual) e
Fase 7 (documentação) em andamento. Pronto para instalação e teste em VM.

## Roadmap

| Fase | Escopo | Status |
|------|--------|--------|
| 1 | Preparar a máquina virtual | ✅ Concluída |
| 2 | Instalação e configuração base do Arch | ✅ Concluída |
| 3 | Ambiente de desenvolvimento | ✅ Concluída |
| 4 | GNOME mínimo + extensões + theming | ✅ Concluída (artefatos) |
| 5 | Identidade visual | 🚧 Em andamento — paleta, GRUB, Plymouth, GDM, scripts prontos; logo/wallpaper adiados |
| 6 | Configuração das ferramentas | 🚧 Parcial — lazygit, zellij, tmux, starship prontos |
| 7 | Estabilização e documentação | 🚧 Em andamento — bootstrap.sh e MIGRATION.md concluídos |
| 8 | Camada de IA (`peachd`) | 📋 Planejada — repositório próprio |

## O que está no repositório

| Artefato | O que faz |
|---|---|
| `bootstrap.sh` | Ponto de entrada único pós-Fase 2: roda `install.sh` + `apply-theme.sh` |
| `install.sh` | Instala pacotes, runtimes (Rust, Python, Node, Java) e aplica dotfiles |
| `apply-theme.sh` | Orquestra o tema completo (user + system) |
| `apply-theme-user.sh` | gsettings, Gradience, 12 extensões GNOME, Night Theme Switcher |
| `apply-theme-system.sh` | GRUB tema, Plymouth, GDM — requer sudo |
| `scripts/10-99` | 11 blocos modulares da Fase 2 (mirrors, áudio, AMD, Btrfs, GRUB…) |
| `dotfiles/` | zsh, starship, ghostty, zellij, tmux, lazygit, vscode — via stow |
| `themes/` | `palette.json` (fonte da verdade), Gradience preset, GRUB theme, Plymouth |
| `packages/` | `pkglist.txt`, `aurlist.txt`, `vscode-extensions.txt` |
| `system/` | Configs de /etc: sysctl, grub, journald, snapper, pacman, dconf/GDM |
| `security/` | sshd_config, aide.conf |
| `docs/MIGRATION.md` | Checklist completo VM → hardware físico (dual boot + LUKS) |

## Principais escolhas técnicas

- **Base:** Arch Linux, Btrfs com subvolumes `@`/`@home` + snapshots via snapper, GRUB
- **Segurança:** LUKS, firewalld, firejail, AIDE, sysctl hardening, sshd restritivo
- **Desktop:** GNOME instalado minimamente; 12 extensões incluindo Dash to Panel e gTile
- **Tema:** paleta própria em pêssego/lilás propagada por GRUB, Plymouth, GDM, Gradience, terminal
- **Dev:** Rust (rustup), Python (pyenv), Node (fnm), Java (sdkman)
- **Terminal:** Ghostty + zsh + starship + zellij/tmux + ripgrep, fd, bat, eza, fzf, zoxide
- **IA (Fase 8):** daemon `peachd` em Python, API Anthropic, socket Unix — repositório próprio

## Identidade visual

Paleta pastel centrada em pêssego e lilás. Fonte da verdade: [`themes/palette.json`](themes/palette.json).

| Cor | Hex | Uso principal |
|-----|-----|---------------|
| Cream | `#FFF8F5` | Background claro / foreground escuro |
| Peach | `#E8956D` | Accent primário |
| Grub Accent | `#F1B098` | Destaque GRUB, títulos Plymouth |
| Lavender | `#C4A8D4` | Accent secundário, subtítulos |
| Blossom | `#E8A0B8` | Accent terciário |
| Deep Plum | `#2D2433` | Background escuro, fundo GDM/Plymouth |
| Muted Plum | `#6B5B7A` | Texto secundário |

## Como usar

A instalação base do Arch é feita manualmente via `archinstall`. Consulte
[`docs/MIGRATION.md`](docs/MIGRATION.md) para o checklist completo, incluindo
dual boot com Windows e LUKS.

```bash
# Após archinstall + Fase 2 (scripts/10 → 99, um por vez como root):

git clone https://github.com/pedrovazs/PeachOS
cd PeachOS

# Fases 3 + 5 de uma vez (pacotes, dotfiles, tema)
./bootstrap.sh

# Ou em partes:
./install.sh                    # só pacotes e dotfiles
./apply-theme.sh                # só tema completo
./apply-theme.sh --user-only    # só extensões, fontes, modo escuro
./apply-theme.sh --system-only  # só GRUB + Plymouth + GDM
```

> Se rodar `bootstrap.sh` em TTY (antes do primeiro login gráfico), o tema
> de sistema é aplicado automaticamente. Após o login no GNOME, rode
> `./apply-theme.sh --user-only` para completar a parte de usuário.

Os scripts são idempotentes — podem ser executados mais de uma vez sem quebrar.

## Licença

A definir.

---

<div align="center">
<sub>PeachOS — um espaço próprio para programar.</sub>
</div>
