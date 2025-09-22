#!/bin/bash
# Instalación automática de Arch Linux en VirtualBox (Linux Zen)
# ⚠️ BORRA COMPLETAMENTE /dev/sda ⚠️

set -e

# Variables
DISK="/dev/sda"
HOSTNAME="arch"
USERNAME="arch"
PASSWORD="arch"
LOCALE="es_MX.UTF-8"
KEYMAP="la-latin1"
TIMEZONE="America/Mexico_City"

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
pacstrap /mnt base linux-zen linux-zen-headers linux-firmware base-devel vim nano networkmanager grub efibootmgr sudo

echo ">>> Generando fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

echo ">>> Configurando sistema..."
arch-chroot /mnt /bin/bash <<EOF
# Zona horaria y reloj
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Localización
echo "$LOCALE UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

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

# Activar servicios básicos
systemctl enable NetworkManager

# Instalar GRUB EFI
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
EOF

echo ">>> Instalación completada con Linux Zen."
echo ">>> Ahora puedes reiniciar con 'reboot'."

