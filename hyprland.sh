#!/bin/bash

# --- Script de Instalación de Hyprland (Post-Instalación de Arch Base) ---
# Este script solo instala el entorno gráfico y las aplicaciones básicas,
# ya que tu script de instalación base ya manejó VirtualBox Guest Additions,
# NetworkManager y GIT.

# --- 0. Variables y Comprobaciones ---
HYPR_CONFIG_DIR="$HOME/.config/hypr"
HYPR_CONFIG_FILE="$HYPR_CONFIG_DIR/hyprland.conf"

echo "--- 1. Actualizando el sistema antes de instalar Hyprland ---"
sudo pacman -Syu --noconfirm

# --- 2. Instalación de Hyprland y Dependencias Esenciales ---
# Paquetes clave:
# - hyprland: El compositor Wayland.
# - mesa: Driver gráfico genérico, esencial para Wayland en VirtualBox.
# - xorg-xwayland: Soporte para aplicaciones X11 legacy.
# - xdg-desktop-portal-hyprland: Para compartir pantalla y otras integraciones.
# - qt5-wayland, qt6-wayland: Para que las aplicaciones QT funcionen en Wayland.
# - polkit-kde-agent: Agente de Polkit para manejar solicitudes de permisos (sudo gráfico).
# - kitty, wofi, waybar: Terminal, lanzador y barra de estado.

echo "--- 2. Instalando Hyprland, drivers Mesa y dependencias de ecosistema ---"
sudo pacman -S --noconfirm \
    hyprland \
    mesa \
    xorg-xwayland \
    xdg-desktop-portal-hyprland \
    qt5-wayland qt6-wayland \
    polkit-kde-agent \
    kitty wofi waybar

# --- 3. Configuración del Teclado Latino (la-latin1) y Entorno ---

echo "--- 3. Creando directorio y configuración de Hyprland ---"
mkdir -p "$HYPR_CONFIG_DIR"

# Intentar copiar la configuración de ejemplo del sistema (si existe)
if [ -f "/usr/share/hyprland/hyprland.conf" ]; then
    cp /usr/share/hyprland/hyprland.conf "$HYPR_CONFIG_FILE"
    echo "✔ Configuración de ejemplo copiada a $HYPR_CONFIG_FILE."
else
    echo "Advertencia: No se encontró la configuración de ejemplo del sistema."
    touch "$HYPR_CONFIG_FILE"
fi

# **AÑADIR CONFIGURACIÓN ESPECÍFICA DEL TECLADO LATINO ('latam')**
echo "--- 4. Aplicando configuración del teclado latino ('latam') ---"
# Se usa 'latam' que es el código XKB para el teclado latinoamericano.
# Sed se usa para buscar la sección 'input' y reemplazar o añadir la línea del layout.
if grep -q "input {" "$HYPR_CONFIG_FILE"; then
    # Si la sección 'input' existe, añadir o reemplazar kb_layout
    sed -i '/^input {/a \ \ kb_layout = latam' "$HYPR_CONFIG_FILE"
    sed -i 's/kb_layout = .*/kb_layout = latam/' "$HYPR_CONFIG_FILE"
else
    # Si la sección no existe (por ejemplo, archivo vacío), la añadimos al final.
    cat <<EOT >> "$HYPR_CONFIG_FILE"

# Configuración de entrada para teclado latino (latam)
input {
    kb_layout = latam
}
EOT
fi

echo "--- 5. Instalación Completa ---"
echo ""
echo "======================================================="
echo "        🎉 Hyprland y dependencias instaladas 🎉"
echo "======================================================="
echo ""
echo "PRÓXIMOS PASOS IMPORTANTES:"
echo "1. TECLADO LATINO: Se ha configurado 'kb_layout = latam' en $HYPR_CONFIG_FILE."
echo "2. INICIO DE HYPRLAND:"
echo "   Opción A (Recomendada): Instala un Display Manager (DM) como SDDM:"
echo "      sudo pacman -S sddm"
echo "      sudo systemctl enable sddm --now"
echo "      # Luego, **REINICIA** la MV para ir a la pantalla de login."
echo ""
echo "   Opción B (Manual): Inicia sesión en el TTY y ejecuta:"
echo "      exec Hyprland"
echo ""
echo "¡Reinicia tu máquina virtual para un entorno limpio y usar SDDM!"

