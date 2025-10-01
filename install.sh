#!/bin/bash
# Instalación base de Arch Linux con Kernel Zen para Laptop (Clean Install)
# ⚠️ BORRA COMPLETAMENTE el disco especificado en la variable DISK ⚠️

set -e

# --- 1. Variables de Configuración ---
# MODIFICA ESTO: Usa /dev/nvme0n1 para SSD NVMe o /dev/sda para SATA
DISK="/dev/sda" 
HOSTNAME="ideapad-arch"
LOCALE="es_MX.UTF-8"
KEYMAP="la-latin1"
TIMEZONE="America/Mexico_City"

# --- 2. Solicitud de credenciales (Interactivo) ---
echo "--- Configuración de credenciales ---"
read -rp "Introduce el nombre de usuario que quieres crear: " USERNAME
read -srp "Introduce la contraseña para $USERNAME y root: " PASSWORD
echo ""

# --- 3. Particionado y Formateo ---
echo ">>> 1. Creando particiones GPT y formateando disco: $DISK ..."

# Crear tabla de particiones GPT
parted $DISK mklabel gpt
# Partición ESP (EFI System Partition) de 512MiB (Para GRUB y Windows Boot Manager)
parted $DISK mkpart primary fat32 1MiB 513MiB
parted $DISK set 1 esp on
# Partición principal EXT4 (el resto del disco, será la partición raíz /)
parted $DISK mkpart primary ext4 513MiB 100%

echo ">>> 2. Creando sistemas de archivos..."
# Formatear partición EFI
mkfs.fat -F32 ${DISK}1
# Formatear partición principal
mkfs.ext4 -F ${DISK}2

echo ">>> 3. Montando particiones..."
# Montar partición principal
mount ${DISK}2 /mnt
# Crear y montar punto de montaje para boot/efi
mkdir -p /mnt/boot/efi
mount ${DISK}1 /mnt/boot/efi

# --- 4. Instalación de Paquetes Base ---
echo ">>> 4. Instalando sistema base con kernel Linux Zen y utilidades esenciales..."
pacstrap /mnt base linux-zen linux-zen-headers linux-firmware base-devel \
vim nano networkmanager grub efibootmgr sudo git xdg-user-dirs polkit

echo ">>> 5. Generando fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# --- 6. Configuración dentro de chroot ---
echo ">>> 6. Configurando sistema (chroot)..."
arch-chroot /mnt /bin/bash <<EOF
# Zona horaria y reloj
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Localización e idioma
echo "$LOCALE UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

# Nombre de host (hostname)
echo "$HOSTNAME" > /etc/hostname
cat <<EOT >> /etc/hosts
127.0.0.1      localhost
::1            localhost
127.0.1.1      $HOSTNAME.localdomain $HOSTNAME
EOT

# Contraseña de root y usuario
echo "root:$PASSWORD" | chpasswd
useradd -m -G wheel -s /bin/bash $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd
# Configurar sudo para el grupo wheel
echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel

# Reconstruir initramfs (por la instalación de un kernel no-default)
mkinitcpio -P

# Activar servicios necesarios
systemctl enable NetworkManager 

# Instalar y configurar GRUB (para Dual Boot con Windows)
# Instala GRUB en modo EFI. Asume que la partición EFI es /mnt/boot/efi
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
# Configura GRUB. La configuración estándar detecta automáticamente Windows.
grub-mkconfig -o /boot/grub/grub.cfg
EOF

# --- 7. Finalización ---
echo ">>> 7. Desmontando particiones..."
umount -R /mnt

echo ">>> ✅ Instalación Arch Linux Base completada con Linux Zen."
echo ">>> Por favor, expulsa la ISO de instalación y luego reinicia con 'reboot'."
echo ">>> La instalación no incluye entorno de escritorio. Entrarás a la TTY (terminal)."
