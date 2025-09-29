#!/bin/bash

# --- Script de Instalación y Configuración Base Funcional de Hyprland ---
# Versión optimizada para VirtualBox (Base Arch Linux)
# Incluye: Instalación de paquetes, drivers Mesa, configuración Latino (latam),
# atajos de teclado y fondo de pantalla (wallpaper).

# --- 0. Variables y Directorios ---
HYPR_CONFIG_DIR="$HOME/.config/hypr"
HYPR_CONFIG_FILE="$HYPR_CONFIG_DIR/hyprland.conf"
HYPRPAPER_CONFIG_FILE="$HYPR_CONFIG_DIR/hyprpaper.conf"
MOD="SUPER" # Tecla Modificadora Principal (Tecla Windows/Super)

echo "--- 1. Actualizando el sistema antes de instalar Hyprland ---"
sudo pacman -Syu --noconfirm

# --- 2. Instalación de Hyprland y Dependencias Esenciales ---
# Se instala:
# - hyprland, mesa (drivers cruciales para VirGL en VirtualBox), xorg-xwayland.
# - hyprpaper (gestor de fondos), kitty (terminal), wofi (launcher), waybar (barra).
# - xdg-desktop-portal-hyprland (integración con aplicaciones modernas).
# - qt/polkit (soporte de permisos y apps QT).
echo "--- 2. Instalando Hyprland, drivers Mesa y componentes de ecosistema ---"
sudo pacman -S --noconfirm \
    hyprland \
    mesa \
    xorg-xwayland \
    xdg-desktop-portal-hyprland \
    qt5-wayland qt6-wayland \
    polkit-kde-agent \
    hyprpaper kitty wofi waybar sddm

# --- 3. Generación de la Configuración Base Funcional ---

echo "--- 3. Creando directorio de configuración y respaldando si existe ---"
mkdir -p "$HYPR_CONFIG_DIR"
if [ -f "$HYPR_CONFIG_FILE" ]; then
    mv "$HYPR_CONFIG_FILE" "$HYPR_CONFIG_FILE.bak"
    echo "✔ Se creó un respaldo de tu configuración anterior."
fi

# 3.1 Creando hyprland.conf (Configuración principal)
echo "--- Escribiendo hyprland.conf: Teclado Latino, Atajos para Kitty/Wofi ---"
cat <<EOT > "$HYPR_CONFIG_FILE"
# -----------------------------------------------------
# Configuración Base Funcional de Hyprland
# Diseñada para VirtualBox y Teclado Latino (latam)
# -----------------------------------------------------

# === 1. Variables ===
\$ $MOD, Super

# === 2. Autostart (Aplicaciones al inicio) ===
exec-once = hyprpaper &
exec-once = waybar &
exec-once = /usr/lib/polkit-kde-authentication-agent-1 & # Agente de permisos

# === 3. Input (Teclado y Ratón) ===
input {
    kb_layout = latam # CLAVE: Configuración para teclado latino
    follow_mouse = 1
    sensitivity = 0
}

# === 4. Keybindings (Atajos de teclado) ===

# Terminal - CLAVE: Abre Kitty con Win + Enter
bind = $MOD, RETURN, exec, kitty

# Launcher - CLAVE: Abre Wofi con Win + R
bind = $MOD, R, exec, wofi --show drun

# Cerrar Ventana Activa
bind = $MOD, Q, killactive,

# Cambiar de Workspace (Espacio de Trabajo)
bind = $MOD, 1, workspace, 1
bind = $MOD, 2, workspace, 2
bind = $MOD, 3, workspace, 3
bind = $MOD, 4, workspace, 4
bind = $MOD, 5, workspace, 5

# Mover la ventana al Workspace
bind = $MOD SHIFT, 1, movetoworkspace, 1
bind = $MOD SHIFT, 2, movetoworkspace, 2

# Recargar configuración de Hyprland
bind = $MOD, E, exec, hyprctl reload

# === 5. Configuración General (Opcional, pero recomendado) ===
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgb(88c0d0)
    col.inactive_border = rgb(4c566a)
    layout = dwindle
}

EOT

# 3.2 Creando hyprpaper.conf (Fondo de Pantalla Sólido)
echo "--- Escribiendo hyprpaper.conf (Fondo de color sólido azul) ---"
cat <<EOT > "$HYPRPAPER_CONFIG_FILE"
# Configuración de Fondo de Pantalla
preload =
wallpaper = monitorname, 0x1A202C # Color sólido (Azul oscuro)
EOT

# --- 4. Instalando y Habilitando el Display Manager (SDDM) ---

echo "--- 4. Habilitando SDDM (Display Manager) para el login gráfico ---"
# SDDM es un Display Manager ligero que funciona bien con Wayland.
sudo systemctl enable sddm --now

# --- 5. Instrucciones Finales ---
echo ""
echo "======================================================="
echo "       ✅ Instalación y Configuración Completa ✅"
echo "======================================================="
echo ""
echo "¡Tu sistema Arch con Hyprland base ya está listo!"
echo ""
echo "PASO FINAL REQUERIDO:"
echo "Por favor, **REINICIA** tu máquina virtual (MV) para iniciar SDDM:"
echo "  reboot"
echo ""
echo "Después de reiniciar:"
echo "1. Selecciona 'Hyprland' en la pantalla de login de SDDM."
echo "2. Inicia sesión con tu usuario y contraseña."
echo ""
echo "Una vez dentro de Hyprland, prueba:"
echo "• Terminal (Kitty): Tecla **SUPER + ENTER**"
echo "• Launcher (Wofi): Tecla **SUPER + R**"
echo ""
