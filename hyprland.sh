#!/bin/bash
# =========================================================
# SCRIPT 2 de 2: Instalación y Configuración de Hyprland
# Diseñado para ejecutarse DESPUÉS de la instalación base en una PC real.
# Incluye: Teclado Latino y Sistema de sonido completo con PipeWire.
# =========================================================
set -e

# --- 0. Variables y Directorios ---
HYPR_CONFIG_DIR="$HOME/.config/hypr"
HYPR_CONFIG_FILE="$HYPR_CONFIG_DIR/hyprland.conf"
HYPRPAPER_CONFIG_FILE="$HYPR_CONFIG_DIR/hyprpaper.conf"
MOD="SUPER" # Tecla Modificadora Principal (Tecla Windows/Super)

echo "--- 1. Actualizando el sistema e instalando paquetes de Hyprland y Sonido ---"
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm \
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

# --- 2. Creación y Configuración Funcional ---
echo "--- 2. Creando directorios de configuración ---"
mkdir -p "$HYPR_CONFIG_DIR"

if [ -f "$HYPR_CONFIG_FILE" ]; then
    mv "$HYPR_CONFIG_FILE" "$HYPR_CONFIG_FILE.bak"
    echo "✔ Se creó un respaldo de tu configuración anterior en: $HYPR_CONFIG_FILE.bak"
fi

echo "--- Escribiendo hyprland.conf (Configuración para PC Real) ---"
cat <<EOT > "$HYPR_CONFIG_FILE"
# -----------------------------------------------------
# Configuración Base para Hyprland
# -----------------------------------------------------
# === 1. Variables ===
\$mod = SUPER

# === 2. Entorno ===
# Descomenta la siguiente línea si experimentas problemas gráficos (pantalla negra, etc.)
# env = WLR_RENDERER_ALLOW_SOFTWARE,1
env = GDK_BACKEND,wayland,x11

# === 3. Autostart ===
exec-once = hyprpaper &
exec-once = waybar &
exec-once = /usr/lib/polkit-kde-authentication-agent-1 &

# === 4. Input (Teclado) ===
input {
    kb_layout = latam
    follow_mouse = 1
    sensitivity = 0
}

# === 5. Keybindings ===
bind = \$mod, RETURN, exec, kitty
bind = \$mod, R, exec, wofi --show drun
bind = \$mod, Q, killactive,
bind = \$mod, 1, workspace, 1
bind = \$mod, 2, workspace, 2
bind = \$mod SHIFT, 1, movetoworkspace, 1
bind = \$mod SHIFT, 2, movetoworkspace, 2
bind = \$mod, E, exec, hyprctl reload

# === 6. Configuración General ===
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgb(88c0d0)
    col.inactive_border = rgb(4c566a)
    layout = dwindle
}
EOT
echo "✔ Archivo hyprland.conf creado."

echo "--- Escribiendo hyprpaper.conf (Fondo de color sólido) ---"
cat <<EOT > "$HYPRPAPER_CONFIG_FILE"
# Configuración de Fondo de Pantalla
preload =
wallpaper = monitorname, 0x1A202C 
EOT
echo "✔ Archivo hyprpaper.conf creado."

# --- 3. Finalización ---
echo "--- 3. Habilitando SDDM (Display Manager) ---"
sudo systemctl enable sddm --now

echo ""
echo "======================================================="
echo "       🎉 Instalación y Configuración Completa 🎉"
echo "======================================================="
echo ""
echo "PASO FINAL REQUERIDO:"
echo "Por favor, **REINICIA** tu PC para iniciar SDDM:"
echo "  reboot"
echo ""
echo "Después de reiniciar, selecciona 'Hyprland' en la pantalla de login de SDDM."
