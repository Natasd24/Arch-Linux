#!/bin/bash
set -e

# =======================================
# 1. Configuración inicial
# =======================================
loadkeys es         # Teclado en español
timedatectl set-ntp true

# =======================================
# 2. Particionado y formateo (disco entero)
# =======================================
parted /dev/sda --script mklabel gpt \
    mkpart ESP fat32 1MiB 513MiB set 1 boot on \
    mkpart primary ext4 513MiB 100%

mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda2

mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

# =======================================
# 3. Instalación base
# =======================================
pacstrap /mnt base linux linux-firmware vim sudo networkmanager git

genfstab -U /mnt >> /mnt/etc/fstab

# =======================================
# 4. Configuración del sistema
# =======================================
arch-chroot /mnt /bin/bash <<EOF
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc

echo "es_MX.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=es_MX.UTF-8" > /etc/locale.conf
echo "KEYMAP=es" > /etc/vconsole.conf

echo "archlinux" > /etc/hostname
cat <<EOT > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   archlinux.localdomain archlinux
EOT

# usuario
useradd -m -G wheel -s /bin/bash arch
echo "arch:arch" | chpasswd
echo "root:root" | chpasswd
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# red
systemctl enable NetworkManager

# bootloader
pacman -Sy --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

EOF

# =======================================
# 5. Instalar entorno gráfico mínimo (Hyprland + Wayland)
# =======================================
arch-chroot /mnt /bin/bash <<EOF
pacman -Sy --noconfirm \
    hyprland xorg-xwayland xdg-desktop-portal-hyprland \
    waybar alacritty wofi \
    pipewire pipewire-pulse wireplumber \
    polkit seatd \
    ttf-dejavu ttf-jetbrains-mono

systemctl enable seatd
EOF

umount -R /mnt
echo "✅ Instalación terminada. Reinicia el sistema."
