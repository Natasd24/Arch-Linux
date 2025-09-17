#!/bin/bash
set -euo pipefail

# ==========================
# 1. Configuración inicial
# ==========================
loadkeys es
timedatectl set-ntp true

# ==========================
# 2. Particionar disco (GPT)
# ==========================
parted /dev/sda --script mklabel gpt \
    mkpart ESP fat32 1MiB 513MiB set 1 boot on \
    mkpart primary ext4 513MiB 100%

# ==========================
# 3. Formatear
# ==========================
mkfs.fat -F32 /dev/sda1
mkfs.ext4 -F /dev/sda2

# ==========================
# 4. Montar
# ==========================
mount /dev/sda2 /mnt
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot

# ==========================
# 5. Instalar base (Zen kernel)
# ==========================
pacstrap -K /mnt base linux-zen linux-zen-headers linux-firmware \
    vim nano networkmanager sudo

# ==========================
# 6. Fstab
# ==========================
genfstab -U /mnt >> /mnt/etc/fstab

# ==========================
# 7. Configuración en chroot
# ==========================
arch-chroot /mnt /bin/bash <<EOF
set -euo pipefail

# Zona horaria y locales
ln -sf /usr/share/zoneinfo/America/Mexico_City /etc/localtime
hwclock --systohc
echo "es_MX.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=es" > /etc/vconsole.conf

# Hostname y red
echo "arch-vm" > /etc/hostname
cat <<HOSTS > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   arch-vm.localdomain arch-vm
HOSTS
systemctl enable NetworkManager

# Bootloader (systemd-boot con Zen)
bootctl install
UUID=\$(blkid -s UUID -o value /dev/sda2)

cat <<BOOT > /boot/loader/entries/arch-zen.conf
title   Arch Linux (Zen)
linux   /vmlinuz-linux-zen
initrd  /initramfs-linux-zen.img
options root=UUID=\$UUID rw
BOOT

cat <<LOADER > /boot/loader/loader.conf
default arch-zen.conf
timeout 3
editor  no
LOADER

# Usuarios
echo "root:root123" | chpasswd
useradd -m -G wheel -s /bin/bash vmuser
echo "vmuser:user123" | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Hyprland mínimo
pacman -S --needed --noconfirm \
    hyprland seatd polkit kitty wofi eww \
    wayland xdg-utils wl-clipboard

systemctl enable seatd

# Login manager (greetd + tuigreet)
pacman -S --noconfirm greetd greetd-tuigreet
systemctl enable greetd
cat <<GREETD > /etc/greetd/config.toml
[default_session]
command = "tuigreet --cmd Hyprland"
user = "vmuser"
GREETD

# Audio y fuentes
pacman -S --noconfirm pipewire wireplumber pipewire-audio noto-fonts
EOF

# ==========================
# 8. Finalizar
# ==========================
umount -R /mnt
echo "Instalación completada. Reinicia la VM."
