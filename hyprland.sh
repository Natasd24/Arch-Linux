#!/bin/bash
# ===================================================================================
# SCRIPT FINAL: Instalación Completa de Hyprland + Helpers AUR (Versión Definitiva)
#
# Este script automatiza:
#   1. Optimización de mirrors.
#   2. Actualización del sistema.
#   3. Instalación del entorno gráfico base.
#   4. Instalación de los AUR Helpers 'yay' y 'paru'.
#   5. Creación de archivos de configuración iniciales.
#   6. Habilitación del inicio de sesión gráfico.
#
# INSTRUCCIONES: EJECUTAR SIN 'sudo'. El script lo solicitará cuando sea necesario.
# ===================================================================================
set -e

# --- Paso 1: Preparación del sistema ---
echo "--- Paso 1: Preparando el sistema y optimizando los servidores de descarga ---"
sudo -v # Pide la contraseña al inicio
sudo rm -f /var/lib/pacman/db.lck # Desbloquea pacman

echo "--> Instalando 'reflector' para optimizar los mirrors..."
sudo pacman -S --needed --noconfirm reflector
echo "--> Optimizando la lista de mirrors para México y EE. UU. (puede tardar un minuto)..."
sudo reflector --verbose --country Mexico --country 'United States' -l 6 --sort rate --save /etc/pacman.d/mirrorlist
echo "--> Forzando la sincronización con los nuevos y rápidos mirrors..."
sudo pacman -Syyu --noconfirm

# --- Paso 2: Instalación del Entorno Gráfico ---
echo ""
echo "--- Paso 2: Instalando el entorno Hyprland y las aplicaciones ---"
sudo pacman -S --needed --noconfirm hyprland mesa xorg-xwayland xdg-desktop-portal-hyprland qt5-wayland qt6-wayland polkit-kde-agent pipewire wireplumber pipewire-pulse pipewire-alsa hyprpaper kitty wofi waybar sddm
echo "✔ Instalación de paquetes del entorno completada."

# --- Paso 3: Instalación de Helpers del AUR ---
echo ""
echo "--- Paso 3: Instalando Helpers del AUR (yay y paru) ---"
echo "--> Instalando dependencias para compilar: git y base-devel..."
sudo pacman -S --needed --noconfirm git base-devel

# Se crea un directorio temporal que será eliminado al final
TEMP_AUR_DIR=$(mktemp -d)

# Instalar yay
echo "--> Compilando e instalando 'yay'..."
if ! command -v yay &> /dev/null; then
    git clone https://aur.archlinux.org/yay.git "$TEMP_AUR_DIR/yay"
    (cd "$TEMP_AUR_DIR/yay" && makepkg -si --noconfirm)
else
    echo "'yay' ya está instalado. Omitiendo."
fi

# Instalar paru
echo "--> Compilando e instalando 'paru'..."
if ! command -v paru &> /dev/null; then
    git clone https://aur.archlinux.org/paru.git "$TEMP_AUR_DIR/paru"
    (cd "$TEMP_AUR_DIR/paru" && makepkg -si --noconfirm)
else
    echo "'paru' ya está instalado. Omitiendo."
fi

# Limpiar el directorio temporal
rm -rf "$TEMP_AUR_DIR"
echo "✔ yay y paru instalados y archivos temporales eliminados."

# --- Paso 4: Creación de Archivos de Configuración ---
echo ""
echo "--- Paso 4: Creando los archivos de configuración para tu usuario ---"
HYPR_CONFIG_DIR="$HOME/.config/hypr"
mkdir -p "$HYPR_CONFIG_DIR"

echo "--> Escribiendo archivo de configuración principal: hyprland.conf"
cat <<EOT > "$HYPR_CONFIG_DIR/hyprland.conf"
# Configuración Base para Hyprland
\$mod = SUPER
env = GDK_BACKEND,wayland,x11
exec-once = hyprpaper &
exec-once = waybar &
exec-once = /usr/lib/polkit-kde-authentication-agent-1 &
input {
    kb_layout = latam
    follow_mouse = 1
    sensitivity = 0
}
bind = \$mod, RETURN, exec, kitty
bind = \$mod, R, exec, wofi --show drun
bind = \$mod, Q, killactive,
bind = \$mod, 1, workspace, 1
bind = \$mod, 2, workspace, 2
bind = \$mod SHIFT, 1, movetoworkspace, 1
bind = \$mod SHIFT, 2, movetoworkspace, 2
bind = \$mod, E, exec, hyprctl reload
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgb(88c0d0)
    col.inactive_border = rgb(4c566a)
    layout = dwindle
}
EOT

echo "--> Escribiendo archivo de configuración del fondo de pantalla: hyprpaper.conf"
cat <<EOT > "$HYPR_CONFIG_DIR/hyprpaper.conf"
# Configuración de Fondo de Pantalla
preload =
wallpaper = monitorname, 0x1A202C
EOT
echo "✔ Archivos de configuración creados."

# --- Paso 5: Finalización ---
echo ""
echo "--- Paso 5: Habilitando el Inicio de Sesión Gráfico ---"
sudo systemctl enable sddm

echo ""
echo "======================================================="
echo "        🎉 ¡Instalación y Configuración Completa! 🎉"
echo "======================================================="
echo ""
echo "PASO FINAL REQUERIDO:"
echo "Por favor, **REINICIA** tu PC para iniciar tu nuevo escritorio:"
echo "  reboot"
