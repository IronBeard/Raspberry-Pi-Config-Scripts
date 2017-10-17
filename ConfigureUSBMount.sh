#!/bin/bash

#Text Colors
NONE='\033[00m'
BLACK='\033[00;30m'
BLUE='\033[00;34m'
GREEN='\033[00;32m'
CYAN='\033[00;36m'
RED='\033[00;31m'
PURPLE='\033[00;35m'
BROWN='\033[00;33m'
LIGHTGRAY='\033[00;37m'
DARKGRAY='\033[01;30m'
LIGHTBLUE='\033[01;34m'
LIGHTGREEN='\033[01;32m'
LIGHTCYAN='\033[01;36m'
LIGHTRED='\033[01;31m'
LIGHTPURPLE='\033[01;35m'
YELLOW='\033[01;33m'
WHITE='\033[01;37m'
BOLD='\033[1m'
UNDERLINE='\033[4m'

echo -e ${WHITE}`date`$(tput sgr0)

echo -e ${WHITE}"Backup ${PURPLE}USBMount ${WHITE} config for rollback"$(tput sgr0)
cp /etc/usbmount/usbmount.conf /etc/usbmount/usbmount.conf.bak

echo -e ${WHITE}"Using to SED edit ${LIGHTBLUE}usbmount.conf ${WHITE}to change the:"$(tput sgr0)
echo -e ${WHITE}"    FILESYSTEMS to include NTFS"$(tput sgr0)
sed -i 's|FILESYSTEMS="vfat ext2 ext3 ext4 hfsplus"|FILESYSTEMS="vfat ext2 ext3 ext4 hfsplus ntfs"|g' /etc/usbmount/usbmount.conf
echo -e ${WHITE}"    FS_MOUNTOPTIONS to pass the user options for NTFS, FAT and EXT4"$(tput sgr0)
#sed -i 's|FS_MOUNTOPTIONS=""|FS_MOUNTOPTIONS="-fstype=ntfs,gid=users,umask=0 -fstype=vfat,gid=users,umask=0 -fstype=ext4,gid=users,umask=0"|g' /etc/usbmount/usbmount.conf
sed -i 's|FS_MOUNTOPTIONS=""|FS_MOUNTOPTIONS="-fstype=ntfs,gid=users,umask=0 -fstype=vfat,gid=users,umask=0"|g' /etc/usbmount/usbmount.conf
echo -e ${WHITE}"    MOUNTOPTIONS USB sync setting to async for performance"$(tput sgr0)
sed -i 's|MOUNTOPTIONS="sync,noexec,nodev,noatime,nodiratime"|MOUNTOPTIONS="async,noexec,nodev,noatime,nodiratime"|g' /etc/usbmount/usbmount.conf

echo -e ${WHITE}"Install Complete"$(tput sgr0)
