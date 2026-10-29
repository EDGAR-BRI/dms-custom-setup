#!/bin/bash
set -e

echo "============================================================"
echo "    🚀 INSTALADOR COMPLETO DE CONFIGURACIONES (DOTFILES)    "
echo "    DMS + Niri + SDDM + Howdy + Terminales + Gestos Touch   "
echo "============================================================"
echo ""

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURRENT_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$CURRENT_USER")
BACKUP_DIR="$USER_HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

echo "👤 Usuario objetivo: $CURRENT_USER"
echo "📁 Directorio base:  $BASE_DIR"
echo ""

# 0. Backup de configuraciones previas
echo "[1/8] 📦 Creando copia de seguridad de configuraciones actuales..."
mkdir -p "$BACKUP_DIR"
for cfg in dms niri kitty fastfetch starship fish dunst rofi btop cava wlogout; do
    if [ -d "$USER_HOME/.config/$cfg" ]; then
        cp -r "$USER_HOME/.config/$cfg" "$BACKUP_DIR/" 2>/dev/null || true
    fi
done
echo "  -> Copia de seguridad guardada en: $BACKUP_DIR"

# 1. Compilar e instalar el módulo PAM inteligente
echo "[2/8] 🔐 Compilando módulo PAM pam_check_empty.so..."
sudo gcc -fPIC -shared -O2 "$BASE_DIR/pam/pam_check_empty.c" -o /usr/lib/security/pam_check_empty.so -lpam
sudo chmod 755 /usr/lib/security/pam_check_empty.so
echo "  -> Instalado /usr/lib/security/pam_check_empty.so"

# 2. Configurar reglas de PAM
echo "[3/8] 🛡️  Instalando reglas de PAM (dankshell, sddm, sudo)..."
sudo cp "$BASE_DIR/pam/dankshell" /etc/pam.d/dankshell
sudo cp "$BASE_DIR/pam/sddm" /etc/pam.d/sddm
sudo cp "$BASE_DIR/pam/sudo" /etc/pam.d/sudo
echo "  -> Reglas PAM configuradas (soporte Howdy + contraseña tradicional)"

# 3. Instalar scripts auxiliares y ejecutables
echo "[4/8] ⚙️  Instalando scripts de usuario en ~/.local/bin..."
mkdir -p "$USER_HOME/.local/bin"
cp "$BASE_DIR/local/bin/"* "$USER_HOME/.local/bin/"
chmod +x "$USER_HOME/.local/bin/"*
if [ -f "$BASE_DIR/local/bin/check-howdy-sudo.sh" ]; then
    sudo cp "$BASE_DIR/local/bin/check-howdy-sudo.sh" /usr/local/bin/check-howdy-sudo.sh
    sudo chmod 755 /usr/local/bin/check-howdy-sudo.sh
fi
echo "  -> Scripts instalados con permisos de ejecución"

# 4. Compilar demonio de gestos niri-touchd
echo "[5/8] 🖐️ Compilando demonio de gestos niri-touchd..."
if [ -f "$BASE_DIR/local/src/niri-touchd/main.c" ]; then
    mkdir -p "$USER_HOME/.local/src/niri-touchd"
    cp -r "$BASE_DIR/local/src/niri-touchd/"* "$USER_HOME/.local/src/niri-touchd/"
    gcc -O2 "$BASE_DIR/local/src/niri-touchd/main.c" -o "$USER_HOME/.local/bin/niri-touchd" -lm
    chmod +x "$USER_HOME/.local/bin/niri-touchd"
    
    mkdir -p "$USER_HOME/.config/systemd/user"
    cp "$BASE_DIR/.config/systemd/user/niri-touchd.service" "$USER_HOME/.config/systemd/user/"
    systemctl --user daemon-reload 2>/dev/null || true
    systemctl --user enable --now niri-touchd.service 2>/dev/null || true
    echo "  -> niri-touchd compilado y servicio habilitado"
fi

# 5. Instalar todas las configuraciones de ~/.config
echo "[6/8] 🎨 Desplegando dotfiles en ~/.config..."
mkdir -p "$USER_HOME/.config"
cp -r "$BASE_DIR/.config/"* "$USER_HOME/.config/"
chmod +x "$USER_HOME/.config/dms/plugins/githubStats/fetch.sh" 2>/dev/null || true
if [ -f "$BASE_DIR/.zshrc" ]; then
    cp "$BASE_DIR/.zshrc" "$USER_HOME/.zshrc"
fi
echo "  -> Dotfiles desplegados: dms, niri, kitty, fastfetch, starship, fish, rofi, dunst, btop, cava, wlogout"

# 6. Instalar tema SDDM
echo "[7/8] 🖼️  Instalando tema de inicio de sesión SDDM (Corners)..."
if [ -d "$BASE_DIR/sddm-theme/Corners" ]; then
    sudo mkdir -p /usr/share/sddm/themes/Corners
    sudo cp -r "$BASE_DIR/sddm-theme/Corners/"* /usr/share/sddm/themes/Corners/
    sudo chown -R "$CURRENT_USER:$CURRENT_USER" /usr/share/sddm/themes/Corners
    echo "  -> Tema SDDM instalado en /usr/share/sddm/themes/Corners"
fi

# 7. Configuración de Howdy
echo "[8/8] 📷 Verificando configuración de cámara Howdy..."
if [ -f "$BASE_DIR/howdy/config.ini" ] && [ -d "/etc/howdy" ]; then
    echo "  -> Instalando perfil de cámara optimizado (/etc/howdy/config.ini)..."
    sudo cp "$BASE_DIR/howdy/config.ini" /etc/howdy/config.ini
fi

echo ""
echo "============================================================"
echo "    ✨ ¡CONFIGURACIÓN COMPLETADA CON ÉXITO! ✨"
echo "============================================================"
echo "💡 Recuerda recargar Niri o reiniciar tu sesión para ver"
echo "   todos los cambios activos."
echo ""
