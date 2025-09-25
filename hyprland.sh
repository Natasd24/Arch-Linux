#!/bin/bash
# Instalación completa de Hyprland con todos los componentes

set -e

echo "=== Instalando Hyprland y componentes esenciales ==="
sudo pacman -S --noconfirm hyprland xdg-desktop-portal-hyprland waybar wofi kitty

echo "=== Instalando pipewire para sonido ==="
sudo pacman -S --noconfirm pipewire pipewire-pulse wireplumber pipewire-audio

echo "=== Instalando componentes de sistema ==="
sudo pacman -S --noconfirm polkit-gnome network-manager-applet

echo "=== Instalando xdg-user-dirs y feh (wallpapers) ==="
sudo pacman -S --noconfirm xdg-user-dirs feh

echo "=== Instalando VirtualBox Guest Additions ==="
sudo pacman -S --noconfirm virtualbox-guest-utils

echo "=== Instalando fuentes Nerd Fonts ==="
sudo pacman -S --noconfirm ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji

echo "=== Instalando utilidades adicionales ==="
sudo pacman -S --noconfirm thunar grim slurp wl-clipboard swww

echo "=== Habilitando servicios ==="
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now vboxservice

echo "=== Configurando servicios de usuario (pipewire) ==="
systemctl --user enable --now pipewire pipewire-pulse wireplumber

echo "=== Creando directorios de usuario ==="
xdg-user-dirs-update

echo "=== Creando estructura de configuración ==="
mkdir -p ~/.config/hypr
mkdir -p ~/.config/waybar
mkdir -p ~/.config/wofi

echo "=== Configurando Hyprland ==="
cat > ~/.config/hypr/hyprland.conf << 'EOF'
# Configuración de Hyprland
monitor=,preferred,auto,auto

exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = waybar &
exec-once = swww init &
exec-once = ~/.config/hypr/set-wallpaper.sh &
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
exec-once = nm-applet --indicator &

input {
    kb_layout = la-latin1
    follow_mouse = 1
    touchpad {
        natural_scroll = false
    }
}

general {
    gaps_in = 5
    gaps_out = 20
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
    layout = dwindle
    cursor_inactive_timeout = 0
}

decoration {
    rounding = 10
    
    blur {
        enabled = true
        size = 3
        passes = 1
    }
    
    drop_shadow = yes
    shadow_range = 4
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
}

animations {
    enabled = yes
    
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    
    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

dwindle {
    pseudotile = yes
    preserve_split = yes
}

master {
    new_is_master = true
}

gestures {
    workspace_swipe = false
}

# Atajos de teclado
bind = SUPER, Q, exec, kitty
bind = SUPER, C, killactive
bind = SUPER, M, exit
bind = SUPER, E, exec, thunar
bind = SUPER, V, togglefloating
bind = SUPER, R, exec, wofi --show drun
bind = SUPER, P, exec, grim -g "$(slurp)" - | wl-copy

# Cambiar workspace
bind = SUPER, 1, workspace, 1
bind = SUPER, 2, workspace, 2
bind = SUPER, 3, workspace, 3
bind = SUPER, 4, workspace, 4
bind = SUPER, 5, workspace, 5

# Mover ventana al workspace
bind = SUPER SHIFT, 1, movetoworkspace, 1
bind = SUPER SHIFT, 2, movetoworkspace, 2
bind = SUPER SHIFT, 3, movetoworkspace, 3
bind = SUPER SHIFT, 4, movetoworkspace, 4
bind = SUPER SHIFT, 5, movetoworkspace, 5

# Control de audio
bind = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
bind = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

# Pantalla completa
bind = SUPER, F, fullscreen
EOF

echo "=== Configurando Waybar ==="
cat > ~/.config/waybar/config << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 35,
    "spacing": 4,
    
    "modules-left": ["hyprland/workspaces"],
    "modules-center": ["clock"],
    "modules-right": ["cpu", "memory", "battery", "pulseaudio", "network", "tray"],
    
    "hyprland/workspaces": {
        "disable-scroll": true,
        "all-outputs": true,
        "format": "{icon}",
        "format-icons": {
            "1": "",
            "2": "",
            "3": "",
            "4": "",
            "5": ""
        }
    },
    
    "clock": {
        "format": " {:%H:%M}",
        "format-alt": " {:%d/%m/%Y}",
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>"
    },
    
    "cpu": {
        "format": " {usage}%",
        "tooltip": false
    },
    
    "memory": {
        "format": " {}%",
        "tooltip": false
    },
    
    "battery": {
        "format": "{icon} {capacity}%",
        "format-icons": ["", "", "", "", ""],
        "tooltip": false
    },
    
    "pulseaudio": {
        "format": "{icon} {volume}%",
        "format-muted": " Muted",
        "format-icons": ["", "", ""],
        "on-click": "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
        "tooltip": false
    },
    
    "network": {
        "format-wifi": " {signalStrength}%",
        "format-ethernet": " Connected",
        "format-disconnected": " Disconnected",
        "tooltip": false
    },
    
    "tray": {
        "spacing": 10
    }
}
EOF

cat > ~/.config/waybar/style.css << 'EOF'
* {
    border: none;
    border-radius: 0;
    font-family: "JetBrainsMono Nerd Font";
    font-weight: bold;
    font-size: 14px;
    min-height: 0;
}

window#waybar {
    background: rgba(21, 18, 27, 0.8);
    color: #cdd6f4;
}

#workspaces button {
    padding: 0 8px;
    background: transparent;
    color: #cdd6f4;
    border: 2px solid transparent;
    border-radius: 8px;
}

#workspaces button.active {
    background: linear-gradient(45deg, #cba6f7, #f5c2e7);
    color: #1e1e2e;
}

#clock, #cpu, #memory, #battery, #pulseaudio, #network {
    padding: 0 10px;
    margin: 0 3px;
    background: rgba(127, 132, 156, 0.2);
    border-radius: 8px;
}
EOF

echo "=== Configurando Kitty ==="
mkdir -p ~/.config/kitty
cat > ~/.config/kitty/kitty.conf << 'EOF'
font_family JetBrainsMono Nerd Font
font_size 12.0

background #1e1e2e
foreground #cdd6f4

selection_background #585b70
selection_foreground #cdd6f4

cursor #f5e0dc
cursor_text_color #11111b

url_color #89b4fa

active_border_color #b4befe
inactive_border_color #585b70

wayland_titlebar_color background

confirm_os_window_close 0
EOF


echo "=== Configurando Wofi ==="
cat > ~/.config/wofi/style.css << 'EOF'
window {
    margin: 0px;
    border: 2px solid #b4befe;
    background-color: #1e1e2e;
    border-radius: 10px;
}

#input {
    margin: 5px;
    border: none;
    color: #cdd6f4;
    background-color: #313244;
    border-radius: 5px;
}

#inner-box {
    margin: 5px;
    border: none;
    background-color: #1e1e2e;
}

#outer-box {
    margin: 5px;
    border: none;
    background-color: #1e1e2e;
}

#scroll {
    margin: 0px;
    border: none;
}

#text {
    margin: 5px;
    border: none;
    color: #cdd6f4;
} 

#entry:selected {
    background-color: #b4befe;
    border-radius: 5px;
}

#text:selected {
    color: #1e1e2e;
}
EOF

echo "=== Configurando auto-inicio de Hyprland ==="
cat >> ~/.bash_profile << 'EOF'

# Auto-start Hyprland on tty1
if [ -z "${WAYLAND_DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
    exec Hyprland
fi
EOF

echo "=== Estableciendo wallpaper por defecto ==="
# Crear directorio de wallpapers y descargar uno por defecto
mkdir -p ~/Imágenes/Wallpapers
wget -O ~/Imágenes/Wallpapers/default.jpg "https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Ftse1.mm.bing.net%2Fth%2Fid%2FOIP.GbADx9e4pec-M6QgfL_GcwHaEo%3Fpid%3DApi&f=1&ipt=348a1fbf0a31183a5ae10e7b190e65fb317b41e9c8573e3a2fe02a1d21a6d6b8&ipo=images"

cat > ~/.config/hypr/set-wallpaper.sh << 'EOF'
#!/bin/bash
swww img ~/Imágenes/Wallpapers/default.jpg --transition-type=grow --transition-pos=0.984,0.977 --transition-step=255
EOF

chmod +x ~/.config/hypr/set-wallpaper.sh

echo "=== Instalación completada! ==="
echo ""
echo "Para iniciar Hyprland:"
echo "1. Reinicia el sistema: sudo reboot"
echo "2. O inicia sesión manualmente: Hyprland"
echo ""
echo "Atajos importantes:"
echo "Super + Q -> Terminal (Kitty)"
echo "Super + R -> Lanzador (Wofi)" 
echo "Super + C -> Cerrar ventana"
echo "Super + E -> Administrador de archivos"
echo "Super + P -> Captura de pantalla"
