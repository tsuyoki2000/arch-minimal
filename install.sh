#! /bin/sh
clear

########################################
# 未対応案件
# - Swap（ファイル形式）
# - multilib Repo (/etc/pacman.conf?)
########################################

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
# Settings
################################################################################
read -p "Hostname: " HOST_NAME
read -p "Root password: " ROOT_PASSWORD
clear

read -p "User name: " USER_NAME
read -p "User password: " USER_PASSWORD
clear
read -p "Start install. If press Enter: "
clear

################################################################################
# Create Partitions
################################################################################
INSTALL_DEVICE=/dev/sda

#green "Load Keymap..."
#loadkeys jp106
#echo "done."

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
# MirrorList
# ミラーリストの更新は必須ではない。パッケージのダウンロードが遅いだけ。
# -c は country。jp は日本。-p は protocol。
################################################################################
green "Select Japan Mirror..."
reflector -c jp -p https --save /etc/pacman.d/mirrorlist
echo "done."

#reflector -c jp -p https
## 日本のミラーリストが表示されたかの確認
#read -p "Did you see the Japan MirrorList? (y/n): " IS_MIRROR_LIST
#if [ $IS_MIRROR_LIST = "y" ]; then
#  reflector -c jp -p https --save /etc/pacman.d/mirrorlist
#fi
#clear

################################################################################
# Time Sync
################################################################################
green "Time Sync..."
timedatectl set-ntp true
echo "done."

################################################################################
# System Insall
################################################################################

green "Base Package..."
pacstrap -K /mnt base linux linux-firmware base-devel networkmanager

green "fstab..."
genfstab -U /mnt >> /mnt/etc/fstab
echo "done."

# chroot
#arch-chroot /mnt << __EOF__
#__EOF__

green "TimeZone..."
arch-chroot /mnt ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
echo "done."

green "Harcware Clock Setting..."
arch-chroot /mnt hwclock --systohc
echo "done."

green "Localization..."
arch-chroot /mnt sed -i "s/#en_US.UTF-8/en_US.UTF-8/g" /etc/locale.gen
# locale で日本語が選べるように設定しておく
arch-chroot /mnt sed -i "s/#ja_JP.UTF-8/ja_JP.UTF-8/g" /etc/locale.gen
echo "done."

green "Create locale..."
arch-chroot /mnt locale-gen



#####################################
# 言語の設定
# デフォルトでは、LANG="C.UTF-8" になっている
# TTY は日本語表示ができないので、ここでは設定しない（Xシステムインストール時に設定すべきだと思う）
#####################################
#green "Edit locale.conf..."
#arch-chroot /mnt << __EOF__
#echo LANG=ja_JP.UTF-8 > /etc/locale.conf
#__EOF__

#arch-chroot /mnt echo "LANG=ja_JP.UTF-8" > /etc/locale.conf（ダメだった）
# リダイレクト（>）の処理が一般権限で実行されているため、ファイル出力が出来ないらしい

#arch-chroot /mnt echo "LANG=ja_JP.UTF-8" | sudo tee /etc/locale.conf（ダメだった）
#sudo sh -c "arch-chroot /mnt echo LANG=ja_JP.UTF-8 > /etc/locale.conf"（ダメだった）
#sh -c "arch-chroot /mnt echo LANG=ja_JP.UTF-8 > /etc/locale.conf"（ダメだった）



#####################################
# Keymap 設定
# インストール時に以下のコマンドが実行できないので、簡易的に日本語キーボードを設定
# sudo localectl set-keymap jp106
# 再起動後、手動でコマンドを実行する事（Xシステムをインストールする前に実行しておく事）
# コマンドが実行できない理由は、この段階で systemd サービスが起動してないため（localectl は systemd のコマンド）。
#####################################
green "Set Keymap..."
arch-chroot /mnt << __EOF__
echo KEYMAP=jp106 > /etc/vconsole.conf
__EOF__

#arch-chroot /mnt << __EOF__
#echo "KEYMAP=jp106
#XKBLAYOUT=jp
#XKBMODEL=jp106
#XKBOPTIONS=terminate:ctrl_alt_bksp" > /etc/vconsole.conf
#XKB〜の３行は意味なかった（xfceインストール後、キーボードレイアウトは英語のままだった）
#__EOF__



################################################################################
# Network Settings
################################################################################
green "Create Hostname..."
#arch-chroot /mnt echo $HOST_NAME > /etc/hostname（ダメだった）
arch-chroot /mnt << __EOF__
echo $HOST_NAME > /etc/hostname
__EOF__

green "Enable NetworkManager Service..."
arch-chroot /mnt systemctl enable NetworkManager
echo "done."



################################################################################
# Boot Loader
################################################################################
green "Install grub (for BIOS)..."
arch-chroot /mnt pacman -S grub --noconfirm
arch-chroot /mnt grub-install --target=i386-pc --recheck /dev/sda

green "Create grub.cfg..."
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
arch-chroot /mnt useradd -m -G wheel $USER_NAME
echo "done."

green "Set User Password..."
arch-chroot /mnt passwd $USER_NAME << __EOF__
$USER_PASSWORD
$USER_PASSWORD
__EOF__

green "Add sudo permission for User..."
#arch-chroot /mnt sed -i "s/root ALL=(ALL:ALL) ALL/root ALL=(ALL:ALL) ALL\n$USER_NAME ALL=(ALL:ALL) ALL/g" /etc/sudoers
arch-chroot /mnt << __EOF__
echo $USER_NAME ALL=(ALL) ALL > /etc/sudoers.d/00_$USER_NAME
__EOF__
echo "done."
read



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
# - pipewire-alsa（普段使用のアプリで ALSA を使っているものがあるのか分からんが一応インストール）
################################################################################
green "Install Pipewire..."
arch-chroot /mnt pacman -S wireplumber gst-plugin-pipewire pipewire-pulse pipewire-jack pipewire-alsa --noconfirm

################################################################################
# git
################################################################################
green "Install git..."
arch-chroot /mnt pacman -S git --noconfirm


# Exit Root
#exit

################################################################################
# インストール時には、systemd サービスが起動してないため、実行できない。
# 再起動後、手動でやらないとダメっぽい（スクリプトに組み込むのが無理っぽい？）
################################################################################
#green "Set Keymap using localectl..."
#arch-chroot /mnt << __EOF__
#localectl set-keymap jp106
#__EOF__



################################################################################
# UnMount
################################################################################
green "unmount /mnt..."
umount -R /mnt
echo "done."



################################################################################
# Shutdown
################################################################################
green "Install is Complete."
green "Type 'poweroff' or 'reboot'."
