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

🚧 **Em desenvolvimento.** O projeto está na fase de implementação da configuração.
Veja o roadmap abaixo.

## Roadmap

O desenvolvimento está dividido em 8 fases. O detalhamento completo está em
[`docs/PeachOS-Plano-Completo.docx`](docs/).

| Fase | Escopo | Status |
|------|--------|--------|
| 1 | Preparar a máquina virtual | Planejada |
| 2 | Instalação e configuração base do Arch | Planejada |
| 3 | Ambiente de desenvolvimento | Planejada |
| 4 | Instalação e configuração do GNOME | Planejada |
| 5 | Identidade visual | Paleta e logo definidas |
| 6 | Configuração das ferramentas | Planejada |
| 7 | Estabilização e documentação | Planejada |
| 8 | Camada de IA | Planejada |

## Principais escolhas técnicas

- **Base:** Arch Linux, filesystem Btrfs com snapshots, bootloader GRUB
- **Desktop:** GNOME instalado minimamente, com tema próprio via libadwaita
- **Dev:** Rust, Python, Node, Java — cada um com gerenciador de versão
- **Terminal:** Ghostty, zsh + starship, ferramentas modernas (ripgrep, fd, eza...)
- **Segurança:** firewalld, firejail, LUKS, auditoria com Lynis/rkhunter/aide
- **IA:** daemon em Python acessível por terminal, atalho global e extensão do GNOME

## Identidade visual

Paleta pastel centrada em pêssego e lilás. A fonte da verdade das cores é
[`themes/palette.json`](themes/).

| | Cor | Hex |
|---|-----|-----|
| ⬜ | Cream | `#FFF8F5` |
| 🟧 | Peach | `#E8956D` |
| 🟪 | Lavender | `#C4A8D4` |
| 🌸 | Blossom | `#E8A0B8` |
| ⬛ | Deep Plum | `#2D2433` |

## Estrutura do repositório

```
peachos-config/
├── docs/         # plano completo das 8 fases
├── scripts/      # scripts de instalação modulares
├── dotfiles/     # configurações de apps (via stow)
├── themes/       # paleta, logo, wallpaper, temas
├── system/       # arquivos de configuração de sistema
├── security/     # firewall e SSH
└── packages/     # listas de pacotes
```

## Como usar

> ⚠️ O projeto ainda está em desenvolvimento. As instruções abaixo refletem o
> fluxo planejado.

A instalação base do Arch é feita manualmente via `archinstall`. Depois, a
configuração do PeachOS é aplicada a partir deste repositório:

```bash
git clone https://github.com/pedrovazs/PeachOS
cd PeachOS
chmod +x bootstrap.sh
./bootstrap.sh
```

O `bootstrap.sh` instala os pacotes e aplica a identidade visual completa.

## Licença

A definir.

---

<div align="center">
<sub>PeachOS — um espaço próprio para programar.</sub>
</div>
