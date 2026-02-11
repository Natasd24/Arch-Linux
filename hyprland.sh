#!/bin/bash
set -e

# --- 1. Optimización de Mirrors y Sistema ---
echo "--> Optimizando mirrors para México y EE. UU..."
sudo pacman -S --needed --noconfirm reflector
sudo reflector --verbose --country Mexico --country 'United States' -l 6 --sort rate --save /etc/pacman.d/mirrorlist

echo "--> Actualizando el sistema..."
sudo pacman -Syyu --noconfirm

# --- 2. Paru (AUR Helper) ---
echo "--> Instalando dependencias de compilación y Paru..."
sudo pacman -S --needed --noconfirm base-devel git

# Compilación de paru
if ! command -v paru &> /dev/null; then
    TEMP_DIR=$(mktemp -d)
    git clone https://aur.archlinux.org/paru.git "$TEMP_DIR/paru"
    cd "$TEMP_DIR/paru"
    makepkg -si --noconfirm
    cd ~
    rm -rf "$TEMP_DIR"
fi

# --- 3. Caelestia Shell ---
echo "--> Instalando Caelestia Shell..."
# Necesitamos fish para correr su instalador
sudo pacman -S --needed --noconfirm fish

if [ ! -d "$HOME/.local/share/caelestia" ]; then
    git clone https://github.com/caelestia-dots/caelestia.git ~/.local/share/caelestia
    # Ejecutamos con --noconfirm como vimos que funcionaba mejor
    fish ~/.local/share/caelestia/install.fish --noconfirm
else
    echo "Caelestia ya está descargado. Omitiendo clonación."
fi

# --- 4. Aplicaciones Extra y Gaming ---
echo "--> Instalando herramientas de sistema, Discord y Meta-Gaming..."
sudo pacman -S --needed --noconfirm \
    thunar \
    network-manager-applet \
    blueman \
    os-prober \
    grub \
    discord \
    gvfs \
    thunar-volman \
    p7zip \
    cachyos-gaming-meta

echo ""
echo "===================================================="
echo "   ✅ ¡Optimización y Setup completado, Natas!     "
echo "===================================================="
