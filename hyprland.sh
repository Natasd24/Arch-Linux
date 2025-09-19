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

# Detectar disco automáticamente
detect_disk() {
    if [ -b /dev/nvme0n1 ]; then
        DISK="/dev/nvme0n1"
        BOOT_PARTITION="${DISK}p1"
        ROOT_PARTITION="${DISK}p2"
        SWAP_PARTITION="${DISK}p3"
    elif [ -b /dev/sda ]; then
        DISK="/dev/sda"
        BOOT_PARTITION="${DISK}1"
        ROOT_PARTITION="${DISK}2"
        SWAP_PARTITION="${DISK}3"
    elif [ -b /dev/vda ]; then
        DISK="/dev/vda"
        BOOT_PARTITION="${DISK}1"
        ROOT_PARTITION="${DISK}2"
        SWAP_PARTITION="${DISK}3"
    else
        print_error "No se pudo detectar el disco. Por favor, configura manualmente."
    fi
    
    print_status "Disco detectado: $DISK"
}

# Variables configurables
HOSTNAME="arch-zen-gaming"
USERNAME="gamer"  # Cambiar por tu usuario
TIMEZONE="America/Mexico_City"  # Cambiar según tu zona horaria
KEYMAP="la-latin1"  # Cambiar según tu teclado

# Inicializar variables de disco
DISK=""
BOOT_PARTITION=""
ROOT_PARTITION=""
SWAP_PARTITION=""

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

# Mostrar información de discos
show_disk_info() {
    print_status "Información de discos disponibles:"
    lsblk
    echo ""
    print_warning "Se utilizará el disco: $DISK"
    print_warning "Particiones:"
    print_warning "  - Boot: $BOOT_PARTITION"
    print_warning "  - Root: $ROOT_PARTITION"
    print_warning "  - Swap: $SWAP_PARTITION"
    echo ""
    
    read -p "¿Continuar con esta configuración? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_error "Instalación cancelada por el usuario"
    fi
}

# Particionamiento del disco
partition_disk() {
    print_status "Particionando el disco $DISK"
    
    # Limpiar tabla de particiones
    umount -R /mnt 2>/dev/null || true
    swapoff -a 2>/dev/null || true
    
    # Usar parted para particionamiento más compatible
    parted -s $DISK mklabel gpt
    
    # Crear particiones
    # EFI (550M)
    parted -s $DISK mkpart primary fat32 1MiB 551MiB
    parted -s $DISK set 1 esp on
    
    # Root (40G)
    parted -s $DISK mkpart primary ext4 551MiB 40.5GiB
    
    # Swap (8G)
    parted -s $DISK mkpart primary linux-swap 40.5GiB 48.5GiB
    
    # Sincronizar
    partprobe $DISK
    sleep 2
    
    print_status "Particiones creadas"
}

# Formatear particiones
format_partitions() {
    print_status "Formateando particiones"
    
    # Formatear EFI
    mkfs.fat -F32 $BOOT_PARTITION
    
    # Formatear root
    mkfs.ext4 -F $ROOT_PARTITION
    
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
    mkdir -p /mnt/boot
    mount $BOOT_PARTITION /mnt/boot
    
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
    
    # Obtener UUID de la partición root para el bootloader
    ROOT_UUID=$(blkid -s UUID -o value $ROOT_PARTITION)
    
    # Script para chroot
    cat > /mnt/configure.sh << EOF
#!/bin/bash

set -e

# Variables
HOSTNAME="$HOSTNAME"
USERNAME="$USERNAME"
TIMEZONE="$TIMEZONE"
KEYMAP="$KEYMAP"
ROOT_UUID="$ROOT_UUID"

# Configurar zona horaria
ln -sf /usr/share/zoneinfo/\$TIMEZONE /etc/localtime
hwclock --systohc

# Configurar localización
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "es_MX.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Configurar teclado
echo "KEYMAP=\$KEYMAP" > /etc/vconsole.conf

# Configurar hostname
echo "\$HOSTNAME" > /etc/hostname

# Configurar hosts
cat > /etc/hosts << HOSTS
127.0.0.1   localhost
::1         localhost
127.0.1.1   \$HOSTNAME.localdomain   \$HOSTNAME
HOSTS

# Instalar y configurar bootloader (GRUB para mayor compatibilidad)
pacman -S --noconfirm grub efibootmgr os-prober
mkdir -p /boot/efi
mount $BOOT_PARTITION /boot/efi

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Crear usuario
useradd -m -G wheel -s /bin/bash \$USERNAME
echo "Ingresa la contraseña para \$USERNAME:"
passwd \$USERNAME

# Configurar sudo
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Instalar paquetes esenciales
pacman -S --noconfirm \\
    networkmanager \\
    openssh \\
    git \\
    python \\
    python-pip \\
    go \\
    nodejs \\
    npm

# Habilitar servicios
systemctl enable NetworkManager
systemctl enable sshd

# Instalar yay (AUR helper)
cd /tmp
git clone https://aur.archlinux.org/yay.git
chown -R \$USERNAME:\$USERNAME yay
cd yay
sudo -u \$USERNAME makepkg -si --noconfirm

# Instalar Hyprland y componentes
pacman -S --noconfirm \\
    hyprland \\
    kitty \\
    wofi \\
    swaybg \\
    swaylock \\
    xdg-desktop-portal-hyprland \\
    grim \\
    slurp \\
    wl-clipboard

# Instalar herramientas de desarrollo y utilidades
pacman -S --noconfirm \\
    neovim \\
    zsh \\
    bat \\
    lsd \\
    fzf \\
    ripgrep \\
    fd \\
    exa \\
    zoxide \\
    ttf-jetbrains-mono-nerd \\
    noto-fonts \\
    noto-fonts-cjk \\
    noto-fonts-emoji

# Instalar Eww desde AUR (manualmente por posibles problemas de dependencias)
cd /tmp
sudo -u \$USERNAME git clone https://aur.archlinux.org/eww.git
cd eww
sudo -u \$USERNAME makepkg -si --noconfirm

# Configurar Zsh con Powerlevel10k
sudo -u \$USERNAME sh -c "\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
sudo -u \$USERNAME git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /home/\$USERNAME/.oh-my-zsh/custom/themes/powerlevel10k

# Configurar Neovim con NvChad
sudo -u \$USERNAME git clone https://github.com/NvChad/NvChad /home/\$USERNAME/.config/nvim --depth 1

# Crear directorios de configuración
sudo -u \$USERNAME mkdir -p /home/\$USERNAME/.config/hypr
sudo -u \$USERNAME mkdir -p /home/\$USERNAME/.config/wofi
sudo -u \$USERNAME mkdir -p /home/\$USERNAME/.config/kitty
sudo -u \$USERNAME mkdir -p /home/\$USERNAME/.config/eww

# Configuración básica de Hyprland
sudo -u \$USERNAME cat > /home/\$USERNAME/.config/hypr/hyprland.conf << 'HYPR'
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

# Key bindings
\$mainMod = SUPER

bind = \$mainMod, RETURN, exec, kitty
bind = \$mainMod, Q, killactive,
bind = \$mainMod, M, exit,
bind = \$mainMod, E, exec, thunar
bind = \$mainMod, V, togglefloating,
bind = \$mainMod, R, exec, wofi --show drun

bind = \$mainMod, left, movefocus, l
bind = \$mainMod, right, movefocus, r
bind = \$mainMod, up, movefocus, u
bind = \$mainMod, down, movefocus, d

bind = \$mainMod, 1, workspace, 1
bind = \$mainMod, 2, workspace, 2
bind = \$mainMod, 3, workspace, 3
bind = \$mainMod, 4, workspace, 4
bind = \$mainMod, 5, workspace, 5

bind = \$mainMod SHIFT, 1, movetoworkspace, 1
bind = \$mainMod SHIFT, 2, movetoworkspace, 2
bind = \$mainMod SHIFT, 3, movetoworkspace, 3
bind = \$mainMod SHIFT, 4, movetoworkspace, 4
bind = \$mainMod SHIFT, 5, movetoworkspace, 5
HYPR

# Configurar Kitty
sudo -u \$USERNAME cat > /home/\$USERNAME/.config/kitty/kitty.conf << 'KITTY'
font_family      JetBrainsMono Nerd Font
font_size        11
background_opacity 0.9
enable_audio_bell no
KITTY

# Descargar wallpaper de Minecraft
sudo -u \$USERNAME curl -o /home/\$USERNAME/wallpaper.jpg "https://images.hdqwalls.com/download/minecraft-forest-4k-cs-1920x1080.jpg"

# Configurar Zsh
sudo -u \$USERNAME cat > /home/\$USERNAME/.zshrc << 'ZSHRC'
export ZSH="/home/\$USERNAME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(git)

source \$ZSH/oh-my-zsh.sh

# Aliases
alias ls='lsd'
alias ll='lsd -l'
alias la='lsd -a'
alias lla='lsd -la'
alias cat='bat'
alias vim='nvim'

# Configuración personalizada
eval "\$(zoxide init zsh)"
ZSHRC

# Cambiar shell por defecto a zsh
chsh -s /bin/zsh \$USERNAME

# Limpiar
rm -rf /tmp/yay /tmp/eww

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
    print_info "Contraseña: La que estableciste durante la instalación"
    print_info "Entorno: Hyprland (inicia con 'starthypr' o desde el login manager)"
    print_info "Terminal: Kitty"
    print_info "Shell: Zsh con Powerlevel10k"
}

# Función principal
main() {
    print_status "Iniciando instalación de Arch Linux Zen con Hyprland"
    
    check_root
    check_internet
    detect_disk
    show_disk_info
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
