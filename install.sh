#!/bin/bash
set -e

# ==========================
# Solicitar datos de usuario
# ==========================
echo "=== CONFIGURACIÓN DE USUARIO ==="
read -p "Nombre de usuario: " username
read -sp "Contraseña del usuario: " user_password
echo
read -sp "Contraseña de root: " root_password
echo

# ==========================
# 1. Teclado y particionar disco
# ==========================
loadkeys es

# Instalar parted si no está disponible
pacman -Sy --noconfirm parted

parted /dev/sda --script mklabel gpt \
    mkpart ESP fat32 1MiB 513MiB set 1 boot on \
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
mkdir -p /mnt/boot/efi
mount /dev/sda1 /mnt/boot/efi

# ==========================
# 4. Instalar base (solo kernel zen)
# ==========================
pacstrap -K /mnt base base-devel linux-zen linux-zen-headers linux-firmware \
    vim nano networkmanager sudo parted neofetch

# ==========================
# 5. Fstab
# ==========================
genfstab -U /mnt >> /mnt/etc/fstab

# ==========================
# 6. Chroot
# ==========================
arch-chroot /mnt /bin/bash <<EOF

# Zona horaria y locales
ln -sf /usr/share/zoneinfo/America/Mexico_City /etc/localtime
hwclock --systohc
echo "es_MX.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=es" > /etc/vconsole.conf

# Hostname y red
echo "Arch-$username" > /etc/hostname
cat <<EOT > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   Arch-$username.localdomain Arch-$username
EOT
systemctl enable NetworkManager

# Bootloader (solo zen)
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

# Usuarios y contraseñas
echo "root:$root_password" | chpasswd
useradd -m -G wheel,seat -s /bin/bash $username
echo "$username:$user_password" | chpasswd

# Dar sudo al grupo wheel
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers

# Hyprland + utilidades mínimas y recomendadas
pacman -S --needed --noconfirm \
    hyprland seatd polkit lxqt-policykit \
    kitty wofi eww wayland xdg-user-dirs xdg-utils \
    wl-clipboard xdg-desktop-portal-hyprland \
    noto-fonts noto-fonts-emoji noto-fonts-cjk \
    pipewire pipewire-pulse pipewire-alsa wireplumber

systemctl enable seatd

# Login manager (greetd + tuigreet)
pacman -S --noconfirm greetd greetd-tuigreet
systemctl enable greetd

# Crear directorio de configuración de greetd
mkdir -p /etc/greetd

cat <<EOT > /etc/greetd/config.toml
[terminal]
vt = 1

[default_session]
command = "tuigreet --cmd /usr/bin/Hyprland"
user = "greetd"
EOT

# Configurar permisos para greetd
chown -R greetd:greetd /etc/greetd

# Crear carpetas de usuario (Documentos, Descargas, etc.)
# Esto se ejecutará cuando el usuario inicie sesión por primera vez
pacman -S --noconfirm xdg-user-dirs
echo "#!/bin/bash" > /etc/profile.d/xdg-dirs.sh
echo "if [ -n \"\\\$XDG_SESSION_TYPE\" ]; then" >> /etc/profile.d/xdg-dirs.sh
echo "    xdg-user-dirs-update" >> /etc/profile.d/xdg-dirs.sh
echo "fi" >> /etc/profile.d/xdg-dirs.sh
chmod +x /etc/profile.d/xdg-dirs.sh

EOF

# ==========================
# 7. Crear script de post-instalación para el usuario
# ==========================
arch-chroot /mnt /bin/bash <<EOF
# Crear script que se ejecutará en el primer inicio
mkdir -p /home/$username/.config/autostart
cat <<EOT > /home/$username/.config/autostart/xdg-dirs.desktop
[Desktop Entry]
Type=Application
Name=Create User Directories
Exec=xdg-user-dirs-update
OnlyShowIn=Hyprland;
X-GNOME-Autostart-enabled=true
EOT

chown -R $username:$username /home/$username
EOF

# ==========================
# 8. Reinicio
# ==========================
echo "=== INSTALACIÓN COMPLETADA ==="
echo "Usuario: $username"
echo "Hostname: Arch-$username"
neofetch
echo "El sistema se reiniciará en 5 segundos..."
sleep 5
umount -R /mnt
reboot
