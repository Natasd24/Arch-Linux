#!/bin/bash
set -e

echo "==================================================="
echo "   INSTALADOR CAELESTIA SHELL - EDICIÓN VIRTUALBOX"
echo "==================================================="

# --- 1. Optimización y Drivers de VirtualBox (CRÍTICO) ---
echo "--> 1. Optimizando espejos y actualizando..."
sudo pacman -S --needed --noconfirm reflector
sudo reflector --verbose --country Mexico --country 'United States' -l 6 --sort rate --save /etc/pacman.d/mirrorlist
sudo pacman -Syyu --noconfirm

echo "--> 2. Instalando Drivers de Video y Guest Utils..."
# 'mesa' es necesario para OpenGL en Hyprland
sudo pacman -S --needed --noconfirm virtualbox-guest-utils mesa
sudo systemctl enable --now vboxservice

# --- 2. Herramientas Base y AUR Helper (Paru BINARIO) ---
echo "--> 3. Instalando herramientas base..."
sudo pacman -S --needed --noconfirm base-devel git

echo "--> 4. Instalando Paru (Versión BINARIA para ahorrar RAM)..."
# Usamos paru-bin para que no compile rust y no reviente la memoria
if ! command -v paru &> /dev/null; then
    TEMP_DIR=$(mktemp -d)
    # NOTA: Clonamos paru-bin, no paru normal
    git clone https://aur.archlinux.org/paru-bin.git "$TEMP_DIR/paru"
    cd "$TEMP_DIR/paru"
    makepkg -si --noconfirm
    cd ~
    rm -rf "$TEMP_DIR"
else
    echo "Paru ya está instalado."
fi

# --- 3. Instalación MANUAL de Dependencias (Para evitar corrupción) ---
echo "--> 5. Instalando dependencias de Caelestia por separado..."
# Instalamos lo pesado antes para que el script de Caelestia solo configure
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
    xdg-desktop-portal-hyprland

# --- 4. Caelestia Shell ---
echo "--> 6. Clonando e instalando Caelestia Shell..."
if [ ! -d "$HOME/.local/share/caelestia" ]; then
    git clone https://github.com/caelestia-dots/caelestia.git ~/.local/share/caelestia
    
    echo "Ejecutando instalador de Caelestia..."
    # Ejecutamos el script. Como ya instalamos las dependencias arriba, 
    # esto debería ser rápido y sin errores.
    fish ~/.local/share/caelestia/install.fish --noconfirm
else
    echo "Caelestia ya estaba clonado. Saltando clonación."
fi

# --- 5. Aplicaciones Extra ---
echo "--> 7. Instalando aplicaciones finales..."
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

# --- 6. PARCHE FINAL PARA VIRTUALBOX (Anti-Pantalla Negra) ---
echo "--> 8. Aplicando parche para cursor en VirtualBox..."
# Esto crea un archivo que fuerza a Hyprland a funcionar en VM
mkdir -p ~/.config/hypr
echo "env = WLR_NO_HARDWARE_CURSORS,1" >> ~/.config/hypr/hyprland.conf

echo "==================================================="
echo "✅ INSTALACIÓN COMPLETADA."
echo "Reinicia y escribe 'Hyprland' para entrar."
echo "==================================================="
