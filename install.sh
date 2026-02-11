#!/bin/bash
# INSTALACIÓN AUTOMÁTICA ARCH LINUX (VIRTUALBOX + INTEL)
# ⚠️ ADVERTENCIA: ESTE SCRIPT BORRARÁ AUTOMÁTICAMENTE EL DISCO /dev/sda ⚠️

set -e

# --- 1. Variables Fijas ---
DISK="/dev/sda"
HOSTNAME="arch-natas"
LOCALE="es_MX.UTF-8"
KEYMAP="la-latin1"
TIMEZONE="America/Mexico_City"

# --- 2. Datos de Usuario (Único paso manual) ---
clear
echo "================================================="
echo "   INSTALADOR AUTOMÁTICO DE ARCH LINUX (VB)"
echo "================================================="
echo "El disco $DISK será formateado automáticamente:"
echo " -> Partición 1: EFI (512 MB)"
echo " -> Partición 2: Raíz (Resto del disco)"
echo "-------------------------------------------------"

read -rp "Introduce el nombre de usuario a crear: " USERNAME
read -srp "Introduce la contraseña para $USERNAME y root: " PASSWORD
echo ""
echo ""
echo "⏳ Tienes 5 segundos para cancelar (Ctrl+C) antes de borrar el disco..."
sleep 5

# --- 3. Particionado Automático (La Magia) ---
echo ">>> 1. Particionando $DISK..."
# Zap-all limpia la tabla de particiones, clear crea una nueva
sgdisk --zap-all $DISK
sgdisk --clear $DISK

# Crear EFI (Partición 1, 512MB, HexCode ef00)
sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI System" $DISK

# Crear Raíz (Partición 2, Resto, HexCode 8300)
sgdisk -n 2:0:0 -t 2:8300 -c 2:"Linux Filesystem" $DISK

# Informar al kernel de los cambios
partprobe $DISK
sleep 2

# Definir las variables de partición automáticamente
EFI_PARTITION="${DISK}1"
ROOT_PARTITION="${DISK}2"

# --- 4. Formateo y Montaje ---
echo ">>> 2. Formateando particiones..."
mkfs.fat -F32 "$EFI_PARTITION"
mkfs.ext4 -F "$ROOT_PARTITION"

echo ">>> 3. Montando en /mnt..."
mount "$ROOT_PARTITION" /mnt
mkdir -p /mnt/boot/efi
mount "$EFI_PARTITION" /mnt/boot/efi

# --- 5. Instalación Base (Intel + VBox) ---
echo ">>> 4. Instalando paquetes (Kernel Zen + Drivers Intel/VBox)..."
# Se incluye 'intel-ucode' y drivers gráficos/utils de VirtualBox
pacstrap /mnt base linux-zen linux-zen-headers linux-firmware base-devel \
vim nano networkmanager grub efibootmgr sudo git xdg-user-dirs polkit os-prober \
virtualbox-guest-utils intel-ucode

echo ">>> 5. Generando fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# --- 6. Configuración del Sistema ---
echo ">>> 6. Configurando el sistema final..."
arch-chroot /mnt /bin/bash <<EOF
# Zona horaria y Reloj
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Idioma
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

# Usuarios
echo "root:$PASSWORD" | chpasswd
useradd -m -G wheel -s /bin/bash $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd
echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel

# Initramfs
mkinitcpio -P

# --- SERVICIOS CRÍTICOS ---
systemctl enable NetworkManager
systemctl enable vboxservice  # Importante para pantalla completa y clipboard

# GRUB
sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
EOF

# --- 7. Finalización ---
echo ">>> 7. Desmontando..."
umount -R /mnt
echo ""
echo "======================================================="
echo "   ✅ INSTALACIÓN COMPLETADA"
echo "======================================================="
echo "PASOS FINALES:"
echo "1. Apaga la máquina virtual (o cierra la ventana)."
echo "2. Ve a Configuración > Almacenamiento > Eliminar disco de la unidad virtual (Quitar la ISO)."
echo "3. Inicia de nuevo."
