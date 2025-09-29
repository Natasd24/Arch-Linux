#!/bin/bash
# Script de Post-Instalación para un entorno Hyprland básico

set -e

echo ">>> Actualizando el sistema..."
sudo pacman -Syu --noconfirm

echo ">>> Instalando paquetes de Hyprland y entorno gráfico básico..."
# Hyprland: Compositor Wayland
# Wayland-utils: Utilidades Wayland
# Xorg-xwayland: Capa de compatibilidad para aplicaciones X11
# Mesa: Drivers de gráficos (fundamental para 3D/Wayland)
# Ttf-fira-code: Una fuente popular
# Alacritty: Terminal ligero
# Sddm: Display manager (Gestor de inicio de sesión)
# Polkit-kde-agent: Agente de autenticación
# Wofi: Lanzador de aplicaciones
sudo pacman -S --noconfirm hyprland wayland-utils xorg-xwayland mesa ttf-fira-code \
alacritty sddm polkit-kde-agent wofi

echo ">>> Creando directorios XDG (si no existen)..."
xdg-user-dirs-update

echo ">>> Activando el gestor de inicio de sesión SDDM..."
sudo systemctl enable sddm

echo ">>> ⚠️ Configuración de Hyprland (Mínima) ⚠️"
# Copia una configuración mínima para poder iniciar el compositor.
# El usuario deberá personalizar esto después.
mkdir -p ~/.config/hypr
cat <<EOT > ~/.config/hypr/hyprland.conf
# Configuración Mínima de Hyprland
#
# Monitores
monitor=,preferred,auto,1

# Ejecutar servicios al inicio
exec-once = waybar & # Barra de estado
exec-once = polkit-kde-authentication-agent-1 # Agente de autenticación

# Reglas de ventana
windowrulev = float, wofi
windowrulev = float, Alacritty

# Binds (Atajos de teclado)
bind = $mainMod, Q, exec, alacritty # Abrir terminal
bind = $mainMod, P, exec, wofi --show drun # Lanzador de aplicaciones
bind = $mainMod, M, exit # Cerrar Hyprland

# Variables
\$mainMod = SUPER # Tecla Windows
EOT

echo ">>> Instalación de Hyprland base completada."
echo ">>> Ahora **reinicia** para ver el gestor de inicio de sesión (SDDM)."
echo ">>> sudo reboot"
