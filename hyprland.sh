#!/bin/bash
set -e

echo "==================================================="
echo "   SETUP ARCH LINUX + CAELESTIA (VIRTUALBOX)     "
echo "==================================================="

# --- 1. Optimización y Drivers VBox (Fundamental) ---
echo "--> [1/6] Optimizando red y drivers de video..."
sudo pacman -S --needed --noconfirm reflector
sudo reflector --verbose --country Mexico --country 'United States' -l 6 --sort rate --save /etc/pacman.d/mirrorlist
sudo pacman -Syyu --noconfirm

# Drivers gráficos y utilidades de VBox
sudo pacman -S --needed --noconfirm virtualbox-guest-utils mesa
sudo systemctl enable --now vboxservice

# --- 2. Paru BINARIO (Para no explotar la RAM) ---
echo "--> [2/6] Instalando Paru-bin..."
sudo pacman -S --needed --noconfirm base-devel git

if ! command -v paru &> /dev/null; then
    TEMP_DIR=$(mktemp -d)
    # Clonamos la versión binaria pre-compilada
    git clone https://aur.archlinux.org/paru-bin.git "$TEMP_DIR/paru"
    cd "$TEMP_DIR/paru"
    makepkg -si --noconfirm
    cd ~
    rm -rf "$TEMP_DIR"
else
    echo "Paru ya instalado."
fi

# --- 3. Instalación MANUAL de Dependencias ---
# Esto es lo que pediste: instalamos nosotros para que Caelestia no lo haga mal.
echo "--> [3/6] Pre-instalando dependencias (Hyprland, Fish, Kitty...)..."
sudo pacman -S --needed --noconfirm \
    hyprland \
    fish \
    kitty \
    wofi \
    waybar \
    swww \
    dunst \
    starship \
    ttf-jetbrains-mono-nerd \
    noto-fonts-emoji \
    polkit-gnome \
    qt5-wayland \
    qt6-wayland \
    xdg-desktop-portal-hyprland \
    pavucontrol \
    imagemagick \
    jq

# --- 4. Clonar Caelestia ---
echo "--> [4/6] Descargando Caelestia Shell..."
# Borramos si existe para evitar conflictos
rm -rf ~/.local/share/caelestia
git clone https://github.com/caelestia-dots/caelestia.git ~/.local/share/caelestia

# --- 5. Ejecutar Instalador (Modo Configuración) ---
echo "--> [5/6] Aplicando configuración..."
# Aquí usamos tus flags. Como ya instalamos las deps arriba, esto será rápido.
# Usamos --noconfirm para que no pregunte y --aur-helper=paru explícitamente.
fish ~/.local/share/caelestia/install.fish --noconfirm --aur-helper=paru

# --- 6. Parches Finales para VirtualBox ---
echo "--> [6/6] Aplicando correcciones para VM..."
mkdir -p ~/.config/hypr

# Fix del cursor invisible y renderizado
echo "env = WLR_NO_HARDWARE_CURSORS,1" >> ~/.config/hypr/hyprland.conf
echo "env = WLR_RENDERER_ALLOW_SOFTWARE,1" >> ~/.config/hypr/hyprland.conf

# Aplicaciones útiles extra
sudo pacman -S --needed --noconfirm thunar network-manager-applet gvfs p7zip firefox

echo "==================================================="
echo "✅ TODO LISTO. Reinicia y escribe 'Hyprland'"
echo "==================================================="
