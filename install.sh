#!/bin/bash
# Instalación automática de Arch Linux con Hyprland y herramientas esenciales
# ⚠️ BORRA COMPLETAMENTE /dev/sda ⚠️

set -e

# Variables
DISK="/dev/sda"
HOSTNAME="arch-hypr"
USERNAME="arch"
PASSWORD="arch"
LOCALE="es_ES.UTF-8"  
KEYMAP="es"           
TIMEZONE="America/Mexico_City"

echo ">>> Formateando disco..."
parted $DISK mklabel gpt
parted $DISK mkpart ESP fat32 1MiB 301MiB
parted $DISK set 1 boot on
parted $DISK mkpart primary linux-swap 301MiB 16GiB  # SWAP añadido
parted $DISK mkpart primary ext4 16GiB 100%

# Crear filesystems
mkfs.fat -F32 ${DISK}1
mkswap ${DISK}2
swapon ${DISK}2
mkfs.ext4 -F ${DISK}3

# Montar
mount ${DISK}3 /mnt
mkdir -p /mnt/boot
mount ${DISK}1 /mnt/boot

echo ">>> Instalando sistema base con kernel Linux Zen..."
pacstrap /mnt base linux-zen linux-zen-headers linux-firmware base-devel \
vim nano networkmanager grub efibootmgr sudo git \
xdg-user-dirs pipewire wireplumber sddm kitty tar

echo ">>> Generando fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

echo ">>> Configurando sistema..."
arch-chroot /mnt /bin/bash <<EOF
# Zona horaria y reloj
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Localización
echo "$LOCALE UTF-8" >> /etc/locale.gen
echo "es_ES.UTF-8 UTF-8" >> /etc/locale.gen
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

# Configurar fuente de consola (más legible)
echo "FONT=ter-118n" >> /etc/vconsole.conf

# Activar servicios
systemctl enable NetworkManager
systemctl enable sddm

# Instalar GRUB EFI
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
EOF

echo ">>> Instalando fuentes Nerd Fonts..."
arch-chroot /mnt /bin/bash <<'EOF'
pacman -S --noconfirm \
    ttf-cascadia-code-nerd \
    ttf-cascadia-mono-nerd \
    ttf-fira-code \
    ttf-fira-mono \
    ttf-fira-sans \
    ttf-firacode-nerd \
    ttf-iosevka-nerd \
    ttf-iosevkaterm-nerd \
    ttf-jetbrains-mono-nerd \
    ttf-jetbrains-mono \
    ttf-nerd-fonts-symbols \
    ttf-nerd-fonts-symbols-mono \
    noto-fonts \
    noto-fonts-cjk \
    noto-fonts-emoji
EOF

echo ">>> Instalando yay (AUR Helper)..."
arch-chroot /mnt /bin/bash <<'EOF'
cd /tmp
sudo -u $USERNAME bash -c '
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
'
EOF

echo ">>> Instalando aplicaciones adicionales desde AUR..."
arch-chroot /mnt /bin/bash <<EOF
# Como usuario normal
sudo -u $USERNAME yay -S --noconfirm brave-bin visual-studio-code-bin

# Instalar Hyprland y componentes esenciales
pacman -S --noconfirm hyprland waybar rofi thunar firefox
EOF

echo ">>> Configuración post-instalación..."
arch-chroot /mnt /bin/bash <<EOF
# Crear carpetas de usuario
sudo -u $USERNAME xdg-user-dirs-update

# Configurar PipeWire para audio
systemctl --user enable pipewire pipewire-pulse wireplumber

# Mensaje de finalización
echo ">>> Instalación completada!"
echo ">>> Sistema listo para Hyprland"
echo ">>> Usuario: $USERNAME"
echo ">>> Contraseña: $PASSWORD"
echo ">>> Reinicia con: reboot"
EOF

echo ">>> ¡Instalación completada con éxito!"
echo ">>> Hyprland y todas las herramientas están instaladas"
echo ">>> Reinicia el sistema y inicia sesión en Hyprland"
