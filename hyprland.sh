# Crear directorios
mkdir -p "$HOME/.config/hypr"

# Crear el archivo de configuración de Hyprland
# (Copia todo desde cat hasta EOT y pégalo)
cat <<EOT > "$HOME/.config/hypr/hyprland.conf"
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
EOT

# Crear el archivo de configuración del fondo de pantalla
# (Copia todo desde cat hasta EOT y pégalo)
cat <<EOT > "$HOME/.config/hypr/hyprpaper.conf"
# Configuración de Fondo de Pantalla
preload =
wallpaper = monitorname, 0x1A202C 
EOT

# Habilitar el inicio de sesión gráfico
sudo systemctl enable sddm

# Y finalmente, reiniciar
reboot
