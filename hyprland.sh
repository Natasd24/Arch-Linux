#!/bin/bash
# ===================================================================================
# SCRIPT FINAL: Instalación Completa de Hyprland (Versión Definitiva)
#
# Este script automatiza todos los pasos exitosos del proceso manual:
#   1. Optimiza los servidores de descarga (mirrors) con Reflector.
#   2. Actualiza el sistema.
#   3. Instala TODOS los paquetes del entorno gráfico en una sola línea.
#   4. Crea los archivos de configuración en el directorio del usuario.
#   5. Habilita el inicio de sesión gráfico.
#
# INSTRUCCIONES: EJECUTAR SIN 'sudo'. El script lo solicitará cuando sea necesario.
# ===================================================================================
set -e

echo "--- Paso 1: Preparando el sistema y optimizando los servidores de descarga ---"

# Pide la contraseña al inicio para las operaciones de sudo que vendrán después.
sudo -v

# Elimina el archivo de bloqueo de pacman por si una ejecución anterior falló.
sudo rm -f /var/lib/pacman/db.lck

echo "--> Instalando 'reflector' para optimizar los mirrors..."
sudo pacman -S --needed --noconfirm reflector

echo "--> Optimizando la lista de mirrors para México y EE. UU. (puede tardar un minuto)..."
sudo reflector --verbose --country Mexico --country 'United States' -l 6 --sort rate --save /etc/pacman.d/mirrorlist

echo "--> Forzando la sincronización con los nuevos y rápidos mirrors..."
sudo pacman -Syyu --noconfirm

echo ""
echo "--- Paso 2: Instalando el entorno Hyprland y las aplicaciones ---"
# Instalación de todos los paquetes requeridos en una sola línea, como solicitaste.
sudo pacman -S --needed --noconfirm hyprland mesa xorg-wayland xdg-desktop-portal-hyprland qt5-wayland qt6-wayland polkit-kde-agent pipewire wireplumber pipewire-pulse pipewire-alsa hyprpaper kitty wofi waybar sddm
echo "✔ Instalación de todos los paquetes completada."
echo ""

# --- Paso 3: Creando los archivos de configuración ---
echo "--- Paso 3: Creando los archivos de configuración para tu usuario ---"

# Define las variables de configuración. $HOME será el correcto (ej. /home/tu_usuario)
HYPR_CONFIG_DIR="$HOME/.config/hypr"
HYPR_CONFIG_FILE="$HYPR_CONFIG_DIR/hyprland.conf"
HYPRPAPER_CONFIG_FILE="$HYPR_CONFIG_DIR/hyprpaper.conf"
MOD="SUPER"

# Crea el directorio de configuración
mkdir -p "$HYPR_CONFIG_DIR"

echo "--> Escribiendo archivo de configuración principal: hyprland.conf"
cat <<EOT > "$HYPR_CONFIG_FILE"
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
cat <<EOT > "$HYPRPAPER_CONFIG_FILE"
# Configuración de Fondo de Pantalla
preload =
wallpaper = monitorname, 0x1A202C
EOT
echo "✔ Archivos de configuración creados."
echo ""

# --- Paso 4: Finalización ---
echo "--- Paso 4: Habilitando el Inicio de Sesión Gráfico ---"
sudo systemctl enable sddm

echo ""
echo "======================================================="
echo "       🎉 ¡Instalación y Configuración Completa! 🎉"
echo "======================================================="
echo ""
echo "PASO FINAL REQUERIDO:"
echo "Por favor, **REINICIA** tu PC para iniciar tu nuevo escritorio:"
echo "  reboot"
