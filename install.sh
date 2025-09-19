#!/bin/bash

# Script de instalación mínima de Arch Linux para VirtualBox
# Ejecutar como root desde el live environment

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Variables configurables
DISK="/dev/sda"
HOSTNAME="arch-vbox"
USERNAME="usuario"
TIMEZONE="America/Mexico_City"
KEYMAP="la-latin1"

# Función para imprimir mensajes
print_status() { echo -e "${GREEN}[+]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Verificar root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Este script debe ejecutarse como root"
    fi
}

# Verificar internet
check_internet() {
    if ! ping -c 1 archlinux.org &> /dev/null; then
        print_error "No hay conexión a internet"
    fi
    print_status "Conexión a internet verificada"
}

# Particionamiento
partition_disk() {
    print_status "Particionando el disco $DISK"
    
    umount -R /mnt 2>/dev/null || true
    swapoff -a 2>/dev/null || true
    
    parted -s $DISK mklabel msdos
    parted -s $DISK mkpart primary ext4 1MiB 100%
    parted -s $DISK set 1 boot on
    
    partprobe $DISK
    sleep 2
}

# Formatear particiones
format_partitions() {
    print_status "Formateando particiones"
    mkfs.ext4 -F ${DISK}1
}

# Montar particiones
mount_partitions() {
    print_status "Montando particiones"
    mount ${DISK}1 /mnt
}

# Instalar sistema base
install_base() {
    print_status "Instalando sistema base"
    pacstrap /mnt base linux linux-firmware sudo nano vim git
}

# Generar fstab
generate_fstab() {
    print_status "Generando fstab"
    genfstab -U /mnt >> /mnt/etc/fstab
}

# Configurar sistema
configure_system() {
    print_status "Configurando sistema"
    
    cat > /mnt/configure.sh << 'EOF'
#!/bin/bash
set -e

# Variables
HOSTNAME="arch-vbox"
USERNAME="usuario"
TIMEZONE="America/Mexico_City"
KEYMAP="la-latin1"

# Zona horaria
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Localización
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

# Hostname
echo "$HOSTNAME" > /etc/hostname
cat > /etc/hosts << HOSTS
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain   $HOSTNAME
HOSTS

# Instalar GRUB
pacman -S --noconfirm grub
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

# Crear usuario
useradd -m -G wheel -s /bin/bash $USERNAME
echo "Ingresa la contraseña para $USERNAME:"
passwd $USERNAME
echo "Ingresa la contraseña para root:"
passwd

# Configurar sudo
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Instalar paquetes básicos
pacman -S --noconfirm \
    networkmanager \
    openssh \
    dhcpcd

# Habilitar servicios
systemctl enable NetworkManager
systemctl enable sshd

# Instalar VirtualBox Guest Utils
pacman -S --noconfirm virtualbox-guest-utils
systemctl enable vboxservice

EOF

    chmod +x /mnt/configure.sh
    arch-chroot /mnt ./configure.sh
    rm /mnt/configure.sh
}

# Finalizar instalación
finish_installation() {
    print_status "Finalizando instalación"
    umount -R /mnt
    print_status "¡Instalación completada! Reinicia el sistema."
}

# Función principal
main() {
    check_root
    check_internet
    partition_disk
    format_partitions
    mount_partitions
    install_base
    generate_fstab
    configure_system
    finish_installation
}

main "$@"
