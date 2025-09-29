#!/bin/bash

# --- Script de Instalación de Hyprland para VirtualBox (Base Arch Linux) ---
# Ejecutar este script asume que tienes una instalación base de Arch y un usuario
# no-root con permisos sudo.

# --- 0. Variables y Comprobaciones ---
HYPR_CONFIG_DIR="$HOME/.config/hypr"
HYPR_CONFIG_FILE="$HYPR_CONFIG_DIR/hyprland.conf"

echo "--- 1. Actualizando el sistema ---"
sudo pacman -Syu --noconfirm

# --- 2. Instalación de Hyprland y Dependencias Esenciales ---
# Se instala:
# - hyprland: El compositor Wayland.
# - mesa: Driver gráfico genérico, esencial para Wayland en VirtualBox (virgl/vbox).
# - xorg-xwayland: Necesario para que funcionen las aplicaciones X11 legacy.
# - xdg-desktop-portal-hyprland: Para compartir pantalla y otras integraciones.
# - qt5-wayland, qt6-wayland: Para que las aplicaciones QT funcionen en Wayland.
# - polkit-kde-agent: Un agente de Polkit para manejar solicitudes de permisos (sudo gráfico).
# - kitty: Un terminal moderno compatible con Wayland.
# - wofi: Un lanzador de aplicaciones simple.
# - waybar: Una barra de estado Wayland.

echo "--- 2. Instalando Hyprland, drivers Mesa y dependencias básicas ---"
sudo pacman -S --noconfirm \
    hyprland \
    mesa \
    xorg-xwayland \
    xdg-desktop-portal-hyprland \
    qt5-wayland qt6-wayland \
    polkit-kde-agent \
    networkmanager \
    kitty wofi waybar \
    git wget

# --- 3. Configuración del Entorno Básico ---

# Habilitar NetworkManager para la conectividad de red
echo "--- 3. Habilitando NetworkManager ---"
sudo systemctl enable --now NetworkManager

# Crear el directorio de configuración
echo "--- 4. Configurando Hyprland de ejemplo ---"
mkdir -p "$HYPR_CONFIG_DIR"

# Copiar la configuración de ejemplo del sistema si existe
if [ -f "/usr/share/hyprland/hyprland.conf" ]; then
    cp /usr/share/hyprland/hyprland.conf "$HYPR_CONFIG_FILE"
    echo "✔ Configuración de ejemplo copiada a $HYPR_CONFIG_FILE."
else
    echo "Advertencia: No se encontró la configuración de ejemplo del sistema."
    echo "Se recomienda obtenerla del repositorio oficial de Hyprland."
fi

# --- 4. Instalación de VirtualBox Guest Additions (Opcional, pero vital) ---
echo "--- 5. Instalando VirtualBox Guest Additions ---"
# Esto mejorará el rendimiento, la resolución y la integración.
sudo pacman -S --noconfirm virtualbox-guest-utils
sudo systemctl enable --now vboxservice

# --- 5. Instrucciones Finales ---
echo ""
echo "======================================================="
echo "        🎉 Instalación de Hyprland en VirtualBox Completa 🎉"
echo "======================================================="
echo ""
echo "PASOS IMPORTANTES A SEGUIR:"
echo ""
echo "1. CONFIGURACIÓN:"
echo "   El archivo base de configuración está en: $HYPR_CONFIG_FILE"
echo "   Edítalo para cambiar atajos de teclado, apariencia, etc."
echo ""
echo "2. INICIAR HYPRLAND:"
echo "   A) Opción Recomendada: Instalar un Display Manager (DM), como SDDM:"
echo "      sudo pacman -S sddm"
echo "      sudo systemctl enable sddm"
echo "      # Luego, REINICIA la MV y selecciona 'Hyprland' en la pantalla de inicio de sesión."
echo ""
echo "   B) Opción Manual (desde TTY):"
echo "      # Cierra la sesión y vuelve a iniciar en el TTY (Ctrl+Alt+F3 o similar)."
echo "      # Ejecuta: Hyprland"
echo ""
echo "   ¡Recuerda **REINICIAR** la máquina virtual para que todos los servicios arranquen correctamente!"

