#!/bin/bash

# Exit on error
set -e

# Define user
USER_NAME="fuzail"  # Change if needed

echo "Updating system and installing required packages..."
pacman -Sy --noconfirm hyprland xorg-xwayland xorg-xinit sddm \
  waybar rofi kitty neofetch network-manager-applet \
  pipewire pipewire-pulse wireplumber pulseaudio-bluetooth \
  git neovim ttf-inter

# Enable SDDM
echo "Enabling SDDM..."
systemctl enable sddm

# Set up .xinitrc for Hyprland
echo "Setting up .xinitrc..."
echo "exec Hyprland" > /home/$USER_NAME/.xinitrc
chmod +x /home/$USER_NAME/.xinitrc
chown $USER_NAME:$USER_NAME /home/$USER_NAME/.xinitrc

# Install dotfiles
echo "Setting up dotfiles..."
git clone https://github.com/fuzailmansuri/dotfiles /home/$USER_NAME/.config
chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.config

# Set 1.25x scaling
echo "Applying 1.25x scaling..."
echo "Xft.dpi: 120" >> /home/$USER_NAME/.Xresources
chown $USER_NAME:$USER_NAME /home/$USER_NAME/.Xresources

# Enable NetworkManager
echo "Enabling NetworkManager..."
systemctl enable NetworkManager

echo "Installation complete. Reboot now."
