#!/bin/bash

set -e  # Exit on error

# Update system
sudo pacman -Syu --noconfirm

# Install essential packages
sudo pacman -S --noconfirm \
    networkmanager wpa_supplicant wireless_tools iwd dhclient \
    bluez bluez-utils \
    pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber \
    xdg-user-dirs xdg-utils \
    mesa vulkan-intel \
    git curl wget unzip zip tar \
    nano vim neofetch htop \
    sudo

# Enable services
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth

# Install Hyprland and dependencies
sudo pacman -S --noconfirm \
    hyprland waybar rofi dunst alacritty \
    thunar thunar-volman tumbler gvfs \
    polkit-gnome xdg-desktop-portal-hyprland \
    firefox

# Set default scaling to 1.25x
echo "Xft.dpi: 120" > ~/.Xresources
echo "export GDK_SCALE=1.25" >> ~/.bashrc
echo "export QT_SCALE_FACTOR=1.25" >> ~/.bashrc

# Set up Hyprland Material You theme
git clone https://github.com/koeqaife/hyprland-material-you.git ~/.config/hypr

# Install SDDM (GUI login)
sudo pacman -S --noconfirm sddm qt5-graphicaleffects qt5-svg
sudo systemctl enable --now sddm

echo "Setup complete! Reboot your system."
