#!/bin/bash
# ===================================================================================
# SCRIPT 2 de 2: Instalación de Hyprland (Versión Final y Robusta)
#
# CARACTERÍSTICAS:
# - Repara automáticamente los servidores de descarga (mirrors) para evitar bloqueos.
# - Es seguro volver a ejecutarlo: no reinstalará paquetes que ya existan.
# - Separa los pasos de actualización e instalación para máxima estabilidad.
# ===================================================================================
set -e

# --- 0. Variables y Directorios ---
HYPR_CONFIG_DIR="$HOME/.config/hypr"
HYPR_CONFIG_FILE="$HYPR_CONFIG_DIR/hyprland.conf"
HYPRPAPER_CONFIG_FILE="$HYPR_CONFIG_DIR/hyprpaper.conf"
MOD="SUPER" # Tecla Modificadora Principal (Tecla Windows/Super)

# --- 1. Preparación y Optimización de Mirrors ---
echo "--- Paso 1: Preparando el sistema y optimizando los servidores de descarga ---"

# Elimina el archivo de bloqueo de pacman por si una ejecución anterior falló
sudo rm -f /var/lib/pacman/db.lck

echo "--> Instalando 'reflector' para optimizar los mirrors..."
sudo pacman -S --needed --noconfirm reflector

echo "--> Optimizando la lista de mirrors (servidores). Esto puede tardar un minuto..."
sudo reflector --verbose --country Mexico --country 'United States' -l 6 --sort rate --save /etc/pacman.d/mirrorlist

echo "--> Forzando la sincronización con los nuevos mirrors..."
sudo pacman -Syyu --noconfirm

# --- 2. Instalación de Paquetes del Entorno Gráfico ---
echo "--- Paso 2: Instalando el entorno Hyprland y las aplicaciones ---"
sudo pacman -S --needed --noconfirm \
    hyprland \
    mesa \
    xorg-xwayland \
    xdg-desktop-portal-hyprland \
    qt5-wayland qt6-wayland \
    polkit-kde-agent \
    \
    # Servidor de Sonido Moderno (PipeWire)
    pipewire \
    wireplumber \
    pipewire-pulse \
    pipewire-alsa \
    \
    # Componentes del Entorno Gráfico
    hyprpaper kitty wofi waybar sddm

echo "✔ Instalación de paquetes completada."

# --- 3. Creación de Archivos de Configuración ---
echo "--- Paso 3: Creando los archivos de configuración ---"
mkdir -p "$HYPR_CONFIG_DIR"

if [ -f "$HYPR_CONFIG_FILE" ]; then
    mv "$HYPR_CONFIG_FILE" "$HYPR_CONFIG_FILE.bak"
    echo "✔ Se creó un respaldo de tu configuración anterior."
fi

echo "--> Escribiendo hyprland.conf..."
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

echo "--> Escribiendo hyprpaper.conf..."
cat <<EOT > "$HYPRPAPER_CONFIG_FILE"
# Configuración de Fondo de Pantalla
preload =
wallpaper = monitorname, 0x1A202C 
EOT
echo "✔ Archivos de configuración creados."

# --- 4. Finalización ---
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
