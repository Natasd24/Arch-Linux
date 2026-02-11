#!/bin/bash
set -e

# --- 1. Optimización de Mirrors ---
echo "--> Optimizando mirrors para máxima velocidad (México y EE. UU.)..."
sudo pacman -S --needed --noconfirm reflector
sudo reflector --verbose --country Mexico --country 'United States' -l 6 --sort rate --save /etc/pacman.d/mirrorlist
sudo pacman -Syyu --noconfirm

# --- 2. Herramientas Base y AUR Helper (Paru) ---
echo "--> Instalando base-devel y git..."
sudo pacman -S --needed --noconfirm base-devel git

echo "--> Instalando Paru..."
if ! command -v paru &> /dev/null; then
    # Usamos un directorio temporal para no ensuciar el home
    TEMP_DIR=$(mktemp -d)
    git clone https://aur.archlinux.org/paru.git "$TEMP_DIR/paru"
    cd "$TEMP_DIR/paru"
    makepkg -si --noconfirm
    cd ~
    rm -rf "$TEMP_DIR"
fi

# --- 3. Caelestia Shell ---
echo "--> Preparando instalación de Caelestia Shell..."
# Se requiere fish para ejecutar el instalador de Caelestia
sudo pacman -S --needed --noconfirm fish

if [ ! -d "$HOME/.local/share/caelestia" ]; then
    git clone https://github.com/caelestia-dots/caelestia.git ~/.local/share/caelestia
    # Ejecución del script de instalación oficial
    fish ~/.local/share/caelestia/install.fish
else
    echo "Caelestia ya está clonado en ~/.local/share/caelestia"
fi

# --- 4. Aplicaciones de Sistema y Utilidades ---
echo "--> Instalando aplicaciones finales..."
sudo pacman -S --needed --noconfirm \
    thunar \
    network-manager-applet \
    blueman \
    os-prober \
    grub \
    discord \
    gvfs \
    thunar-volman \
    p7zip

echo "---"
echo "✅ Proceso completado. Sistema Arch Linux configurado y limpio."
