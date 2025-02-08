#!/bin/bash

set -e

# Set variables
DISK="/dev/nvme0n1"  # Your main disk
HOSTNAME="archlinux"
USERNAME="fuzailmansuri"
PASSWORD="f"
LOCALE="en_US.UTF-8"
TIMEZONE="Asia/Kolkata"  # Change if needed
SCALING="1.25"  # Default UI scaling (Windows/Fedora-like)

# Wipe disk (⚠️ This erases all data!)
echo -e "\n>>> Wiping disk and setting up partitions..."
wipefs -af $DISK
sgdisk -Z $DISK
sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI" $DISK
sgdisk -n 2:0:0 -t 2:8300 -c 2:"Root" $DISK

# Format partitions
mkfs.fat -F32 ${DISK}p1
mkfs.ext4 ${DISK}p2

# Mount filesystems
mount ${DISK}p2 /mnt
mkdir -p /mnt/boot/efi
mount ${DISK}p1 /mnt/boot/efi

# Install base system
echo -e "\n>>> Installing base system..."
pacstrap /mnt base linux linux-firmware nano networkmanager git base-devel bluez bluez-utils 

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot into new system
echo -e "\n>>> Configuring system..."
arch-chroot /mnt /bin/bash <<EOF
set -e

# Set timezone
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Set locale
echo "$LOCALE UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf

# Set hostname
echo "$HOSTNAME" > /etc/hostname

# Set root password
echo "root:$PASSWORD" | chpasswd

# Create user
useradd -m -G wheel -s /bin/bash $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Enable essential services
systemctl enable NetworkManager
systemctl enable bluetooth

# Install bootloader
pacman -Sy grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Install Hyprland & Essentials
echo -e "\n>>> Installing Hyprland & essential packages..."
pacman -Syu --noconfirm hyprland waybar dunst alacritty rofi wofi nwg-look \
  qt5ct qt6ct mako grim slurp wl-clipboard playerctl swappy swww brightnessctl \
  xdg-user-dirs pipewire pipewire-pulse wireplumber pavucontrol polkit-kde-agent \
  network-manager-applet gvfs xdg-utils ntfs-3g unzip unrar p7zip firefox \
  thunar thunar-archive-plugin thunar-volman vlc libreoffice-fresh gimp flameshot \
  ttf-inter

# Set Inter as system-wide font
mkdir -p /etc/fonts/local.conf.d
echo '<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <match target="pattern">
    <test name="family"><string>sans-serif</string></test>
    <edit name="family" mode="assign" binding="strong">
      <string>Inter</string>
    </edit>
  </match>
  <match target="pattern">
    <test name="family"><string>serif</string></test>
    <edit name="family" mode="assign" binding="strong">
      <string>Inter</string>
    </edit>
  </match>
  <match target="pattern">
    <test name="family"><string>monospace</string></test>
    <edit name="family" mode="assign" binding="strong">
      <string>Inter</string>
    </edit>
  </match>
</fontconfig>' > /etc/fonts/local.conf.d/99-inter-font.conf

# Install yay (AUR helper)
echo -e "\n>>> Installing yay..."
pacman -S --needed --noconfirm base-devel
git clone https://aur.archlinux.org/yay.git /home/$USERNAME/yay
chown -R $USERNAME:$USERNAME /home/$USERNAME/yay
su - $USERNAME -c "cd ~/yay && makepkg -si --noconfirm"

# Install extra AUR packages
su - $USERNAME -c "yay -S --noconfirm grimblast-git hyprpaper ttf-jetbrains-mono-nerd \
  ttf-nerd-fonts-symbols noto-fonts-cjk papirus-icon-theme"

# Clone Hyprland Material You Theme
su - $USERNAME -c "git clone https://github.com/koeqaife/hyprland-material-you.git ~/.config/hyprland-material-you"
su - $USERNAME -c "mv ~/.config/hyprland-material-you/* ~/.config/"
su - $USERNAME -c "rm -rf ~/.config/hyprland-material-you"

# Make scripts executable
su - $USERNAME -c "chmod +x ~/.config/hypr/waybar/scripts/*"

# Set default scaling to 1.25x
echo "XCURSOR_SIZE=32" >> /etc/environment
echo "QT_SCALE_FACTOR=$SCALING" >> /etc/environment
echo "GDK_SCALE=$SCALING" >> /etc/environment
echo "WLR_DPI=$(echo 96*$SCALING | bc)" >> /etc/environment

# Auto-start Hyprland
echo 'if [[ -z \$DISPLAY ]] && [[ \$(tty) == /dev/tty1 ]]; then exec Hyprland; fi' >> /home/$USERNAME/.bash_profile

EOF

# Unmount and reboot
umount -R /mnt
echo -e "\n>>> Installation complete! Rebooting..."
reboot
