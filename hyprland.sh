#!/bin/bash
# ===================================================================================
# SCRIPT 2 de 2: Instalación de Hyprland (Método Definitivo en Dos Fases)
#
# CÓMO FUNCIONA:
# 1. Este script instala TODOS los paquetes necesarios de forma segura.
# 2. Luego, CREA un segundo script llamado 'configure_hyprland.sh' en tu home.
# 3. Te pedirá que reinicies.
# 4. Después de reiniciar, solo tendrás que ejecutar el segundo script.
# ===================================================================================
set -e

# --- FASE 1: INSTALACIÓN DE PAQUETES ---

echo "--- FASE 1 de 2: Preparando el sistema e instalando TODOS los paquetes ---"

# Limpia y optimiza los mirrors para evitar bloqueos en las descargas
sudo rm -f /var/lib/pacman/db.lck
sudo pacman -S --needed --noconfirm reflector
sudo reflector --verbose --country Mexico --country 'United States' -l 6 --sort rate --save /etc/pacman.d/mirrorlist
sudo pacman -Syyu --noconfirm

# Instala el entorno gráfico y todas las aplicaciones
echo "--> Instalando Hyprland y todos los componentes..."
sudo pacman -S --needed --noconfirm \
    hyprland mesa xorg-xwayland xdg-desktop-portal-hyprland \
    qt5-wayland qt6-wayland polkit-kde-agent \
    pipewire wireplumber pipewire-pulse pipewire-alsa \
    hyprpaper kitty wofi waybar sddm

echo "✔ Todos los paquetes han sido instalados correctamente."
echo ""

# --- FASE 2: CREACIÓN DEL SCRIPT DE CONFIGURACIÓN ---

echo "--- FASE 2 de 2: Creando el script de configuración para el siguiente reinicio ---"

# Usamos $SUDO_USER para asegurarnos de que el script se cree en TU home, no en el de root
cat <<'EOT' > /home/$SUDO_USER/configure_hyprland.sh
#!/bin/bash
# Este script se ejecuta DESPUÉS del primer reinicio para configurar Hyprland.
set -e

echo "--- Iniciando configuración de Hyprland ---"

HYPR_CONFIG_DIR="$HOME/.config/hypr"
HYPR_CONFIG_FILE="$HYPR_CONFIG_DIR/hyprland.conf"
HYPRPAPER_CONFIG_FILE="$HYPR_CONFIG_DIR/hyprpaper.conf"
MOD="SUPER"

mkdir -p "$HYPR_CONFIG_DIR"

echo "--> Creando archivos de configuración..."
cat <<'EOF' > "$HYPR_CONFIG_FILE"
# Configuración Base para Hyprland
\$mod = SUPER
env = GDK_BACKEND,wayland,x11
exec-once = hyprpaper &
exec-once = waybar &
exec-once = /usr/lib/polkit-kde-authentication-agent-1 &
input {
    kb_layout = latam
    follow_mouse = 1
    sensitivity = 0
}
bind = \$mod, RETURN, exec, kitty
bind = \$mod, R, exec, wofi --show drun
bind = \$mod, Q, killactive,
bind = \$mod, 1, workspace, 1
bind = \$mod, 2, workspace, 2
bind = \$mod SHIFT, 1, movetoworkspace, 1
bind = \$mod SHIFT, 2, movetoworkspace, 2
bind = \$mod, E, exec, hyprctl reload
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgb(88c0d0)
    col.inactive_border = rgb(4c566a)
    layout = dwindle
}
EOF

cat <<'EOF' > "$HYPRPAPER_CONFIG_FILE"
# Configuración de Fondo de Pantalla
preload =
wallpaper = monitorname, 0x1A202C
EOF

echo "--> Habilitando el inicio de sesión gráfico (SDDM)..."
sudo systemctl enable sddm

echo ""
echo "=============================================="
echo "    ✅ ¡Configuración finalizada!"
echo "=============================================="
echo ""
echo "Ahora reinicia una última vez para entrar a tu escritorio:"
echo "  reboot"
EOT

# Da permisos de ejecución al nuevo script
chmod +x /home/$SUDO_USER/configure_hyprland.sh

echo "✔ Se ha creado el script 'configure_hyprland.sh' en tu carpeta de inicio."
echo ""
echo "================================================================================"
echo "         PASO CRÍTICO: ¡AHORA DEBES REINICIAR!"
echo "================================================================================"
echo ""
echo "La instalación de paquetes ha terminado. Para continuar, reinicia el sistema:"
echo "  reboot"
echo ""
