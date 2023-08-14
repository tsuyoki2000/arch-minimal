#! /bin/sh
########################################
# 未対応案件
# - Mirrors
# - Swap（ファイル形式）
# - Automatic time sync (NTP)
# - multilib Repo (/etc/pacman.conf?)
########################################

################################################################################
# Settings
################################################################################
clear
read -p "Hostname: " HOST_NAME
read -p "Root password: " ROOT_PASSWORD
clear

read -p "User name: " USER_NAME
read -p "User password: " USER_PASSWORD
clear
read -p "Start install. If press Enter: "
clear

################################################################################
# function for comment
################################################################################
NORMAL=$(tput sgr0)
GREEN=$(tput setaf 2; tput bold)
function green() {
    echo ""
    echo -e "$GREEN$*$NORMAL"
}

################################################################################
# Create Partitions
################################################################################
INSTALL_DEVICE=/dev/sda

green "Load Keymap..."
loadkeys jp106
echo "done."

green "FDISK..."
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

green "Format Disks..."
mkfs.fat -F32 ${INSTALL_DEVICE}1
mkfs.ext4 ${INSTALL_DEVICE}2

green "Mount Disks..."
mount ${INSTALL_DEVICE}2 /mnt
mount --mkdir ${INSTALL_DEVICE}1 /mnt/boot
echo "done."

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

green "Base Package..."
pacstrap -K /mnt base linux linux-firmware base-devel networkmanager

green "fstab..."
genfstab -U /mnt >> /mnt/etc/fstab
echo "done."

# chroot
#arch-chroot /mnt << __EOF__
#__EOF__

green "TimeZone..."
#ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
arch-chroot /mnt ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
echo "done."

green "Harcware Clock Setting..."
#hwclock --systohc
arch-chroot /mnt hwclock --systohc
echo "done."

green "Localization..."
#sed -i "s/#en_US.UTF-8/en_US.UTF-8/g" /etc/locale.gen
#sed -i "s/#ja_JP.UTF-8/ja_JP.UTF-8/g" /etc/locale.gen
#arch-chroot /mnt sed -i "s/#en_US.UTF-8/en_US.UTF-8/g" /etc/locale.gen
arch-chroot /mnt sed -i "s/#ja_JP.UTF-8/ja_JP.UTF-8/g" /etc/locale.gen
echo "done."

green "Create locale..."
#locale-gen
arch-chroot /mnt locale-gen

#####################################
##### LANG="C.UTF-8" になっている #####
# リダイレクト（>）の処理が一般権限で実行されているため、ファイル出力が出来ないらしい
#####################################
green "Edit locale.conf..."
#echo LANG=ja_JP.UTF-8 > /etc/locale.conf
#arch-chroot /mnt echo "LANG=ja_JP.UTF-8" > /etc/locale.conf（ダメだった）
#arch-chroot /mnt echo "LANG=ja_JP.UTF-8" | sudo tee /etc/locale.conf（ダメだった）
#sudo sh -c "arch-chroot /mnt echo LANG=ja_JP.UTF-8 > /etc/locale.conf"（ダメだった）
#sh -c "arch-chroot /mnt echo LANG=ja_JP.UTF-8 > /etc/locale.conf"（ダメだった）
arch-chroot /mnt << __EOF__
echo LANG=ja_JP.UTF-8 > /etc/locale.conf
__EOF__

green "Set Keymap..."
#echo KEYMAP=jp106 > /etc/vconsole.conf
#arch-chroot /mnt echo KEYMAP=jp106 > /etc/vconsole.conf（ダメだった）
arch-chroot /mnt << __EOF__
#echo KEYMAP=jp106 > /etc/vconsole.conf

#echo "KEYMAP=jp106
#XKBLAYOUT=jp
#XKBMODEL=jp106
#XKBOPTIONS=terminate:ctrl_alt_bksp" > /etc/vconsole.conf

localectl set-keymap jp106
__EOF__
#XKB〜の３行は意味なかった（xfceインストール後、キーボードレイアウトは英語のままだった）
sleep 5

################################################################################
# Network Settings
################################################################################
green "Create Hostname..."
#echo $HOST_NAME > /etc/hostname
#arch-chroot /mnt echo $HOST_NAME > /etc/hostname（ダメだった）
arch-chroot /mnt << __EOF__
echo $HOST_NAME > /etc/hostname
__EOF__

green "Enable NetworkManager Service..."
#systemctl enable NetworkManager
arch-chroot /mnt systemctl enable NetworkManager
echo "done."



################################################################################
# Boot Loader
################################################################################
green "Install grub (for BIOS)..."
#pacman -S grub
#grub-install --target=i386-pc --recheck /dev/sda
arch-chroot /mnt pacman -S grub --noconfirm
arch-chroot /mnt grub-install --target=i386-pc --recheck /dev/sda

green "Create grub.cfg..."
#grub-mkconfig -o /boot/grub/grub.cfg
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg



################################################################################
# Root and User Settings
################################################################################
green "Set Root Password..."
arch-chroot /mnt passwd << __EOF__
$ROOT_PASSWORD
$ROOT_PASSWORD
__EOF__

green "Create User..."
arch-chroot /mnt useradd -m $USER_NAME
echo "done."

green "Set User Password..."
arch-chroot /mnt passwd $USER_NAME << __EOF__
$USER_PASSWORD
$USER_PASSWORD
__EOF__

green "Add sudo permission for User..."
#sed -i "s/root ALL=(ALL:ALL) ALL/root ALL=(ALL:ALL) ALL\n$USER_NAME ALL=(ALL:ALL) ALL/g" /etc/sudoers
arch-chroot /mnt sed -i "s/root ALL=(ALL:ALL) ALL/root ALL=(ALL:ALL) ALL\n$USER_NAME ALL=(ALL:ALL) ALL/g" /etc/sudoers
echo "done."
sleep 3

################################################################################
# zram-generator（スワップ管理パッケージ？）
################################################################################
green "Install zram-generator..."
arch-chroot /mnt pacman -S zram-generator --noconfirm

################################################################################
# Pipewire
# - wireplumber（pipewire-pulseの依存。pipwire もインストールされる。）
# - pipewire-pulse（xfce4-pulseaudio-plugin の依存）
# - pipewire-jack（Firefox, smplayer の依存）
# - pipewire-alsa（使用アプリで ALSA を使っているものがあるのか分からんが一応インストール）
################################################################################
green "Install Pipewire..."
arch-chroot /mnt pacman -S wireplumber gst-plugin-pipewire pipewire-pulse pipewire-jack pipewire-alsa --noconfirm

# Exit Root
#exit



################################################################################
# Shutdown
################################################################################
green "unmount /mnt..."
umount -R /mnt
echo "done."

green "Install is Complete."
green "Type 'poweroff' or 'reboot'."
