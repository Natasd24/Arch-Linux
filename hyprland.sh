#!/bin/bash
# Instalación automática de Arch Linux + Hyprland (Linux Zen)
# ⚠️ Este script BORRA COMPLETAMENTE /dev/sda ⚠️

set -e

# ==========================
# Variables
# ==========================
DISK="/dev/sda"
HOSTNAME="arch"
USERNAME="arch"
PASSWORD="arch"
LOCALE="es_MX.UTF-8"
KEYMAP="la-latin1"
TIMEZONE="America/Mexico_City"

# ==========================
# 1. Particionado y formateo
# ==========================
echo ">>> Formateando disco $DISK ..."
parted $DISK mklabel gpt
parted $DISK mkpart ESP fat32 1MiB 301MiB
parted $DISK set 1 boot on
parted $DISK mkpart primary ext4 301MiB 100%

mkfs.fat -F32 ${DISK}1
mkfs.ext4 -F ${DISK}2

mount ${DISK}2 /mnt
mkdir -p /mnt/boot
mount ${DISK}1 /mnt/boot

# ==========================
# 2. Instalación del sistema base
# ==========================
echo ">>> Instalando sistema base con kernel Linux Zen..."
pacstrap /mnt base linux-zen linux-zen-headers linux-firmware base-devel \
vim nano networkmanager grub efibootmgr sudo git xdg-user-dirs \
virtualbox-guest-utils

genfstab -U /mnt >> /mnt/etc/fstab

# ==========================
# 3. Configuración dentro de chroot
# ==========================
arch-chroot /mnt /bin/bash <<EOF
set -e

echo ">>> Configurando zona horaria y localización..."
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

echo "$LOCALE UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

echo "$HOSTNAME" > /etc/hostname
cat <<EOT >> /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOT

# ==========================
# Usuarios
# ==========================
echo ">>> Creando usuarios..."
echo "root:$PASSWORD" | chpasswd
useradd -m -G wheel -s /bin/bash $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd
echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel

# ==========================
# Servicios
# ==========================
systemctl enable NetworkManager
systemctl enable vboxservice

# ==========================
# Bootloader
# ==========================
echo ">>> Instalando GRUB EFI..."
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# ==========================
# 4. Post-instalación (ejecutado como usuario normal)
# ==========================
su - $USERNAME <<'EOSU'
set -e

echo ">>> Configuración post-instalación (Hyprland + paquetes extra)"

# 1. Actualización
sudo pacman -Syu --noconfirm

# 2. Instalar yay
echo ">>> Instalando yay..."
git clone https://aur.archlinux.org/yay-git.git
cd yay-git
makepkg -si --noconfirm
cd ..

# 3. Instalar paquetes con yay
echo ">>> Instalando paquetes yay..."
yay -S --noconfirm hyprland kitty brave-bin wl-clip-persist swaylock-effects \
xviewer zsh-syntax-highlighting zsh-autosuggestions nwg-look \
telegram-desktop visual-studio-code-bin autofirma configuradorfnmt \
gnome-disk-utility evince sddm-theme-sugar-candy-git light

# 4. Instalar paquetes con pacman
echo ">>> Instalando paquetes pacman..."
sudo pacman -S --noconfirm sddm rofi waybar unzip pavucontrol pulseaudio pamixer \
xautolock hyprpaper nemo cinnamon-translations grim slurp swappy dunst \
zsh bat lsd neofetch wget udisks2 udiskie ntfs-3g vlc network-manager-applet \
spotify-launcher megatools pacman-contrib acpi ntp

# 5. Habilitar SDDM
sudo systemctl enable sddm

echo ">>> Post-instalación completada."
EOSU

EOF

echo ">>> Instalación COMPLETA con Linux Zen + Hyprland."
echo ">>> Ahora puedes reiniciar con: reboot"
