set -e

# =======================================
# 1. Configuración inicial
# =======================================
loadkeys es
timedatectl set-ntp true

# =======================================
# 2. Particionado y formateo
# =======================================
# Limpiar disco y crear tabla de particiones GPT
# Limpiar el disco antes de crear una nueva tabla de particiones
dd if=/dev/zero of=/dev/sda bs=512 count=1 conv=notrunc
parted /dev/sda --script mklabel gpt

# Crear partición de booteo (EFI) de 512MiB
parted /dev/sda --script mkpart primary fat32 1MiB 513MiB
parted /dev/sda --script set 1 esp on
# Crear partición principal (root)
parted /dev/sda --script mkpart primary ext4 513MiB 100%

# Formatear particiones
mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda2

# Montar particiones
mount /dev/sda2 /mnt
mkdir -p /mnt/boot/efi
mount /dev/sda1 /mnt/boot/efi

# =======================================
# 3. Instalación base (con kernel Zen)
# =======================================
pacstrap /mnt base linux-zen linux-zen-headers linux-firmware \
    vim sudo networkmanager git grub efibootmgr

genfstab -U /mnt >> /mnt/etc/fstab

# =======================================
# 4. Configuración del sistema (dentro del chroot)
# =======================================
arch-chroot /mnt /bin/bash <<EOF
# Zona horaria (ejemplo para México)
ln -sf /usr/share/zoneinfo/America/Mexico_City /etc/localtime
hwclock --systohc

# Localización
sed -i 's/#es_MX.UTF-8 UTF-8/es_MX.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=es_MX.UTF-8" > /etc/locale.conf
echo "KEYMAP=es" > /etc/vconsole.conf

# Hostname
echo "arch-zen" > /etc/hostname
cat <<EOT > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   arch-zen.localdomain arch-zen
EOT

# Contraseña de root y creación de usuario
echo "root:password_root" | chpasswd
useradd -m -G wheel -s /bin/bash arch
echo "arch:password_user" | chpasswd
# Descomentar la línea para sudoers
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Red
systemctl enable NetworkManager

# Bootloader (GRUB)
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

EOF

umount -R /mnt
echo "✅ Instalación base con Linux Zen completada. Reinicia, quita el ISO y luego ejecuta el script post-reboot."
