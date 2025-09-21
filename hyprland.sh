#!/bin/bash
# Post-instalación Arch Linux con Hyprland + utilidades modernas (México)
# Ejecutar como usuario normal con sudo habilitado

set -e

USER=$(whoami)
WALLPAPER_URL="https://raw.githubusercontent.com/hyprwm/Hyprland/main/assets/wall.png"
WALLPAPER_PATH="$HOME/.config/hypr/wallpaper.png"

echo ">>> Actualizando sistema..."
sudo pacman -Syu --noconfirm

echo ">>> Instalando paquetes base para Hyprland..."
sudo pacman -S --noconfirm \
  hyprland \
  xdg-desktop-portal-hyprland \
  waybar \
  eww-wayland \
  wofi \
  kitty \
  zsh \
  zsh-syntax-highlighting \
  zsh-autosuggestions \
  bat \
  lsd \
  neovim \
  git \
  wget \
  unzip \
  base-devel \
  pipewire pipewire-pulse wireplumber \
  grim slurp wl-clipboard \
  ttf-jetbrains-mono-nerd \
  polkit-gnome \
  network-manager-applet

echo ">>> Configurando wallpaper..."
mkdir -p "$(dirname $WALLPAPER_PATH)"
wget -O "$WALLPAPER_PATH" "$WALLPAPER_URL"

echo ">>> Configurando Hyprland..."
mkdir -p ~/.config/hypr
cat > ~/.config/hypr/hyprland.conf <<EOL
monitor=,preferred,auto,1

exec-once = waybar &
exec-once = eww daemon &
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

echo ">>> Configurando Zsh con Powerlevel10k..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $HOME/.powerlevel10k
echo 'source $HOME/.powerlevel10k/powerlevel10k.zsh-theme' >> ~/.zshrc
echo 'eval "$(zoxide init zsh)"' >> ~/.zshrc
echo 'alias cat="bat"' >> ~/.zshrc
echo 'alias ls="lsd"' >> ~/.zshrc
echo 'export EDITOR=nvim' >> ~/.zshrc
chsh -s /bin/zsh $USER

echo ">>> Instalando NeoVim + NvChad..."
git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1

echo ">>> Instalación completa 🎉"
echo "Reinicia la sesión gráfica con Hyprland (ejecuta 'Hyprland' en TTY tras login)."

