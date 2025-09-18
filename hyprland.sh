#!/bin/bash
set -e

# ==========================
# 1. Actualizar sistema
# ==========================
sudo pacman -Syu --noconfirm

# ==========================
# 2. Instalar Hyprland y utilidades
# ==========================
sudo pacman -S --noconfirm \
    hyprland kitty wofi eww swaybg wl-clipboard \
    seatd polkit greetd greetd-tuigreet pipewire wireplumber pipewire-audio \
    noto-fonts

# ==========================
# 3. Configurar greetd
# ==========================
sudo mkdir -p /etc/greetd
cat <<GREET | sudo tee /etc/greetd/config.toml
[terminal]
vt = 1

[default_session]
command = "tuigreet --cmd Hyprland"
user = "greeter"
GREET

sudo systemctl enable greetd

echo "✅ Instalación de Hyprland y utilidades completada."
echo "👉 Reinicia para iniciar sesión en Hyprland."
