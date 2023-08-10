#! /bin/sh

################################################################################
# Setting
################################################################################
INSTALL_DEVICE=/dev/sda
HOST_NAME=arch
ROOT_PASSWORD=tsuyoki
USER_NAME=tsuyoki
USER_PASSWORD=tsuyoki

################################################################################
# function for comment
################################################################################
NORMAL=$(tput sgr0)
GREEN=$(tput setaf 2; tput bold)
function green() {
    echo -e "$GREEN$*$NORMAL"
}


################################################################################
# Create Partitions
################################################################################
green ""
green "Load Keymap..."
loadkeys jp106

green ""
green "FDISK..."

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

green ""
green "Format Disks..."
mkfs.fat -F32 ${INSTALL_DEVICE}1
mkfs.ext4 ${INSTALL_DEVICE}2

green ""
green "Mount Disks..."
mount ${INSTALL_DEVICE}2 /mnt
mount --mkdir ${INSTALL_DEVICE}1 /mnt/boot

################################################################################
# System Insall
################################################################################

#green ""
#green "Select Mirror..."
#reflector -country 'Japan' --sort rate -save /etc/pacman.d/mirrorlist
# エラーになる（無くても問題ないので、あとまわし）

# ↓拾ってきた
# Select a mirror
#cp /etc/pacman.d/mirrorlist /tmp0
#grep "\.jp" /tmp/mirrorlist > /etc/pacman.d/mirrorlist

green ""
green "Base Package..."
pacstrap -K /mnt base linux linux-firmware base-devel networkmanager intel-ucode


green ""
green "fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# chroot
#arch-chroot /mnt　<< __EOF__
#__EOF__

green ""
green "TimeZone..."
#ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
arch-chroot /mnt ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

green ""
green "Harcware Clock Setting..."
#hwclock --systohc
arch-chroot /mnt hwclock --systohc

green ""
green "Localization..."
#sed -i "s/#en_US.UTF-8/en_US.UTF-8/g" /etc/locale.gen
#sed -i "s/#ja_JP.UTF-8/ja_JP.UTF-8/g" /etc/locale.gen
arch-chroot /mnt sed -i "s/#en_US.UTF-8/en_US.UTF-8/g" /etc/locale.gen
arch-chroot /mnt sed -i "s/#ja_JP.UTF-8/ja_JP.UTF-8/g" /etc/locale.gen

green ""
green "Create locale..."

#locale-gen
arch-chroot /mnt locale-gen

#####################################
##### LANG="C.UTF-8" になっている #####
# リダイレクト（>）の処理が一般権限で実行されているらしい
#####################################
green ""
green "Edit locale.conf..."
#echo LANG=ja_JP.UTF-8 > /etc/locale.conf
#arch-chroot /mnt echo "LANG=ja_JP.UTF-8" > /etc/locale.conf（ダメだった）
#arch-chroot /mnt echo "LANG=ja_JP.UTF-8" | sudo tee /etc/locale.conf（ダメだった）
#sudo sh -c "arch-chroot /mnt echo LANG=ja_JP.UTF-8 > /etc/locale.conf"（ダメだった）
#sh -c "arch-chroot /mnt echo LANG=ja_JP.UTF-8 > /etc/locale.conf"（ダメだった）
arch-chroot /mnt << __EOF__
echo LANG=ja_JP.UTF-8 > /etc/locale.conf
__EOF__


green ""
green "Set Keymap..."
#echo KEYMAP=jp106 > /etc/vconsole.conf
#arch-chroot /mnt echo KEYMAP=jp106 > /etc/vconsole.conf（ダメだった）
arch-chroot /mnt << __EOF__
echo KEYMAP=jp106 > /etc/vconsole.conf
__EOF__



################################################################################
# Network Settings
################################################################################

green ""
green "Create Hostname..."
#echo $HOST_NAME > /etc/hostname
#arch-chroot /mnt echo $HOST_NAME > /etc/hostname（ダメだった）
arch-chroot /mnt << __EOF__
echo $HOST_NAME > /etc/hostname
__EOF__


green ""
green "Enable NetworkManager Service..."
#systemctl enable NetworkManager
arch-chroot /mnt systemctl enable NetworkManager



################################################################################
# Boot Loader
################################################################################
green ""
green "Install grub (for BIOS)..."
#pacman -S grub
#grub-install --target=i386-pc --recheck /dev/sda
arch-chroot /mnt pacman -S grub --noconfirm
arch-chroot /mnt grub-install --target=i386-pc --recheck /dev/sda

green ""
green "Create grub.cfg..."
#grub-mkconfig -o /boot/grub/grub.cfg
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg



################################################################################
# Root and User Settings
################################################################################
green ""
green "Set Root Password..."
arch-chroot /mnt passwd << __EOF__
$ROOT_PASSWORD
$ROOT_PASSWORD
__EOF__

green ""
green "Create User..."
arch-chroot /mnt useradd -m $USER_NAME

green ""
green "Set User Password..."
arch-chroot /mnt passwd $USER_NAME << __EOF__
$USER_PASSWORD
$USER_PASSWORD
__EOF__

# Install sudo（インストール済み。ベースシステムインストール時か？）
#pacman -S sudo

green ""
green "Add sudo permission for User..."
#sed -i "s/root ALL=(ALL:ALL) ALL/root ALL=(ALL:ALL) ALL\n$USER_NAME ALL=(ALL:ALL) ALL/g" /etc/sudoers
arch-chroot /mnt sed -i "s/root ALL=(ALL:ALL) ALL/root ALL=(ALL:ALL) ALL\n$USER_NAME ALL=(ALL:ALL) ALL/g" /etc/sudoers




################################################################################
# Shutdown
################################################################################
# Exit Root
#exit

green ""
green "unmount /mnt..."
umount -R /mnt

green ""
green "Install is Complete."
green "Shutdown. type poweroff"
