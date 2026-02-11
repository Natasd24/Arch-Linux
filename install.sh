#!/bin/bash
# Instalación base de Arch Linux con Kernel Zen para VirtualBox (Intel)
# ⚠️ FORMATEA LAS PARTICIONES ESPECIFICADAS ⚠️

set -e

# --- 1. Variables de Configuración Fijas ---
HOSTNAME="arch-virtualbox"
LOCALE="es_MX.UTF-8"
KEYMAP="la-latin1"
TIMEZONE="America/Mexico_City"

# --- 2. Solicitud de Datos ---
clear
echo "================================================="
echo "   Asistente de Instalación de Arch Linux (VB)"
echo "================================================="
echo ""
echo "A continuación se muestran los discos y particiones disponibles:"
echo "----------------------------------------------------------------"
lsblk -f
echo "----------------------------------------------------------------"
echo ""
echo "Por favor, identifica tu partición EFI (FSTYPE 'vfat') y tu partición Raíz (FSTYPE 'ext4')."
echo "Introduce las rutas completas (ej. /dev/sda1 y /dev/sda2)."
echo ""

read -rp "Introduce la partición EFI: " EFI_PARTITION
read -rp "Introduce la partición Raíz (/): " ROOT_PARTITION
echo ""
read -rp "Introduce el nombre de usuario que quieres crear: " USERNAME
read -srp "Introduce la contraseña para $USERNAME y root: " PASSWORD
echo ""
echo ""

# --- 3. Formateo y Montaje ---
echo ">>> ¡¡¡ADVERTENCIA!!! Se borrarán los datos en:"
echo ">>> EFI:  $EFI_PARTITION"
echo ">>> Raíz: $ROOT_PARTITION"
read -rp "Escribe 'si' para confirmar y continuar: " CONFIRMACION
if [ "$CONFIRMACION" != "si" ]; then
    echo "Cancelado."
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
echo ">>> 3. Instalando sistema base (Intel + VirtualBox)..."
# Se añade 'intel-ucode' y 'xf86-video-vmware'
pacstrap /mnt base linux-zen linux-zen-headers linux-firmware base-devel \
vim nano networkmanager grub efibootmgr sudo git xdg-user-dirs polkit os-prober \
virtualbox-guest-utils xf86-video-vmware intel-ucode

echo ">>> 4. Generando fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# --- 5. Configuración del Sistema (Chroot) ---
echo ">>> 5. Configurando sistema interno..."
arch-chroot /mnt /bin/bash <<EOF
# Zona horaria
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Idioma y Teclado
echo "$LOCALE UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

# Hostname
echo "$HOSTNAME" > /etc/hostname
cat <<EOT >> /etc/hosts
127.0.0.1      localhost
::1            localhost
127.0.1.1      $HOSTNAME.localdomain $HOSTNAME
EOT

# Usuarios y Contraseñas
echo "root:$PASSWORD" | chpasswd
useradd -m -G wheel -s /bin/bash $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd
echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel

# Initramfs
mkinitcpio -P

# --- SERVICIOS CRÍTICOS (Aquí está la magia para VB) ---
systemctl enable NetworkManager
systemctl enable vboxservice

# Bootloader (GRUB EFI)
sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
EOF

# --- 6. Finalización ---
echo ">>> 6. Desmontando particiones..."
umount -R /mnt
echo ""
echo "======================================================="
echo "   ✅ INSTALACIÓN COMPLETADA EXITOSAMENTE"
echo "======================================================="
echo "IMPORTANTE:"
echo "1. Ve a Dispositivos > Unidades Ópticas > Eliminar disco."
echo "2. Ejecuta 'reboot' para reiniciar."
