#!/bin/bash
# Script para instalar Hyprland + entorno mínimo en Arch Linux
# Versión combinada: servicios habilitados + configuración básica + barra + wallpaper + VirtualBox (linux-zen compatible)

set -e

echo "=== Actualizando sistema ==="
sudo pacman -Syu --noconfirm

echo "=== Instalando Hyprland y portal ==="
sudo pacman -S --noconfirm hyprland xdg-desktop-portal-hyprland

echo "=== Instalando barra, lanzador y terminal ==="
sudo pacman -S --noconfirm waybar wofi kitty

echo "=== Instalando sonido (PipeWire + WirePlumber) ==="
sudo pacman -S --noconfirm pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber

echo "=== Instalando fuente JetBrains Mono Nerd ==="
sudo pacman -S --noconfirm ttf-jetbrains-mono-nerd

echo "=== Instalando Polkit (agente GNOME) ==="
sudo pacman -S --noconfirm polkit-gnome

echo "=== Instalando applet de red ==="
sudo pacman -S --noconfirm network-manager-applet networkmanager

echo "=== Instalando xdg-user-dirs y feh (wallpapers) ==="
sudo pacman -S --noconfirm xdg-user-dirs feh

echo "=== Instalando VirtualBox Guest Additions (modo DKMS para linux-zen) ==="
sudo pacman -S --noconfirm virtualbox-guest-utils virtualbox-guest-dkms linux-headers

echo "=== Habilitando servicios ==="
sudo systemctl enable --now NetworkManager.service
systemctl --user enable --now pipewire pipewire-pulse wireplumber
sudo systemctl enable --now vboxservice.service

echo "=== Creando directorios de usuario ==="
xdg-user-dirs-update

echo "=== Creando configuración mínima de Hyprland ==="
mkdir -p ~/.config/hypr

cat > ~/.config/hypr/hyprland.conf << 'EOF'
# ~/.config/hypr/hyprland.conf
# Configuración combinada con atajos básicos + barra + wallpaper

monitor=,preferred,auto,auto

# Tecla Mod (SUPER / Windows)
$mod = SUPER

# Atajos básicos
bind = $mod, Return, exec, kitty
bind = $mod, D, exec, wofi --show drun
bind = $mod, Q, killactive

# Mover foco entre ventanas (hjkl estilo vim)
bind = $mod, H, movefocus, l
bind = $mod, L, movefocus, r
bind = $mod, K, movefocus, u
bind = $mod, J, movefocus, d

# Salir de Hyprland
bind = $mod SHIFT, E, exit

# Recargar configuración
bind = $mod, R, exec, hyprctl reload

# Lanzar servicios gráficos
exec-once = waybar &
exec-once = nm-applet &
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
exec-once = feh --bg-fill ~/Pictures/wallpaper.jpg
EOF

echo "=== Configuración de Waybar ==="
mkdir -p ~/.config/waybar
cat > ~/.config/waybar/config.jsonc << 'EOF'
{
  "layer": "top",
  "position": "top",
  "modules-left": ["clock"],
  "modules-center": ["network"],
  "modules-right": ["pulseaudio", "tray"]
}
EOF

cat > ~/.config/waybar/style.css << 'EOF'
* {
  font-family: "JetBrainsMono Nerd Font";
  font-size: 12px;
}
EOF

echo "=== Configurando wallpaper de ejemplo ==="
mkdir -p ~/Pictures
curl -L https://wallpapercave.com/wp/wp5121916.jpg -o ~/Pictures/wallpaper.jpg

echo "=== Instalación y configuración completadas con éxito 🎉 ==="
echo "👉 Reinicia tu sesión gráfica y selecciona Hyprland."
echo "   Atajos básicos:"
echo "   - Super+Enter: Abrir Kitty"
echo "   - Super+D: Abrir Wofi"
echo "   - Super+Q: Cerrar ventana"
echo "   - Super+Shift+E: Salir de Hyprland"
echo "   - Super+R: Recargar configuración"
echo ""
echo "=== VirtualBox Guest Additions habilitadas ✅ ==="
echo "👉 Módulos DKMS instalados, funcionando con linux-zen."
