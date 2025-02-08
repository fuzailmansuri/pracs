#!/bin/bash

set -e  # Exit on error

DISK="/dev/nvme0n1"  # Change if using another disk
HOSTNAME="archlinux"
USERNAME="fuzail"
PASSWORD="archlinux"

echo -e "\n>>> Wiping disk and creating partitions..."
sgdisk -Z $DISK
sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI" $DISK
sgdisk -n 2:0:0 -t 2:8300 -c 2:"Root" $DISK

echo -e "\n>>> Formatting partitions..."
mkfs.fat -F32 ${DISK}p1
mkfs.ext4 ${DISK}p2

echo -e "\n>>> Mounting partitions..."
mount ${DISK}p2 /mnt
mkdir -p /mnt/boot
mount ${DISK}p1 /mnt/boot

echo -e "\n>>> Installing base system..."
pacstrap /mnt base linux linux-firmware

echo -e "\n>>> Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

echo -e "\n>>> Entering chroot..."
arch-chroot /mnt /bin/bash <<EOF

echo -e "\n>>> Setting timezone and locale..."
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo -e "\n>>> Setting hostname..."
echo "$HOSTNAME" > /etc/hostname

echo -e "\n>>> Installing essential packages..."
pacman -S --noconfirm networkmanager sudo grub efibootmgr

echo -e "\n>>> Setting up users..."
echo "root:$PASSWORD" | chpasswd
useradd -m -G wheel -s /bin/bash $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel

echo -e "\n>>> Installing GRUB..."
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch
grub-mkconfig -o /boot/grub/grub.cfg

echo -e "\n>>> Enabling services..."
systemctl enable NetworkManager

EOF

echo -e "\n>>> Installation complete. Reboot now."
