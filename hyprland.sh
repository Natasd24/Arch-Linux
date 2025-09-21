#!/bin/bash
# Script para instalar Hyprland + entorno mínimo en Arch Linux
# Incluye configuración básica (~/.config/hypr/hyprland.conf)

set -e

echo "=== Actualizando sistema ==="
sudo pacman -Syu --noconfirm

echo "=== Instalando Hyprland y portal ==="
sudo pacman -S --noconfirm hyprland xdg-desktop-portal-hyprland

echo "=== Instalando barra, lanzador y terminal ==="
sudo pacman -S --noconfirm waybar wofi kitty

echo "=== Instalando sonido (PipeWire + WirePlumber) ==="
sudo pacman -S --noconfirm pipewire pipewire-pulse pipewire-alsa wireplumber

echo "=== Instalando fuente JetBrains Mono Nerd ==="
sudo pacman -S --noconfirm ttf-jetbrains-mono-nerd

echo "=== Instalando Polkit (agente GNOME) ==="
sudo pacman -S --noconfirm polkit-gnome

echo "=== Instalando applet de red ==="
sudo pacman -S --noconfirm network-manager-applet networkmanager

echo "=== Instalando xdg-user-dirs ==="
sudo pacman -S --noconfirm xdg-user-dirs

echo "=== Habilitando servicios ==="
sudo systemctl enable --now NetworkManager.service
systemctl --user enable --now pipewire pipewire-pulse wireplumber

echo "=== Creando directorios de usuario ==="
xdg-user-dirs-update

echo "=== Creando configuración mínima de Hyprland ==="
mkdir -p ~/.config/hypr

cat > ~/.config/hypr/hyprland.conf << 'EOF'
# ~/.config/hypr/hyprland.conf
# Configuración mínima para iniciar con atajos básicos

monitor=,preferred,auto,auto

# Tecla Mod (SUPER / Windows)
$mod = SUPER

# Abrir terminal (Kitty)
bind = $mod, Return, exec, kitty

# Lanzador de aplicaciones (Wofi)
bind = $mod, D, exec, wofi --show drun

# Cerrar ventana activa
bind = $mod, Q, killactive

# Mover foco entre ventanas
bind = $mod, H, movefocus, l
bind = $mod, L, movefocus, r
bind = $mod, K, movefocus, u
bind = $mod, J, movefocus, d

# Salir de Hyprland
bind = $mod SHIFT, E, exit

# Lanzar servicios gráficos
exec-once = waybar &
exec-once = nm-applet &
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
EOF

echo "=== Instalación y configuración completadas con éxito 🎉 ==="
echo "👉 Reinicia tu sesión gráfica y selecciona Hyprland."
echo "   Atajos básicos:"
echo "   - Super+Enter: Abrir Kitty"
echo "   - Super+D: Abrir Wofi"
echo "   - Super+Q: Cerrar ventana"
echo "   - Super+Shift+E: Salir de Hyprland"
