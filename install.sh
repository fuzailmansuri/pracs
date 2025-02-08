#!/bin/bash

# Exit on error and display commands being executed
set -e
set -x

# Configuration
DISK="/dev/nvme0n1"  # Change if using another disk
HOSTNAME="archlinux"
USERNAME="fuzail"
PASSWORD="archlinux"
TIMEZONE="Asia/Kolkata"

# Verify running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" 
    exit 1
fi

# Verify boot mode is UEFI
if [ ! -d "/sys/firmware/efi/efivars" ]; then
    echo "Not booted in UEFI mode. Please enable UEFI boot."
    exit 1
fi

# Verify internet connection
if ! ping -c 1 archlinux.org >/dev/null 2>&1; then
    echo "No internet connection. Please connect to the internet first."
    exit 1
fi

echo -e "\n>>> Updating system clock..."
timedatectl set-ntp true

echo -e "\n>>> Wiping disk and creating partitions..."
sgdisk -Z $DISK
sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI" $DISK
sgdisk -n 2:0:0 -t 2:8300 -c 2:"Root" $DISK

echo -e "\n>>> Formatting partitions..."
mkfs.fat -F32 ${DISK}p1
mkfs.ext4 -F ${DISK}p2

echo -e "\n>>> Mounting partitions..."
mount ${DISK}p2 /mnt
mkdir -p /mnt/boot
mount ${DISK}p1 /mnt/boot

echo -e "\n>>> Installing base system..."
pacstrap /mnt base base-devel linux linux-firmware \
    vim nano git \
    intel-ucode   # Replace with amd-ucode if using AMD processor

echo -e "\n>>> Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

echo -e "\n>>> Entering chroot..."
arch-chroot /mnt /bin/bash <<EOF
echo -e "\n>>> Setting timezone and locale..."
ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo -e "\n>>> Setting hostname..."
echo "$HOSTNAME" > /etc/hostname
cat > /etc/hosts <<END
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}
END

echo -e "\n>>> Installing essential packages..."
pacman -S --noconfirm \
    networkmanager \
    sudo \
    grub \
    efibootmgr \
    os-prober \
    hyprland \
    waybar \
    kitty \
    wofi \
    xdg-desktop-portal-hyprland \
    polkit-gnome \
    gnome-keyring \
    network-manager-applet \
    grim \
    slurp \
    pipewire \
    pipewire-pulse \
    wireplumber \
    brightnessctl \
    bluez \
    bluez-utils \
    firefox \
    qt5-wayland \
    qt6-wayland \
    gtk3 \
    mako \
    thunar \
    ttf-jetbrains-mono-nerd \
    noto-fonts \
    noto-fonts-emoji \
    adobe-source-code-pro-fonts \
    xdg-user-dirs

echo -e "\n>>> Setting up users..."
echo "root:${PASSWORD}" | chpasswd
useradd -m -G wheel,audio,video,input -s /bin/bash ${USERNAME}
echo "${USERNAME}:${PASSWORD}" | chpasswd
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel

echo -e "\n>>> Installing GRUB..."
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch
grub-mkconfig -o /boot/grub/grub.cfg

echo -e "\n>>> Enabling services..."
systemctl enable NetworkManager
systemctl enable bluetooth
EOF

echo -e "\n>>> Installation complete. You can now:"
echo "1. Exit chroot environment (if not already)"
echo "2. Unmount partitions: umount -R /mnt"
echo "3. Reboot: reboot"
