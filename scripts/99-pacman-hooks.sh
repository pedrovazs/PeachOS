#!/usr/bin/env bash
# Fase 2 — Bloco 11: Pacman hooks e paru (AUR helper)
# Instala paru e configura hooks para manutenção automática.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> [99] Pacman hooks e paru"

# --- paru ---
if ! command -v paru &>/dev/null; then
    echo "  -> Instalando paru (AUR helper)..."

    # Dependências para build
    pacman -S --noconfirm --needed base-devel git

    PARU_TMP=$(mktemp -d)
    trap 'rm -rf "$PARU_TMP"' EXIT
    git clone --depth=1 https://aur.archlinux.org/paru.git "$PARU_TMP/paru"

    # paru deve ser compilado como usuário normal — detectar quem chamou o script
    REAL_USER="${SUDO_USER:-$USER}"
    if [[ "$REAL_USER" == "root" ]]; then
        echo "  ERRO: paru não pode ser compilado como root."
        echo "  Execute este bloco como usuário comum com sudo, ou instale paru manualmente."
        exit 1
    fi

    chown -R "$REAL_USER:$REAL_USER" "$PARU_TMP"
    su - "$REAL_USER" -c "cd '$PARU_TMP/paru' && makepkg -si --noconfirm"
    echo "  -> paru instalado."
else
    echo "  -> paru já instalado."
fi

# --- paru.conf ---
echo "  -> Copiando paru.conf..."
cp "$REPO_DIR/system/pacman/paru.conf" /etc/paru.conf

# --- pacman hooks ---
echo "  -> Copiando hooks do pacman..."
HOOKS_SRC="$REPO_DIR/system/pacman/hooks"
HOOKS_DST="/etc/pacman.d/hooks"
mkdir -p "$HOOKS_DST"

for hook in "$HOOKS_SRC"/*.hook; do
    [[ -f "$hook" ]] || continue
    echo "    -> $(basename "$hook")"
    cp "$hook" "$HOOKS_DST/"
done

echo "==> [99] Concluído."
echo "    AUR: paru -Syu"
echo "    Hooks em: /etc/pacman.d/hooks/"
