#!/bin/bash
set -e

echo "[1/8] Configurando teclado y particiones..."
loadkeys es
parted /dev/sda --script mklabel gpt \
    mkpart ESP fat32 1MiB 513MiB set 1 boot on \
    mkpart primary ext4 513MiB 100%

echo "[2/8] Formateando particiones..."
mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda2

echo "[3/8] Montando particiones..."
mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

echo "[4/8] Instalando base con kernel Zen..."
pacstrap -K /mnt base linux-zen linux-zen-headers linux-firmware \
    vim nano networkmanager sudo

echo "[5/8] Generando fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

echo "[6/8] Entrando a chroot..."
arch-chroot /mnt /bin/bash <<'EOF'

# Zona horaria y localización
ln -sf /usr/share/zoneinfo/America/Mexico_City /etc/localtime
hwclock --systohc
echo "es_MX.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=es" > /etc/vconsole.conf

# Hostname y red
echo "arch-vbox" > /etc/hostname
cat <<EOT > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   arch-vbox.localdomain arch-vbox
EOT
systemctl enable NetworkManager

# Bootloader (systemd-boot)
bootctl install
UUID=\$(blkid -s UUID -o value /dev/sda2)

cat <<EOT > /boot/loader/entries/arch-zen.conf
title   Arch Linux (Zen)
linux   /vmlinuz-linux-zen
initrd  /initramfs-linux-zen.img
options root=UUID=\$UUID rw
EOT

cat <<EOT > /boot/loader/loader.conf
default arch-zen.conf
timeout 3
editor  no
EOT

# Usuario root y normal
echo "root:root123" | chpasswd
useradd -m -G wheel -s /bin/bash nameless
echo "nameless:user123" | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Paquetes esenciales Hyprland y VM
pacman -S --needed --noconfirm \
    hyprland seatd polkit kitty wofi eww \
    wayland xdg-user-dirs xdg-utils wl-clipboard \
    pipewire wireplumber pipewire-audio noto-fonts \
    virtualbox-guest-utils mesa

systemctl enable seatd
systemctl enable vboxservice

# Greetd con tuigreet
pacman -S --noconfirm greetd greetd-tuigreet
systemctl enable greetd
cat <<EOT > /etc/greetd/config.toml
[default_session]
command = "tuigreet --cmd Hyprland"
user = "nameless"
EOT

EOF

echo "[7/8] Desmontando y reiniciando..."
umount -R /mnt
reboot

