#!/bin/bash
set -e

# =======================================
# 1. Actualización y dependencias
# =======================================
sudo pacman -Syu --noconfirm

sudo pacman -S --noconfirm \
    hyprland xorg-xwayland xdg-desktop-portal-hyprland \
    waybar eww wofi kitty \
    neofetch zsh git base-devel \
    pipewire pipewire-pulse wireplumber seatd \
    ttf-dejavu ttf-jetbrains-mono bat lsd curl wget unzip \
    neovim

# =======================================
# 2. Crear directorios comunes de usuario
# =======================================
xdg-user-dirs-update

# =======================================
# 3. Shell Zsh + Powerlevel10k
# =======================================
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
chsh -s $(which zsh)

# =======================================
# 4. Neovim + NeoChad
# =======================================
git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1
nvim +PackerSync +qa || true

# =======================================
# 5. Barra de estado Eww
# =======================================
git clone https://github.com/elkowar/eww.git ~/eww
cd ~/eww
cargo build --release || true
mkdir -p ~/.config/eww
cat <<EOT > ~/.config/eww/bar
(defwidget bar []
  :orientation :horizontal
  :space-evenly true
  :children [
    (label :text (system "neofetch --stdout | head -n 1"))
  ]
)
EOT

# =======================================
# 6. Configuración mínima Hyprland
# =======================================
mkdir -p ~/.config/hypr
cat <<EOT > ~/.config/hypr/hyprland.conf
# General
monitor=default
dpi=96

# Terminal
bind=SUPER+Return, exec kitty

# Lanzador
bind=SUPER+d, exec wofi --show drun

# Barra de estado
exec_always=eww open bar

# Atajos básicos
bind=SUPER+q, killactive
EOT

# =======================================
# 7. Configuración Wofi
# =======================================
mkdir -p ~/.config/wofi
cat <<EOT > ~/.config/wofi/config
[settings]
mode = drun
EOT

# =======================================
# 8. Inicio automático Hyprland en tty1
# =======================================
cat <<'EOT' >> ~/.zprofile
if [[ -z $DISPLAY ]] && [[ $(tty) == /dev/tty1 ]]; then
    exec Hyprland
fi
EOT

echo "✅ Entorno Hyprland configurado. Reinicia y entra directamente al escritorio."

