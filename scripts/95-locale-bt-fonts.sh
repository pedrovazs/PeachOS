#!/usr/bin/env bash
# Fase 2 — Bloco 10: Locale, Bluetooth e fontes base
set -euo pipefail

echo "==> [95] Locale, Bluetooth e Fontes"

# --- locale ---
LOCALE="pt_BR.UTF-8"
LANG_FILE="/etc/locale.conf"
GEN_FILE="/etc/locale.gen"

# Descomenta pt_BR.UTF-8 se estiver comentado ou ausente.
# grep -qF busca a string sem âncora: encontra tanto "#pt_BR..." quanto "pt_BR...".
# Se só a versão ativa está presente (!grep FALSE, 2ª cond FALSE) → sed não roda (correto).
if ! grep -qF "${LOCALE}" "$GEN_FILE" 2>/dev/null \
    || grep -qF "#${LOCALE}" "$GEN_FILE" 2>/dev/null; then
    echo "  -> Habilitando locale ${LOCALE}..."
    sed -i "s|^#${LOCALE}|${LOCALE}|" "$GEN_FILE"
fi

# Garantir que en_US também está habilitado (algumas ferramentas dependem)
if grep -qF "#en_US.UTF-8" "$GEN_FILE" 2>/dev/null; then
    sed -i 's|^#en_US.UTF-8|en_US.UTF-8|' "$GEN_FILE"
fi

echo "  -> Gerando locales..."
locale-gen

echo "  -> Configurando LANG padrão..."
cat > "$LANG_FILE" <<EOF
LANG=pt_BR.UTF-8
LC_ADDRESS=pt_BR.UTF-8
LC_IDENTIFICATION=pt_BR.UTF-8
LC_MEASUREMENT=pt_BR.UTF-8
LC_MONETARY=pt_BR.UTF-8
LC_NAME=pt_BR.UTF-8
LC_NUMERIC=pt_BR.UTF-8
LC_PAPER=pt_BR.UTF-8
LC_TELEPHONE=pt_BR.UTF-8
LC_TIME=pt_BR.UTF-8
EOF

# --- timezone ---
TIMEZONE="America/Sao_Paulo"
ZONEINFO="/usr/share/zoneinfo/${TIMEZONE}"
[[ -f "$ZONEINFO" ]] || { echo "  ERRO: timezone ${ZONEINFO} não encontrado." >&2; exit 1; }
if [[ "$(readlink /etc/localtime 2>/dev/null)" != *"$TIMEZONE"* ]]; then
    echo "  -> Configurando timezone ${TIMEZONE}..."
    ln -sf "$ZONEINFO" /etc/localtime
    hwclock --systohc
fi

# --- Bluetooth ---
BT_PKGS=(bluez bluez-utils)
echo "  -> Instalando Bluetooth..."
pacman -S --noconfirm --needed "${BT_PKGS[@]}"
systemctl enable --now bluetooth

# --- Fontes ---
FONT_PKGS=(
    ttf-jetbrains-mono-nerd      # terminal principal
    noto-fonts                   # cobertura Unicode base
    noto-fonts-cjk               # chinês, japonês, coreano
    noto-fonts-emoji             # emojis
    ttf-liberation               # métricas compatíveis com Windows (docs)
    ttf-dejavu
)

echo "  -> Instalando fontes..."
pacman -S --noconfirm --needed "${FONT_PKGS[@]}"

echo "  -> Atualizando cache de fontes..."
fc-cache -f

echo "  -> Fontes JetBrains Mono Nerd disponíveis:"
fc-list | grep -i 'jetbrains' | head -5 || echo "    (reinicie a sessão para ver)"

echo "==> [95] Concluído."
