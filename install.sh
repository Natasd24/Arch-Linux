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
    vim nano networkmanager sudo parted

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
    pipewire pipewire-pulse pipewire-alsa wireplumber \
    neofetch  # Agregar neofetch

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

# Carpetas de usuario XDG
pacman -S --noconfirm xdg-user-dirs
echo "#!/bin/bash" > /etc/profile.d/xdg-dirs.sh
echo "if [ -n \"\\\$XDG_SESSION_TYPE\" ]; then" >> /etc/profile.d/xdg-dirs.sh
echo "    xdg-user-dirs-update" >> /etc/profile.d/xdg-dirs.sh
echo "fi" >> /etc/profile.d/xdg-dirs.sh
chmod +x /etc/profile.d/xdg-dirs.sh

# Instalar VirtualBox Guest Additions si estamos en VirtualBox
if dmesg | grep -i "virtualbox" > /dev/null 2>&1; then
    echo "=== DETECTADO VIRTUALBOX - INSTALANDO GUEST ADDITIONS ==="
    
    # Instalar dependencias necesarias
    pacman -S --noconfirm virtualbox-guest-utils virtualbox-guest-modules-zen
    
    # Habilitar servicios de VirtualBox
    systemctl enable vboxservice.service
    
    # Agregar módulos al initramfs
    echo "vboxguest" >> /etc/modules-load.d/virtualbox.conf
    echo "vboxsf" >> /etc/modules-load.d/virtualbox.conf
    echo "vboxvideo" >> /etc/modules-load.d/virtualbox.conf
    
    # Agregar usuario al grupo vboxsf para carpetas compartidas
    usermod -aG vboxsf $username
    usermod -aG vboxsf greetd
    
    echo "VirtualBox Guest Additions instalado correctamente"
fi

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

# Crear archivo de configuración de neofetch
mkdir -p /home/$username/.config/neofetch
cat <<EOT > /home/$username/.config/neofetch/config.conf
# Configuración de neofetch
print_info() {
    info title
    info underline

    info "OS" distro
    info "Host" model
    info "Kernel" kernel
    info "Uptime" uptime
    info "Packages" packages
    info "Shell" shell
    info "Resolution" resolution
    info "DE" de
    info "WM" wm
    info "WM Theme" wm_theme
    info "Theme" theme
    info "Icons" icons
    info "Terminal" terminal
    info "Terminal Font" term_font
    info "CPU" cpu
    info "GPU" gpu
    info "Memory" memory

    info cols
}

# Mostrar logo de Arch
image_source="\${HOME}/.config/neofetch/arch_logo.txt"

# Colors
colors=(1 2 3 4 5 6)
EOT

# Crear logo ASCII de Arch
cat <<EOT > /home/$username/.config/neofetch/arch_logo.txt
                   -`
                  .o+`
                 `ooo/
                `+oooo:
               `+oooooo:
               -+oooooo+:
             `/:-:+oooooo+`
            `/++++/+++++++`
           `/++++++++++++++`
          `/+++ooooooooooooo/`
         ./ooosssso++osssssso+`
        .oossssso-````/ossssss+`
       -osssssso.      :ssssssso.
      :osssssss/        osssso+++.
     /ossssssss/        +ssssooo/-
   `/ossssso+/:-        -:/+osssso+-
  `+sso+:-`                 `.-/+oso:
 `++:.                           `-/+/
 .`                                 `/
EOT

# Configurar neofetch para que se ejecute al iniciar terminal
echo "neofetch" >> /home/$username/.bashrc

chown -R $username:$username /home/$username
EOF

# ==========================
# 8. Mostrar información del sistema antes de reiniciar
# ==========================
echo ""
echo "================================================"
echo "           INSTALACIÓN COMPLETADA"
echo "================================================"
echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║                INFORMACIÓN DEL SISTEMA       ║"
echo "╠══════════════════════════════════════════════╣"
echo "║  Usuario:        $username"
echo "║  Hostname:       Arch-$username"
echo "║  Kernel:         Linux Zen (mejor rendimiento)"
echo "║  Desktop:        Hyprland (Wayland)"
echo "║  Terminal:       Kitty"
echo "║  Login Manager:  Greetd + Tuigreet"
echo "║  Audio:          PipeWire"
echo "╚══════════════════════════════════════════════╝"
echo ""

# Mostrar neofetch del sistema instalado (simulado)
echo "╔══════════════════════════════════════════════╗"
echo "║               NEOFETCH PREVIEW               ║"
echo "╠══════════════════════════════════════════════╣"
echo "        ██████████████████████████████         "
echo "        ██████████████████████████████         "
echo "        ██████████████████████████████         "
echo "        ██████████████████████████████         "
echo "        ██████████████████████████████         "
echo "        ██████████████████████████████         "
echo "██████████████████████████████████████████████"
echo "██████████████████████████████████████████████"
echo "██████████████████████████████████████████████"
echo "        ██████████████████████████████         "
echo "        ██████████████████████████████         "
echo "        ██████████████████████████████         "
echo "        ██████████████████████████████         "
echo "        ██████████████████████████████         "
echo "        ██████████████████████████████         "
echo ""
echo "OS: Arch Linux x86_64"
echo "Host: Arch-$username"
echo "Kernel: linux-zen"
echo "DE: Hyprland"
echo "WM: Hyprland"
echo "Terminal: kitty"
echo "CPU: Virtual CPU"
echo "Memory: 1024MiB / 2048MiB"
echo "╚══════════════════════════════════════════════╝"
echo ""

# Verificar si es VirtualBox y mostrar info
if dmesg | grep -i "virtualbox" > /dev/null 2>&1; then
    echo "✅ VirtualBox Guest Additions instalado:"
    echo "   - Carpetas compartidas habilitadas"
    echo "   - Integración de mouse"
    echo "   - Portapapeles compartido"
    echo "   - Gráficos mejorados"
    echo ""
fi

echo "📦 Paquetes instalados:"
echo "   - Hyprland (Wayland compositor)"
echo "   - Kitty (terminal)"
echo "   - Wofi (launcher)"
echo "   - PipeWire (audio)"
echo "   - Neofetch (info del sistema)"
echo "   - VirtualBox Guest Utils (si aplica)"
echo ""

echo "🚀 El sistema se reiniciará en 10 segundos..."
echo "   Después del reinicio, inicia sesión con:"
echo "   Usuario: $username"
echo "   Contraseña: [la que estableciste]"
echo ""

for i in {10..1}; do
    echo -n "⏰ Reiniciando en $i segundos...\r"
    sleep 1
done

echo ""
echo "🔄 Reiniciando sistema..."
sleep 2

# ==========================
# 9. Reinicio
# ==========================
umount -R /mnt
reboot
