#!/bin/bash
set -e

trap 'echo "❌ Error en la línea $LINENO. Revisa el script o los comandos ejecutados." >&2; exit 1' ERR

# ==========================
# 1. Teclado y particionar disco
# ==========================
loadkeys es
parted /dev/sda --script mklabel gpt \
    mkpart ESP fat32 1MiB 513MiB set 1 esp on \
    mkpart primary ext4 513MiB 100%

# ==========================
# 2. Formatear
# ==========================
mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda2

# ==========================
# 3. Montar
# ==========================
mount /dev/sda2 /mnt
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot

# ==========================
# 4. Optimizar mirrors y descargas
# ==========================
pacman -Sy --noconfirm reflector
reflector --country Mexico,US --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 5/' /etc/pacman.conf

# ==========================
# 5. Instalar base (solo kernel Zen)
# ==========================
pacstrap -K /mnt base base-devel linux-zen linux-zen-headers linux-firmware \
    vim nano networkmanager sudo xdg-user-dirs

# ==========================
# 6. Generar fstab
# ==========================
genfstab -U /mnt >> /mnt/etc/fstab

# ==========================
# 7. Chroot y configuración
# ==========================
arch-chroot /mnt /bin/bash <<'EOF'

# Zona horaria y locales
ln -sf /usr/share/zoneinfo/America/Mexico_City /etc/localtime
hwclock --systohc
echo "es_MX.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=es" > /etc/vconsole.conf

# Hostname y red
echo "Arch-Nameless" > /etc/hostname
cat <<EOT > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   Arch-Nameless.localdomain Arch-Nameless
EOT
systemctl enable NetworkManager

# Bootloader (systemd-boot)
bootctl install
UUID=$(blkid -s UUID -o value /dev/sda2)
cat <<EOT > /boot/loader/entries/arch-zen.conf
title   Arch Linux (Zen)
linux   /vmlinuz-linux-zen
initrd  /initramfs-linux-zen.img
options root=UUID=$UUID rw
EOT

cat <<EOT > /boot/loader/loader.conf
default arch-zen.conf
timeout 3
editor  no
EOT

# Usuarios y contraseñas
echo "root:root123" | chpasswd
useradd -m -G wheel,seat -s /bin/bash Nameless
echo "Nameless:user123" | chpasswd

# Dar sudo al grupo wheel
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Swapfile
fallocate -l 8G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap defaults 0 0' >> /etc/fstab

# Hyprland con todas las dependencias necesarias
pacman -S --needed --noconfirm \
    hyprland seatd polkit kitty wofi eww \
    wayland xdg-utils wl-clipboard xdg-desktop-portal-hyprland \
    pipewire wireplumber pipewire-audio pipewire-pulse \
    noto-fonts noto-fonts-emoji

# Configurar seatd
systemctl enable seatd
usermod -a -G seat Nameless

# Configurar greetd
pacman -S --noconfirm greetd greetd-tuigreet
systemctl enable greetd

mkdir -p /etc/greetd
cat <<EOT > /etc/greetd/config.toml
[terminal]
vt = 1

[default_session]
command = "tuigreet --remember --remember-user-session --time --cmd 'Hyprland'"
user = "greeter"
EOT

# Crear usuario greeter
useradd -M -s /bin/false greeter
chown -R greeter:greeter /etc/greetd

# Crear carpetas de usuario
sudo -u Nameless xdg-user-dirs-update

EOF

# ==========================
# 8. Desmontar y reiniciar
# ==========================
umount -R /mnt
reboot
