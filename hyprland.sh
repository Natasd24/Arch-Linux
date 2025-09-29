#!/bin/bash

# --- Script para CORREGIR y crear una configuración funcional de Hyprland ---
# Soluciona: Error de sintaxis en hyprland.conf (Línea 7) y ventana de Kitty invisible.

# --- 0. Variables y Directorios ---
HYPR_CONFIG_DIR="$HOME/.config/hypr"
HYPR_CONFIG_FILE="$HYPR_CONFIG_DIR/hyprland.conf"
HYPRPAPER_CONFIG_FILE="$HYPR_CONFIG_DIR/hyprpaper.conf"

echo "--- 1. Creando respaldo y preparando archivos ---"

# Crear respaldo de la configuración rota
if [ -f "$HYPR_CONFIG_FILE" ]; then
    mv "$HYPR_CONFIG_FILE" "$HYPR_CONFIG_FILE.BAK_ROTO"
    echo "✔ Respaldo de la configuración anterior guardado como .BAK_ROTO"
fi

# 1.1 Creando hyprland.conf (Configuración principal)
echo "--- 2. Escribiendo hyprland.conf CORREGIDO ---"
cat <<EOT > "$HYPR_CONFIG_FILE"
# -----------------------------------------------------
# Configuración Base FUNCIONAL de Hyprland (Corregida)
# -----------------------------------------------------

# === 1. Variables ===
# FIX: Corregido el error de sintaxis de la línea 7
\$mod = SUPER 

# === 2. Entorno y Compatibilidad (FIX para Kitty invisible) ===
env = WLR_RENDERER_ALLOW_SOFTWARE,1 # Permite el fallback a software (clave para VirtualBox)
env = WLR_NO_HARDWARE_CURSORS,1     # Previene problemas con el cursor
env = GDK_BACKEND,wayland,x11       # Fuerza a las aplicaciones GTK a usar Wayland

# === 3. Autostart (Aplicaciones al inicio) ===
exec-once = hyprpaper &
exec-once = waybar &
exec-once = /usr/lib/polkit-kde-authentication-agent-1 & 

# === 4. Input (Teclado y Ratón) ===
input {
    kb_layout = latam # Configuración para teclado latino
    follow_mouse = 1
    sensitivity = 0
}

# === 5. Keybindings (Atajos de teclado) ===

# Terminal - ¡FIX: Debe abrirse y mostrarse correctamente!
bind = \$mod, RETURN, exec, kitty

# Launcher - Wofi
bind = \$mod, R, exec, wofi --show drun

# Cerrar Ventana Activa
bind = \$mod, Q, killactive,

# Cambiar de Workspace
bind = \$mod, 1, workspace, 1
bind = \$mod, 2, workspace, 2

# Mover la ventana al Workspace
bind = \$mod SHIFT, 1, movetoworkspace, 1
bind = \$mod SHIFT, 2, movetoworkspace, 2

# Recargar configuración de Hyprland
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
echo "✔ Archivo hyprland.conf (Corregido) creado con éxito."


# 1.2 Creando hyprpaper.conf
echo "--- 3. Escribiendo hyprpaper.conf (Fondo de color sólido azul) ---"
cat <<EOT > "$HYPRPAPER_CONFIG_FILE"
# Configuración de Fondo de Pantalla
preload =
wallpaper = monitorname, 0x1A202C 
EOT
echo "✔ Archivo hyprpaper.conf creado."


# --- 4. Instrucciones Finales ---
echo ""
echo "======================================================="
echo "        ✅ Configuración FUNCIONAL Aplicada ✅"
echo "======================================================="
echo ""
echo "Para aplicar estos cambios y solucionar los problemas:"
echo "1. Si estás en la sesión de Hyprland rota, ve al TTY (Ctrl+Alt+F3)."
echo "2. O simplemente **REINICIA** la máquina virtual."
echo ""
echo "Después de reiniciar y seleccionar Hyprland en SDDM:"
echo "• Deberías ver el fondo de pantalla azul oscuro."
echo "• La Terminal Kitty se abrirá y **mostrará** el contenido al usar:"
echo "  Tecla **SUPER (Windows) + ENTER**"
echo ""
