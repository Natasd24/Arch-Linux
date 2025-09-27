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
TIMEZONE="Europe/Madrid"

echo ">>> Formateando disco..."
parted $DISK mklabel gpt
parted $DISK mkpart ESP fat32 1MiB 301MiB
parted $DISK set 1 boot on
parted $DISK mkpart primary linux-swap 301MiB 16GiB
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

# Configurar fuente de consola
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
    ttf-jetbrains-mono-nerd \
    noto-fonts \
    noto-fonts-emoji
EOF

echo ">>> Instalando Hyprland y componentes esenciales..."
arch-chroot /mnt /bin/bash <<'EOF'
pacman -S --noconfirm hyprland waybar rofi thunar firefox
EOF

echo ">>> Preparando instalación de yay..."
arch-chroot /mnt /bin/bash <<EOF
# Instalar dependencias necesarias para yay
pacman -S --noconfirm --needed git base-devel go

# Configurar el usuario para makepkg
echo ">>> Configurando makepkg para el usuario $USERNAME..."
sudo -u $USERNAME bash -c '
    # Crear configuración de makepkg
    mkdir -p ~/.config/makepkg
    cat > ~/.config/makepkg/makepkg.conf <<EOL
MAKEFLAGS="-j\$(nproc)"
BUILDDIR=/tmp/makepkg
PKGDEST=/tmp/makepkg
PACKAGER="$USERNAME <$USERNAME@$HOSTNAME>"
EOL
'
EOF

echo ">>> Instalando yay (AUR Helper)..."
arch-chroot /mnt /bin/bash <<EOF
cd /tmp
rm -rf yay 2>/dev/null || true

# Clonar yay como usuario normal
sudo -u $USERNAME git clone https://aur.archlinux.org/yay.git
cd yay

# Instalar yay sin confirmación interactiva
sudo -u $USERNAME bash -c '
    # Forzar la instalación sin preguntas
    yes | makepkg -si --noconfirm --needed
'

# Verificar instalación
sudo -u $USERNAME yay --version && echo ">>> Yay instalado correctamente"
EOF

echo ">>> Instalando aplicaciones adicionales desde AUR..."
arch-chroot /mnt /bin/bash <<EOF
# Configurar yay para no pedir confirmación
sudo -u $USERNAME yay -Y --gendb
sudo -u $USERNAME yay -Y --devel --save
sudo -u $USERNAME yay -Y --combinedupgrade --save

# Instalar aplicaciones AUR
sudo -u $USERNAME yay -S --noconfirm brave-bin
# visual-studio-code-bin puede ser muy grande, opcional
# sudo -u $USERNAME yay -S --noconfirm visual-studio-code-bin
EOF

echo ">>> Configuración post-instalación..."
arch-chroot /mnt /bin/bash <<EOF
# Crear carpetas de usuario
sudo -u $USERNAME xdg-user-dirs-update

# Configurar PipeWire para audio
sudo -u $USERNAME systemctl --user enable pipewire pipewire-pulse wireplumber

# Configurar permisos para el usuario
chown -R $USERNAME:$USERNAME /home/$USERNAME

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
