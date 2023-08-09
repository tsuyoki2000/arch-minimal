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
#pacstrap -K /mnt base linux linux-firmware base-devel networkmanager intel-ucode vim
pacstrap -K /mnt base linux networkmanager intel-ucode vim

# fstab
genfstab -U /mnt >> /mnt/etc/fstab

# chroot
#arch-chroot /mnt

########################################
# ここで、止まってた（arch-chroot が原因）
########################################

# TimeZone
#ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
arch-chroot /mnt ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# Harcware Clock Setting
#hwclock --systohc
arch-chroot /mnt hwclock --systohc

# localization
#sed -i "s/#en_US.UTF-8/en_US.UTF-8/g" /etc/locale.gen
#sed -i "s/#ja_JP.UTF-8/ja_JP.UTF-8/g" /etc/locale.gen
arch-chroot /mnt sed -i "s/#en_US.UTF-8/en_US.UTF-8/g" /etc/locale.gen
arch-chroot /mnt sed -i "s/#ja_JP.UTF-8/ja_JP.UTF-8/g" /etc/locale.gen

# Create locale
#locale-gen
arch-chroot /mnt locale-gen

# Create locale.conf
#echo LANG=ja_JP.UTF-8 > /etc/locale.conf
arch-chroot /mnt echo LANG=ja_JP.UTF-8 > /etc/locale.conf

# Keymap Setting
#echo KEYMAP=jp106 > /etc/vconsole.conf
arch-chroot /mnt echo KEYMAP=jp106 > /etc/vconsole.conf



################################################################################
# Network Settings
################################################################################

# Hostname
#echo $HOST_NAME > /etc/hostname
arch-chroot /mnt echo $HOST_NAME > /etc/hostname

# Enable NetworkManager Service
#systemctl enable NetworkManager
arch-chroot /mnt systemctl enable NetworkManager



################################################################################
# Boot Loader
################################################################################
# Install MicroCode
#pacman -S intel-ucode
#arch-chroot /mnt pacman -S intel-ucode --noconfirm

# Install grub (for BIOS)
#pacman -S grub
#grub-install --target=i386-pc --recheck /dev/sda
arch-chroot /mnt pacman -S grub --noconfirm
arch-chroot /mnt grub-install --target=i386-pc --recheck /dev/sda

# Create GRUB-Setting-File
#grub-mkconfig -o /boot/grub/grub.cfg
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

################################################################################
# Root and User Settings
################################################################################
arch-chroot /mnt echo $ROOT_PASSWORD
arch-chroot /mnt echo $USER_NAME
arch-chroot /mnt echo $USER_PASSWORD

echo "Set Root Password"
# Set Root Password
#passwd << __EOF__
#$ROOT_PASSWORD
#$ROOT_PASSWORD
#__EOF__

########################################
# ここでエラーになっている（<< __EOF__ が問題か？）
########################################
arch-chroot /mnt passwd << __EOF__
$ROOT_PASSWORD
$ROOT_PASSWORD
__EOF__

echo "Create User"
# Create User
#useradd -m $USER_NAME
arch-chroot /mnt useradd -m $USER_NAME

echo "Set User Password"
# Set User Password
#passwd $USER_NAME << __EOF__
#$USER_PASSWORD
#$USER_PASSWORD
#__EOF__

arch-chroot /mnt passwd $USER_NAME << __EOF__
$USER_PASSWORD
$USER_PASSWORD
__EOF__

# Install sudo（インストール済み。ベースシステムインストール時か？）
#pacman -S sudo

echo "Add sudo permission for User"
# Add sudo permission for User
#sed -i "s/root ALL=(ALL:ALL) ALL/root ALL=(ALL:ALL) ALL\n$USER_NAME ALL=(ALL:ALL) ALL/g" /etc/sudoers
arch-chroot /mnt sed -i "s/root ALL=(ALL:ALL) ALL/root ALL=(ALL:ALL) ALL\n$USER_NAME ALL=(ALL:ALL) ALL/g" /etc/sudoers




################################################################################
# Shutdown
################################################################################
# Exit Root
#exit

# unmount
umount -R /mnt

# Shutdown
echo Type poweroff
