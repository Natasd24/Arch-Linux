#!/bin/bash
# Instalación base de Arch Linux con Kernel Zen para una PARTICIÓN existente.
# ⚠️ FORMATEA LAS PARTICIONES ESPECIFICADAS ⚠️
# Versión mejorada: Muestra las particiones automáticamente antes de preguntar.

set -e

# --- 1. Variables de Configuración Fijas ---
HOSTNAME="ideapad-arch"
LOCALE="es_MX.UTF-8"
KEYMAP="la-latin1"
TIMEZONE="America/Mexico_City"

# --- 2. Solicitud de Datos (Interactivo y Mejorado) ---
clear
echo "================================================="
echo "   Asistente de Instalación de Arch Linux"
echo "================================================="
echo ""
echo "A continuación se muestran los discos y particiones disponibles:"
echo "----------------------------------------------------------------"
lsblk -f
echo "----------------------------------------------------------------"
echo ""
echo "Por favor, identifica tu partición EFI (FSTYPE 'vfat') y tu partición Raíz (FSTYPE 'ext4')."
echo "Introduce las rutas completas (ej. /dev/sda1 o /dev/nvme0n1p1)."
echo ""

read -rp "Introduce la partición EFI: " EFI_PARTITION
read -rp "Introduce la partición Raíz (/): " ROOT_PARTITION
echo ""
read -rp "Introduce el nombre de usuario que quieres crear: " USERNAME
read -srp "Introduce la contraseña para $USERNAME y root: " PASSWORD
echo ""
echo ""

# --- 3. Formateo y Montaje con Confirmación ---
echo ">>> ¡¡¡ADVERTENCIA!!! Se formatearán las siguientes particiones:"
echo ">>> EFI:  $EFI_PARTITION"
echo ">>> Raíz: $ROOT_PARTITION"
echo ">>> TODO EL CONTENIDO EN ELLAS SERÁ ELIMINADO."
read -rp "Para confirmar esta acción, escribe 'si' y presiona Enter: " CONFIRMACION
if [ "$CONFIRMACION" != "si" ]; then
    echo "Instalación cancelada por el usuario."
    exit 1
fi

echo ">>> 1. Creando sistemas de archivos..."
mkfs.fat -F32 "$EFI_PARTITION"
mkfs.ext4 -F "$ROOT_PARTITION"

echo ">>> 2. Montando particiones..."
mount "$ROOT_PARTITION" /mnt
mkdir -p /mnt/boot/efi
mount "$EFI_PARTITION" /mnt/boot/efi

# --- 4. Instalación de Paquetes Base ---
echo ">>> 3. Instalando sistema base con kernel Linux Zen y utilidades esenciales..."
pacstrap /mnt base linux-zen linux-zen-headers linux-firmware base-devel \
vim nano networkmanager grub efibootmgr sudo git xdg-user-dirs polkit os-prober \
virtualbox-guest-utils amd-ucode

echo ">>> 4. Generando fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# --- 5. Configuración dentro de chroot ---
echo ">>> 5. Configurando sistema (chroot)..."
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

# Reconstruir initramfs
mkinitcpio -P

# Activar servicios necesarios
systemctl enable NetworkManager

# Instalar y configurar GRUB para Dual Boot
sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
EOF

# --- 6. Finalización ---
echo ">>> 6. Desmontando particiones..."
umount -R /mnt
echo ""
echo ">>> ✅ Instalación Arch Linux Base completada."
echo ">>> Por favor, expulsa la ISO de instalación y luego reinicia con 'reboot'."
echo ">>> Al reiniciar, deberías ver el menú de GRUB con opciones para Arch y otros SO."
