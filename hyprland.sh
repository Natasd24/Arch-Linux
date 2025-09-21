#!/bin/bash
# Post-instalación mínima Arch Linux con Hyprland
# Ejecutar como usuario normal con sudo habilitado

set -e

USER=$(whoami)
WALLPAPER_URL="https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Ftse1.explicit.bing.net%2Fth%2Fid%2FOIP.LEK5piDAo2ioJ9O6dYFelAHaEG%3Fpid%3DApi&f=1&ipt=843daac58bda1bb027c83c30b9f13e45ebd76b57503fed241215a7a7793d6066&ipo=images"
WALLPAPER_PATH="$HOME/.config/hypr/wallpaper.png"

echo ">>> Actualizando sistema..."
sudo pacman -Syu --noconfirm

echo ">>> Instalando lo esencial para Hyprland..."
sudo pacman -S --noconfirm \
  hyprland \
  xdg-desktop-portal-hyprland \
  waybar \
  wofi \
  kitty \
  pipewire pipewire-pulse wireplumber \
  ttf-jetbrains-mono-nerd \
  polkit-gnome \
  network-manager-applet \
  xdg-user-dirs

echo ">>> Configurando sudo (wheel)..."
echo "%wheel ALL=(ALL) ALL" | sudo tee -a /etc/sudoers

echo ">>> Creando directorios de usuario..."
xdg-user-dirs-update

echo ">>> Configurando wallpaper..."
mkdir -p "$(dirname $WALLPAPER_PATH)"
wget -O "$WALLPAPER_PATH" "$WALLPAPER_URL"

echo ">>> Configurando Hyprland..."
mkdir -p ~/.config/hypr
cat > ~/.config/hypr/hyprland.conf <<EOL
monitor=,preferred,auto,1

exec-once = waybar &
exec-once = kitty &
exec-once = nm-applet &
exec-once = hyprctl hyprpaper preload $WALLPAPER_PATH
exec-once = hyprctl hyprpaper wallpaper ",$WALLPAPER_PATH"

input {
  kb_layout = la
}
EOL

echo ">>> Configurando Waybar..."
mkdir -p ~/.config/waybar
cat > ~/.config/waybar/config <<EOL
{
  "layer": "top",
  "position": "top",
  "modules-left": ["clock"],
  "modules-center": ["workspaces"],
  "modules-right": ["network", "pulseaudio"]
}
EOL
echo "{}" > ~/.config/waybar/style.css

echo ">>> Instalación mínima completa 🎉"
echo "Inicia sesión en TTY y ejecuta 'Hyprland' para arrancar el entorno gráfico."
