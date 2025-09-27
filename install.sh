#!/bin/bash
# Instalación completa de Arch Linux + Hyprland Essentials
# ⚠️ BORRA COMPLETAMENTE /dev/sda ⚠️

set -e

# Variables
DISK="/dev/sda"
HOSTNAME="arch-hypr"
USERNAME="arch"
PASSWORD="arch"
LOCALE="es_ES.UTF-8"
KEYMAP="es"
TIMEZONE="Europe/Madrid"

echo ">>> Configurando teclado español..."
loadkeys es

echo ">>> Instalando Arch Linux con configuración para Hyprland..."

# Particionamiento y formato (SIN SWAP)
echo ">>> Formateando disco..."
parted $DISK mklabel gpt
parted $DISK mkpart ESP fat32 1MiB 301MiB
parted $DISK set 1 boot on
parted $DISK mkpart primary ext4 301MiB 100%

# Crear filesystems
mkfs.fat -F32 ${DISK}1
mkfs.ext4 -F ${DISK}2

# Montar
mount ${DISK}2 /mnt
mkdir -p /mnt/boot
mount ${DISK}1 /mnt/boot

echo ">>> Instalando sistema base con kernel Linux Zen..."
# QUITADO: sddm (login gráfico)
pacstrap /mnt base linux-zen linux-zen-headers linux-firmware base-devel \
vim nano networkmanager grub efibootmgr sudo git \
xdg-user-dirs pipewire wireplumber kitty tar firefox  # ← sddm removido

echo ">>> Configurando sistema..."
arch-chroot /mnt /bin/bash <<EOF
# Configurar teclado en consola
echo "KEYMAP=es" > /etc/vconsole.conf

# Zona horaria y reloj
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Localización
echo "$LOCALE UTF-8" >> /etc/locale.gen
echo "es_ES.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf

# Hostname
echo "$HOSTNAME" > /etc/hostname
cat <<EOT >> /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOT

# Root password
echo "root:$PASSWORD" | chpasswd

# Crear usuario normal
useradd -m -G wheel -s /bin/bash $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd
echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel

# Configurar fuente de consola más grande
pacman -S terminus-font --noconfirm
echo "FONT=ter-118n" >> /etc/vconsole.conf

# Activar servicios (SOLO NetworkManager, NO sddm)
systemctl enable NetworkManager

# Instalar GRUB EFI
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
EOF

# Configuración final fuera de chroot
echo ">>> Configurando fuente de consola..."
setfont ter-118n

echo ">>> Instalación base completada."
echo ""
echo ">>> AL REINICIAR SALDRÁ EN MODO TEXTO (sin login gráfico)"
echo ">>> Para iniciar Hyprland manualmente:"
echo ">>> 1. Login con usuario/contraseña"
echo ">>> 2. Ejecutar: startx" 
echo ">>> 3. O configurar un gestor de sesiones después"
echo ""
echo ">>> Particiones creadas:"
lsblk
echo ""
echo ">>> Reinicia con: umount -R /mnt && reboot"
