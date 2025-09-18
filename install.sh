#!/bin/bash
set -e

# ==========================
# 1. Configuración inicial
# ==========================
loadkeys es
timedatectl set-ntp true

# ==========================
# 2. Particionar disco (UEFI con GPT)
# ==========================
parted /dev/sda --script mklabel gpt \
    mkpart ESP fat32 1MiB 513MiB set 1 boot on \
    mkpart primary ext4 513MiB 100%

mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda2

mount /dev/sda2 /mnt
mkdir -p /mnt/boot/efi
mount /dev/sda1 /mnt/boot/efi

# ==========================
# 3. Instalar sistema base
# ==========================
pacstrap /mnt base base-devel linux-zen linux-zen-headers linux-firmware \
    networkmanager vim git sudo

genfstab -U /mnt >> /mnt/etc/fstab

# ==========================
# 4. Configuración dentro de chroot
# ==========================
arch-chroot /mnt /bin/bash <<EOF
set -e

# Zona horaria
ln -sf /usr/share/zoneinfo/America/Mexico_City /etc/localtime
hwclock --systohc

# Locales
echo "es_MX.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=es_MX.UTF-8" > /etc/locale.conf

# Hostname y red
echo "Arch-Nameless" > /etc/hostname
cat <<NET > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   Arch-Nameless.localdomain Arch-Nameless
NET

# Usuarios
echo "root:root123" | chpasswd
useradd -m -G wheel -s /bin/bash Nameless
echo "Nameless:user123" | chpasswd
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers

# Bootloader systemd-boot
bootctl --path=/boot/efi install
cat <<BOOT > /boot/efi/loader/entries/arch.conf
title   Arch Linux Zen
linux   /vmlinuz-linux-zen
initrd  /initramfs-linux-zen.img
options root=/dev/sda2 rw
BOOT

cat <<CONF > /boot/efi/loader/loader.conf
default arch.conf
timeout 3
editor  no
CONF

# Activar servicios
systemctl enable NetworkManager

# ==========================
# 5. Instalar entorno Hyprland + utilidades
# ==========================
pacman -S --noconfirm \
    hyprland kitty wofi eww wl-clipboard xdg-user-dirs \
    seatd polkit greetd greetd-tuigreet pipewire wireplumber pipewire-audio \
    noto-fonts swww

# greetd configuración mínima
mkdir -p /etc/greetd
cat <<GREET >/etc/greetd/config.toml
[terminal]
vt = 1

[default_session]
command = "tuigreet --cmd Hyprland"
user = "greeter"
GREET

systemctl enable greetd
systemctl enable seatd

# Carpetas de usuario (Documentos, Descargas, etc.)
runuser -l Nameless -c "xdg-user-dirs-update"

EOF

# ==========================
# 6. Desmontar y reiniciar
# ==========================
umount -R /mnt
echo "✅ Instalación completada. Retira el ISO y reinicia el sistema."
