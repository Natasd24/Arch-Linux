#!/bin/bash

# Script de instalación de Arch Linux Zen con Hyprland y personalización
# Ejecutar como root desde el live environment

set -e  # Detener el script en caso de error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables configurables
DISK="/dev/nvme0n1"  # Cambiar según tu disco
BOOT_PARTITION="${DISK}p1"
ROOT_PARTITION="${DISK}p2"
SWAP_PARTITION="${DISK}p3"  # Opcional, comentar si no quieres swap
HOSTNAME="arch-zen-gaming"
USERNAME="gamer"  # Cambiar por tu usuario
TIMEZONE="America/Mexico_City"  # Cambiar según tu zona horaria
KEYMAP="la-latin1"  # Cambiar según tu teclado

# Función para imprimir mensajes
print_status() {
    echo -e "${GREEN}[+]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

print_info() {
    echo -e "${BLUE}[*]${NC} $1"
}

# Verificar que se ejecute como root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Este script debe ejecutarse como root"
    fi
}

# Verificar conexión a internet
check_internet() {
    if ! ping -c 1 archlinux.org &> /dev/null; then
        print_error "No hay conexión a internet"
    fi
    print_status "Conexión a internet verificada"
}

# Particionamiento del disco
partition_disk() {
    print_status "Particionando el disco $DISK"
    
    # Limpiar tabla de particiones
    sgdisk -Z $DISK
    
    # Crear particiones
    # EFI (550M)
    sgdisk -n 1:0:+550M -t 1:ef00 $DISK
    # Root (resto del espacio, ajustar según necesidades)
    sgdisk -n 2:0:+40G -t 2:8300 $DISK
    # Swap (opcional, 8G)
    sgdisk -n 3:0:+8G -t 3:8200 $DISK
    
    print_status "Particiones creadas"
}

# Formatear particiones
format_partitions() {
    print_status "Formateando particiones"
    
    # Formatear EFI
    mkfs.fat -F32 $BOOT_PARTITION
    
    # Formatear root
    mkfs.ext4 $ROOT_PARTITION
    
    # Formatear e activar swap (si existe)
    if [[ -n "$SWAP_PARTITION" ]]; then
        mkswap $SWAP_PARTITION
        swapon $SWAP_PARTITION
    fi
    
    print_status "Particiones formateadas"
}

# Montar particiones
mount_partitions() {
    print_status "Montando particiones"
    
    mount $ROOT_PARTITION /mnt
    mkdir -p /mnt/boot/efi
    mount $BOOT_PARTITION /mnt/boot/efi
    
    print_status "Particiones montadas"
}

# Instalar sistema base
install_base() {
    print_status "Instalando sistema base con Linux Zen"
    
    # Kernel Zen y herramientas esenciales
    pacstrap /mnt base base-devel linux-zen linux-zen-headers linux-firmware \
               nano vim git curl wget sudo dhcpcd
    
    print_status "Sistema base instalado"
}

# Generar fstab
generate_fstab() {
    print_status "Generando fstab"
    genfstab -U /mnt >> /mnt/etc/fstab
}

# Configurar sistema
configure_system() {
    print_status "Configurando sistema"
    
    # Script para chroot
    cat > /mnt/configure.sh << 'EOF'
#!/bin/bash

set -e

# Variables
HOSTNAME="arch-zen-gaming"
USERNAME="gamer"
TIMEZONE="America/Mexico_City"
KEYMAP="la-latin1"

# Configurar zona horaria
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Configurar localización
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "es_MX.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Configurar teclado
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

# Configurar hostname
echo "$HOSTNAME" > /etc/hostname

# Configurar hosts
cat > /etc/hosts << HOSTS
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain   $HOSTNAME
HOSTS

# Instalar y configurar bootloader (systemd-boot)
bootctl --path=/boot/efi install

# Configurar entrada de boot
cat > /boot/efi/loader/entries/arch-zen.conf << BOOT
title   Arch Linux Zen
linux   /vmlinuz-linux-zen
initrd  /initramfs-linux-zen.img
options root=PARTUUID=$(blkid -s PARTUUID -o value /dev/sda2) rw quiet
BOOT

# Configurar loader.conf
echo "default arch-zen" > /boot/efi/loader/loader.conf
echo "timeout 3" >> /boot/efi/loader/loader.conf
echo "editor 0" >> /boot/efi/loader/loader.conf

# Crear usuario
useradd -m -G wheel -s /bin/bash $USERNAME
echo "Ingresa la contraseña para $USERNAME:"
passwd $USERNAME

# Configurar sudo
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Instalar paquetes esenciales
pacman -S --noconfirm \
    networkmanager \
    grub \
    efibootmgr \
    openssh \
    git \
    python \
    python-pip \
    go \
    rustup \
    nodejs \
    npm

# Habilitar servicios
systemctl enable NetworkManager
systemctl enable sshd

# Instalar yay (AUR helper)
cd /tmp
git clone https://aur.archlinux.org/yay.git
chown -R $USERNAME:$USERNAME yay
cd yay
sudo -u $USERNAME makepkg -si --noconfirm

# Instalar Hyprland y componentes
pacman -S --noconfirm \
    hyprland \
    waybar \
    rofi \
    kitty \
    wofi \
    swaybg \
    swaylock \
    xdg-desktop-portal-hyprland \
    grim \
    slurp \
    wl-clipboard

# Instalar herramientas de desarrollo y utilidades
pacman -S --noconfirm \
    neovim \
    zsh \
    bat \
    lsd \
    fzf \
    ripgrep \
    fd \
    exa \
    zoxide \
    ttf-jetbrains-mono-nerd \
    noto-fonts \
    noto-fonts-cjk \
    noto-fonts-emoji

# Instalar Eww desde AUR
sudo -u $USERNAME yay -S --noconfirm eww

# Configurar Zsh con Powerlevel10k
sudo -u $USERNAME sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
sudo -u $USERNAME git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /home/$USERNAME/.oh-my-zsh/custom/themes/powerlevel10k

# Configurar Neovim con NvChad
sudo -u $USERNAME git clone https://github.com/NvChad/NvChad /home/$USERNAME/.config/nvim --depth 1

# Crear directorios de configuración
sudo -u $USERNAME mkdir -p /home/$USERNAME/.config/hypr
sudo -u $USERNAME mkdir -p /home/$USERNAME/.config/wofi
sudo -u $USERNAME mkdir -p /home/$USERNAME/.config/kitty
sudo -u $USERNAME mkdir -p /home/$USERNAME/.config/eww

# Configurar Hyprland
sudo -u $USERNAME cat > /home/$USERNAME/.config/hypr/hyprland.conf << 'HYPR'
# Monitor configuration
monitor=,preferred,auto,1

# Execute applications at launch
exec-once = waybar
exec-once = eww daemon
exec-once = nm-applet --indicator
exec-once = swaybg -i ~/wallpaper.jpg

# Input configuration
input {
    kb_layout = us
    follow_mouse = 1
    touchpad {
        natural_scroll = no
    }
}

# General configuration
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
    layout = dwindle
}

# Decoration configuration
decoration {
    rounding = 10
    blur = yes
    blur_size = 3
    blur_passes = 1
    blur_new_optimizations = on
}

# Animations
animations {
    enabled = yes
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = borderangle, 1, 8, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

# Layout configuration
dwindle {
    pseudotile = yes
    preserve_split = yes
}

# Window rules
windowrule = float, ^(kitty)$
windowrule = center, ^(kitty)$

# Key bindings
$mainMod = SUPER

bind = $mainMod, RETURN, exec, kitty
bind = $mainMod, Q, killactive,
bind = $mainMod, M, exit,
bind = $mainMod, E, exec, nautilus
bind = $mainMod, V, togglefloating,
bind = $mainMod, R, exec, wofi --show drun
bind = $mainMod, P, pseudo, # dwindle
bind = $mainMod, J, togglesplit, # dwindle

bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9
bind = $mainMod, 0, workspace, 10

bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9
bind = $mainMod SHIFT, 0, movetoworkspace, 10

bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1

bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow
HYPR

# Configurar Wofi
sudo -u $USERNAME cat > /home/$USERNAME/.config/wofi/style.css << 'WOFI'
window {
    margin: 0px;
    border: 2px solid rgba(100, 100, 100, 0.8);
    background-color: rgba(29, 31, 33, 0.9);
    border-radius: 10px;
}

#input {
    margin: 5px;
    border: none;
    color: #f8f8f2;
    background-color: rgba(55, 59, 65, 0.8);
}

#inner-box {
    margin: 5px;
    border: none;
    background-color: transparent;
}

#outer-box {
    margin: 5px;
    border: none;
    background-color: transparent;
}

#scroll {
    margin: 0px;
    border: none;
}

#text {
    margin: 5px;
    border: none;
    color: #f8f8f2;
}

#entry:selected {
    background-color: rgba(60, 120, 200, 0.8);
    border-radius: 5px;
}
WOFI

# Configurar Kitty
sudo -u $USERNAME cat > /home/$USERNAME/.config/kitty/kitty.conf << 'KITTY'
font_family      JetBrainsMono Nerd Font
font_size        11
bold_font        auto
italic_font      auto
bold_italic_font auto

background_opacity 0.9

confirm_os_window_close 0

enable_audio_bell no

window_padding_width 10

# Colors
foreground #ffffff
background #1a1b26

color0 #15161E
color1 #f7768e
color2 #9ece6a
color3 #e0af68
color4 #7aa2f7
color5 #bb9af7
color6 #7dcfff
color7 #a9b1d6

color8 #414868
color9 #f7768e
color10 #9ece6a
color11 #e0af68
color12 #7aa2f7
color13 #bb9af7
color14 #7dcfff
color15 #c0caf5

cursor #c0caf5
cursor_text_color #1a1b26
selection_foreground #1a1b26
selection_background #c0caf5
KITTY

# Configurar Eww
sudo -u $USERNAME mkdir -p /home/$USERNAME/.config/eww/eww.yuck
sudo -u $USERNAME mkdir -p /home/$USERNAME/.config/eww/eww.scss

sudo -u $USERNAME cat > /home/$USERNAME/.config/eww/eww.yuck << 'EWW_YUCK'
(defwindow bar
  :monitor 0
  :windowtype "dock"
  :geometry (geometry :x "0px"
                      :y "0px"
                      :width "100%"
                      :height "30px"
                      :anchor "top center")
  :stacking "bg"
  :reserve (struts :side "top" :distance "30px")
  (bar))

(defpoll time :interval "10s"
  `date '+%H:%M'`)

(defpoll date :interval "30s"
  `date '+%A, %d %B'`)

(defwidget bar []
  (centerbox :orientation "horizontal"
    (left)
    (center)
    (right)))

(defwidget left []
  (box :class "left"
    (label :text " Arch Linux")))

(defwidget center []
  (box :class "center"
    (label :text {time})))

(defwidget right []
  (box :class "right"
    (label :text " 50%")
    (label :text "  WiFi")
    (label :text "  90%")))
EWW_YUCK

sudo -u $USERNAME cat > /home/$USERNAME/.config/eww/eww.scss << 'EWW_SCSS'
* {
  all: unset;
}

.bar {
  background-color: rgba(29, 31, 33, 0.9);
  border-radius: 10px;
  margin: 5px;
  padding: 0 10px;
}

.left, .center, .right {
  background-color: transparent;
}

.left {
  color: #7aa2f7;
  font-weight: bold;
}

.center {
  color: #9ece6a;
  font-weight: bold;
}

.right {
  color: #e0af68;
}

.right label {
  margin: 0 5px;
}
EWW_SCSS

# Descargar wallpaper de Minecraft
sudo -u $USERNAME curl -o /home/$USERNAME/wallpaper.jpg "https://images.hdqwalls.com/download/minecraft-forest-4k-cs-1920x1080.jpg"

# Configurar Zsh
sudo -u $USERNAME cat > /home/$USERNAME/.zshrc << 'ZSHRC'
export ZSH="/home/$USERNAME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(git zsh-syntax-highlighting zsh-autosuggestions)

source $ZSH/oh-my-zsh.sh

# Aliases
alias ls='lsd'
alias ll='lsd -l'
alias la='lsd -a'
alias lla='lsd -la'
alias cat='bat'
alias vim='nvim'

# Configuración de Powerlevel10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Configuración personalizada
eval "$(zoxide init zsh)"
ZSHRC

# Configurar Powerlevel10k
sudo -u $USERNAME cat > /home/$USERNAME/.p10k.zsh << 'P10K'
# Configuración básica de Powerlevel10k
typeset -g POWERLEVEL9K_MODE=nerdfont-complete
typeset -g POWERLEVEL9K_PROMPT_ON_NEWLINE=true
typeset -g POWERLEVEL9K_RPROMPT_ON_NEWLINE=false
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon context dir vcs)
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status root_indicator background_jobs time)
typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_last
P10K

# Cambiar shell por defecto a zsh
chsh -s /bin/zsh $USERNAME

# Limpiar
rm -rf /tmp/yay

EOF
    
    # Hacer ejecutable y ejecutar en chroot
    chmod +x /mnt/configure.sh
    arch-chroot /mnt ./configure.sh
    rm /mnt/configure.sh
}

# Finalizar instalación
finish_installation() {
    print_status "Finalizando instalación"
    
    # Desmontar particiones
    umount -R /mnt
    
    print_status "¡Instalación completada!"
    print_warning "Reinicia el sistema y retira el medio de instalación"
    print_info "Usuario: $USERNAME"
    print_info "Entorno: Hyprland"
    print_info "Terminal: Kitty"
    print_info "Shell: Zsh con Powerlevel10k"
    print_info "Editor: Neovim con NvChad"
    print_info "Barra de estado: Eww"
    print_info "Lanzador: Wofi"
}

# Función principal
main() {
    print_status "Iniciando instalación de Arch Linux Zen con Hyprland"
    
    check_root
    check_internet
    partition_disk
    format_partitions
    mount_partitions
    install_base
    generate_fstab
    configure_system
    finish_installation
    
    print_status "Instalación completada exitosamente!"
}

# Ejecutar función principal
main "$@"
