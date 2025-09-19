#!/bin/bash
set -e

# =======================================
# 1. Configuración inicial
# =======================================
echo "🔹 Configurando teclado y hora..."
loadkeys es || { echo "❌ Error: No se pudo cargar el teclado"; exit 1; }
timedatectl set-ntp true || { echo "❌ Error: No se pudo activar NTP"; exit 1; }

# =======================================
# 2. Particionado y formateo
# =======================================
echo "🔹 Particionando disco /dev/sda..."
parted /dev/sda --script mklabel gpt \
    mkpart ESP fat32 1MiB 513MiB set 1 boot on \
    mkpart primary ext4 513MiB 100% || { echo "❌ Error: Particionado fallido"; exit 1; }

echo "🔹 Formateando particiones..."
mkfs.fat -F32 /dev/sda1 || { echo "❌ Error: Formateo de /dev/sda1 falló"; exit 1; }
mkfs.ext4 /dev/sda2 || { echo "❌ Error: Formateo de /dev/sda2 falló"; exit 1; }

echo "🔹 Montando particiones..."
mount /dev/sda2 /mnt || { echo "❌ Error: No se pudo montar /dev/sda2"; exit 1; }
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot || { echo "❌ Error: No se pudo montar /dev/sda1"; exit 1; }

# =======================================
# 3. Instalación base (con kernel Zen)
# =======================================
echo "🔹 Instalando sistema base y kernel Zen..."
pacstrap /mnt base linux-zen linux-zen-headers linux-firmware \
    vim sudo networkmanager git || { echo "❌ Error: pacstrap falló"; exit 1; }

echo "🔹 Generando fstab..."
genfstab -U /mnt >> /mnt/etc/fstab || { echo "❌ Error: genfstab falló"; exit 1; }

# =======================================
# 4. Configuración del sistema
# =======================================
echo "🔹 Configurando sistema dentro de chroot..."
arch-chroot /mnt /bin/bash <<'EOF'
set -e

echo "🔹 Configurando zona horaria y reloj..."
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc

echo "🔹 Configurando locales..."
echo "es_MX.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=es_MX.UTF-8" > /etc/locale.conf
echo "KEYMAP=es" > /etc/vconsole.conf

echo "🔹 Configurando hostname y hosts..."
echo "arch-zen" > /etc/hostname
cat <<EOT > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   arch-zen.localdomain arch-zen
EOT

echo "🔹 Creando usuario y configurando sudo..."
useradd -m -G wheel -s /bin/bash arch
echo "arch:arch" | chpasswd
echo "root:root" | chpasswd
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

echo "🔹 Habilitando NetworkManager..."
systemctl enable NetworkManager

echo "🔹 Instalando y configurando GRUB..."
pacman -Sy --noconfirm grub efibootmgr || { echo "❌ Error: instalación de GRUB falló"; exit 1; }
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB || { echo "❌ Error: grub-install falló"; exit 1; }
grub-mkconfig -o /boot/grub/grub.cfg || { echo "❌ Error: grub-mkconfig falló"; exit 1; }

EOF

# =======================================
# 5. Finalización
# =======================================
echo "🔹 Desmontando particiones..."
umount -R /mnt || { echo "❌ Error: No se pudo desmontar /mnt"; exit 1; }

echo "✅ Instalación base con Linux Zen completada."
echo "🔹 Reinicia la máquina, quita el ISO y luego ejecuta el script post-reboot si lo tienes."
