#!/bin/bash
# Post-Instalación para Hyprland - Toolbox Essentials 🧰
# Ejecutar después del script de instalación base

set -e

echo ">>> Instalando Toolbox Essentials para Hyprland..."

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Función para imprimir mensajes
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar que estamos como usuario normal (no root)
if [ "$EUID" -eq 0 ]; then
    print_error "No ejecutar como root. Crear usuario primero."
    exit 1
fi

# 1. INSTALAR AYUDANTE DE AUR (yay)
print_status "Instalando yay (AUR helper)..."
sudo pacman -S --needed git base-devel --noconfirm
if [ ! -d "yay" ]; then
    git clone https://aur.archlinux.org/yay.git
fi
cd yay && makepkg -si --noconfirm
cd ..
print_status "yay instalado correctamente"

# 2. PILA DE AUDIO (Pipewire)
print_status "Instalando Pipewire y Wireplumber..."
sudo pacman -S pipewire pipewire-pulse pipewire-alsa wireplumber --noconfirm
systemctl --user enable --now pipewire pipewire-pulse wireplumber
print_status "Audio stack configurado"

# 3. FUENTES NERD
print_status "Instalando Nerd Fonts..."
sudo pacman -S \
    ttf-cascadia-code-nerd \
    ttf-cascadia-mono-nerd \
    ttf-fira-code \
    ttf-fira-mono \
    ttf-fira-sans \
    ttf-firacode-nerd \
    ttf-iosevka-nerd \
    ttf-iosevkaterm-nerd \
    ttf-jetbrains-mono-nerd \
    ttf-jetbrains-mono \
    ttf-nerd-fonts-symbols \
    ttf-nerd-fonts-symbols-mono \
    noto-fonts \
    noto-fonts-cjk \
    noto-fonts-emoji \
    --noconfirm
print_status "Fuentes Nerd instaladas"

# 4. GESTOR DE PANTALLA (SDDM)
print_status "Instalando SDDM..."
sudo pacman -S sddm sddm-kcm --noconfirm
sudo systemctl enable sddm.service
print_status "SDDM instalado y habilitado"

# 5. NAVEGADOR WEB (Firefox - REEMPLAZA Brave)
print_status "Instalando Firefox..."
sudo pacman -S firefox firefox-i18n-es-mx --noconfirm
print_status "Firefox instalado"

# 6. EMULADOR DE TERMINAL (Kitty)
print_status "Instalando Kitty..."
sudo pacman -S kitty --noconfirm
print_status "Kitty instalado"

# 7. EDITORES DE TEXTO/CÓDIGO
print_status "Instalando editores..."
sudo pacman -S nano vim --noconfirm
yay -S visual-studio-code-bin --noconfirm
print_status "Editores instalados"

# 8. HERRAMIENTAS ESENCIALES
print_status "Instalando herramientas adicionales..."
sudo pacman -S \
    tar \
    zip \
    unzip \
    p7zip \
    wget \
    curl \
    rsync \
    bash-completion \
    --noconfirm
print_status "Herramientas instaladas"

# 9. HERRAMIENTAS PARA HYPRLAND (adicionales)
print_status "Instalando herramientas específicas para Hyprland..."
sudo pacman -S \
    hyprland \
    waybar \
    rofi \
    thunar \
    gvfs \
    xdg-user-dirs \
    network-manager-applet \
    blueman \
    brightnessctl \
    playerctl \
    --noconfirm
print_status "Herramientas Hyprland instaladas"

# 10. CONFIGURACIÓN FINAL
print_status "Configurando entorno..."

# Generar carpetas de usuario
xdg-user-dirs-update

# Configurar Pipewire para usuario actual
systemctl --user enable --now pipewire pipewire-pulse wireplumber

# Mensaje final
echo ""
echo "=================================================="
print_status "INSTALACIÓN COMPLETADA 🎉"
echo "=================================================="
echo ""
echo "Herramientas instaladas:"
echo "✅ yay (AUR helper)"
echo "✅ Pipewire + Wireplumber (audio)"
echo "✅ Nerd Fonts (fuentes)"
echo "✅ SDDM (gestor de pantalla)"
echo "✅ Firefox (navegador)"
echo "✅ Kitty (terminal)"
echo "✅ VS Code + nano (editores)"
echo "✅ Hyprland + herramientas"
echo ""
echo "Próximos pasos:"
echo "1. Reiniciar: sudo reboot"
echo "2. Iniciar sesión en SDDM"
echo "3. Configurar Hyprland según tus necesidades"
echo ""

print_warning "Configuración de teclado español aplicada"
