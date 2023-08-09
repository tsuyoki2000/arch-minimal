#! /bin/sh

################################################################################
# Setting
################################################################################
INSTALL_DEVICE=/dev/sda
HOST_NAME=arch
ROOT_PASSWORD=tsuyoki
USER_NAME=tsuyoki
USER_PASSWORD=tsuyoki


loadkeys jp106

################################################################################
# Create Partitions
################################################################################

# FDISK
fdisk $INSTALL_DEVICE << __EOF__
o

n
p
1

+512M

n
p
2


w
__EOF__

# Format Disks
mkfs.fat -F 32 ${INSTALL_DEVICE}1
mkfs.ext4 ${INSTALL_DEVICE}2

# Mount Disks
mount ${INSTALL_DEVICE}2 /mnt
mount --mkdir ${INSTALL_DEVICE}1 /mnt/boot

################################################################################
# System Insall
################################################################################

########################################
# Select Mirror
reflector -country 'Japan' --sort rate -save /etc/pacman.d/mirrorlist

#`/etc/pacman.d/mirrorlist`
#手動で以下を追加しても良いかも？
#echo Server = https://ftp.jaist.ac.jp/pub/Linux/ArchLinux/\$repo/os/\$arch > /etc/pacman.d/mirrorlist
#$ は特殊文字なので、echo内で使用する場合は、バックスラッシュを使う
#文頭に追加するにはどうするんだ？
########################################

# Base Package
pacstrap -K /mnt base linux linux-firmware base-devel networkmanager vim

# fstab
genfstab -U /mnt >> /mnt/etc/fstab

# chroot
#arch-chroot /mnt

########################################
# ここで、止まる
########################################

# TimeZone
#ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
arch-chroot /mnt ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# Harcware Clock Setting
hwclock --systohc

# localization
sed -i "s/#en_US.UTF-8/en_US.UTF-8/g" /etc/locale.gen
sed -i "s/#ja_JP.UTF-8/ja_JP.UTF-8/g" /etc/locale.gen

# Create locale
locale-gen

# Create locale.conf
#echo LANG=en_US.UTF-8 > /etc/locale.conf
echo LANG=ja_JP.UTF-8 > /etc/locale.conf

# Keymap Setting
echo KEYMAP=jp106 > /etc/vconsole.conf



################################################################################
# Network Settings
################################################################################

# Hostname
echo $HOST_NAME > /etc/hostname

# Enable NetworkManager Service
systemctl enable NetworkManager



################################################################################
# Boot Loader
################################################################################
# Install MicroCode
pacman -S intel-ucode

# Install grub (for BIOS)
pacman -S grub
grub-install --target=i386-pc --recheck /dev/sda

# Create GRUB-Setting-File
grub-mkconfig -o /boot/grub/grub.cfg

################################################################################
# Root and User Settings
################################################################################

# Set Root Password
passwd << __EOF__
$ROOT_PASSWORD
$ROOT_PASSWORD
__EOF__

# Create User
useradd -m $USER_NAME

# Set User Password
passwd $USER_NAME << __EOF__
$USER_PASSWORD
$USER_PASSWORD
__EOF__

# Install sudo（インストール済み。ベースシステムインストール時か？）
#pacman -S sudo

# Add sudo permission for User
sed -i "s/root ALL=(ALL:ALL) ALL/root ALL=(ALL:ALL) ALL\n$USER_NAME ALL=(ALL:ALL) ALL/g" /etc/sudoers

################################################################################
# Shutdown
################################################################################
# Exit Root
exit

# unmount
umount -R /mnt

# Shutdown
echo Type poweroff
