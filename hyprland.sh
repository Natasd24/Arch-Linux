#!/bin/bash
# Script para instalar Hyprland + entorno mínimo en Arch Linux

set -e

echo "=== Actualizando sistema ==="
sudo pacman -Syu --noconfirm

echo "=== Instalando Hyprland y portal ==="
sudo pacman -S --noconfirm hyprland xdg-desktop-portal-hyprland

echo "=== Instalando barra, lanzador y terminal ==="
sudo pacman -S --noconfirm waybar wofi kitty

echo "=== Instalando sonido (PipeWire + WirePlumber) ==="
sudo pacman -S --noconfirm pipewire pipewire-pulse pipewire-alsa wireplumber

echo "=== Instalando fuente JetBrains Mono Nerd ==="
sudo pacman -S --noconfirm ttf-jetbrains-mono-nerd

echo "=== Instalando Polkit (agente GNOME) ==="
sudo pacman -S --noconfirm polkit-gnome

echo "=== Instalando applet de red ==="
sudo pacman -S --noconfirm network-manager-applet networkmanager

echo "=== Instalando xdg-user-dirs ==="
sudo pacman -S --noconfirm xdg-user-dirs

echo "=== Habilitando servicios ==="
sudo systemctl enable --now NetworkManager.service
systemctl --user enable --now pipewire pipewire-pulse wireplumber

echo "=== Creando directorios de usuario ==="
xdg-user-dirs-update

echo "=== Instalación completada con éxito 🎉 ==="
echo "Recuerda: Inicia sesión en Hyprland desde tu gestor de sesiones o con 'Hyprland' desde TTY."
