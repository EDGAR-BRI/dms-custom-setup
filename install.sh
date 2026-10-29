#!/bin/bash
set -e

echo "=================================================="
echo "    Instalador de Configuración DMS + SDDM + Howdy"
echo "=================================================="

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURRENT_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$CURRENT_USER")

# 1. Compilar e instalar el módulo PAM inteligente
echo "[1/6] Compilando módulo pam_check_empty.so..."
sudo gcc -fPIC -shared -O2 "$BASE_DIR/pam/pam_check_empty.c" -o /usr/lib/security/pam_check_empty.so -lpam
sudo chmod 755 /usr/lib/security/pam_check_empty.so
echo "  -> Instalado /usr/lib/security/pam_check_empty.so"

# 2. Configurar archivos PAM
echo "[2/6] Configurando reglas de PAM (dankshell, sddm, sudo)..."
sudo cp "$BASE_DIR/pam/dankshell" /etc/pam.d/dankshell
sudo cp "$BASE_DIR/pam/sddm" /etc/pam.d/sddm
sudo cp "$BASE_DIR/pam/sudo" /etc/pam.d/sudo
echo "  -> Reglas PAM actualizadas con éxito"

# 3. Instalar scripts auxiliares
echo "[3/6] Instalando scripts de control de Howdy..."
sudo cp "$BASE_DIR/scripts/check-howdy-sudo.sh" /usr/local/bin/check-howdy-sudo.sh
sudo chmod 755 /usr/local/bin/check-howdy-sudo.sh

mkdir -p "$USER_HOME/.local/bin"
cp "$BASE_DIR/scripts/toggle-howdy-sudo.sh" "$USER_HOME/.local/bin/toggle-howdy-sudo.sh"
chmod +x "$USER_HOME/.local/bin/toggle-howdy-sudo.sh"
echo "  -> Scripts instalados en /usr/local/bin y $USER_HOME/.local/bin"

# 4. Instalar plugins de DMS
echo "[4/6] Instalando complementos de DMS..."
mkdir -p "$USER_HOME/.config/dms/plugins"
cp -r "$BASE_DIR/plugins/"* "$USER_HOME/.config/dms/plugins/"
chmod +x "$USER_HOME/.config/dms/plugins/githubStats/fetch.sh" 2>/dev/null || true
echo "  -> Plugins instalados en $USER_HOME/.config/dms/plugins"

# 5. Instalar tema de SDDM
echo "[5/6] Instalando tema de SDDM..."
sudo mkdir -p /usr/share/sddm/themes/Corners
sudo cp -r "$BASE_DIR/sddm-theme/Corners/"* /usr/share/sddm/themes/Corners/
sudo chown -R "$CURRENT_USER:$CURRENT_USER" /usr/share/sddm/themes/Corners
echo "  -> Tema SDDM instalado en /usr/share/sddm/themes/Corners"

# 6. Informar sobre atajos de teclado
echo "[6/6] Verificando atajos de Niri..."
echo "  -> Si aún no tienes el atajo para alternar el reconocimiento en sudo,"
echo "     agrega la siguiente línea a tu ~/.config/niri/config.kdl:"
echo "     Mod+Ctrl+Shift+S hotkey-overlay-title=\"Alternar Reconocimiento Facial Sudo\" { spawn-sh \"$USER_HOME/.local/bin/toggle-howdy-sudo.sh\"; }"

echo ""
echo "=================================================="
echo "    ¡Instalación completada con éxito!"
echo "=================================================="
