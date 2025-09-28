# Instalación automática de Arch Linux en VirtualBox (Linux Zen)
# ⚠️ BORRA COMPLETAMENTE /dev/sda ⚠️

set -e

# Variables de Configuración
DISK="/dev/sda"
HOSTNAME="arch" # Nombre de la máquina
USERNAME="arch" # Nombre del usuario normal
PASSWORD="arch" # Contraseña para root y usuario normal
LOCALE="es_MX.UTF-8" # Configuración regional
KEYMAP="la-latin1" # Mapa de teclado
TIMEZONE="America/Mexico_City" # Zona horaria

echo ">>> Formateando disco: $DISK..."
# Crear tabla de particiones GPT
parted $DISK mklabel gpt
# Partición ESP (EFI System Partition) de 300MiB
parted $DISK mkpart ESP fat32 1MiB 301MiB
parted $DISK set 1 boot on
# Partición principal ext4 (el resto del disco)
parted $DISK mkpart primary ext4 301MiB 100%

echo ">>> Creando sistemas de archivos..."
# Formatear partición EFI
mkfs.fat -F32 ${DISK}1
# Formatear partición principal
mkfs.ext4 -F ${DISK}2

echo ">>> Montando particiones..."
# Montar partición principal
mount ${DISK}2 /mnt
# Crear y montar punto de montaje para boot/efi
mkdir -p /mnt/boot
mount ${DISK}1 /mnt/boot

echo ">>> Instalando sistema base con kernel Linux Zen y utilidades de VirtualBox..."
pacstrap /mnt base linux-zen linux-zen-headers linux-firmware base-devel \
vim nano networkmanager grub efibootmgr sudo git \
xdg-user-dirs virtualbox-guest-utils

echo ">>> Generando fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

echo ">>> Configurando sistema dentro de chroot..."
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
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOT

# Contraseña de root
echo "root:$PASSWORD" | chpasswd

# Crear usuario normal con permisos de sudo (grupo wheel)
useradd -m -G wheel -s /bin/bash $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd
# Configurar sudo para el grupo wheel (permite a los usuarios de wheel ejecutar cualquier comando)
echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel

# Activar servicios necesarios
systemctl enable NetworkManager # Gestor de red
systemctl enable vboxservice # Servicios de VirtualBox Guest (para carpetas compartidas, etc.)

# Instalar y configurar GRUB (para arranque EFI)
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
EOF

echo ">>> ✅ Instalación completada con Linux Zen."
echo ">>> Por favor, desmonta las particiones con 'umount -R /mnt', expulsa la ISO y luego reinicia con 'reboot'."
echo ">>> Usuario: $USERNAME | Contraseña: $PASSWORD"
