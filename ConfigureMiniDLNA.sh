#!/bin/bash

#Functions
function ScreenLines {
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
}

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

#Ensure that the script has been run as root
if [ `whoami` != root ]; then
  echo -e ${WHITE}"Due to the nature of the changes that this script makes please run it as ${RED}root ${WHITE}or by using ${RED}sudo"$(tput sgr0)
  exit
fi

echo -e ${WHITE}"Backup ${PURPLE}MiniDLNA ${WHITE} config for rollback"$(tput sgr0)
cp /etc/minidlna.conf /etc/minidlna.conf.bak

echo -e ${WHITE}"Using SED to edit ${LIGHTBLUE}minidlna.conf ${WHITE}to change the:"$(tput sgr0)
echo -e ${WHITE}"    ${GREEN}media_dir ${WHITE}to point to the ${PURPLE}USBMount ${WHITE}directories"$(tput sgr0)
sed -i 's|media_dir=/var/lib/minidlna|media_dir=V,/media/usb0\nmedia_dir=V,/media/usb1\nmedia_dir=V,/media/usb2\nmedia_dir=V,/media/usb3\nmedia_dir=V,/media/usb4\nmedia_dir=V,/media/usb5\nmedia_dir=V,/media/usb6\nmedia_dir=V,/media/usb7\n|g' /etc/minidlna.conf
# Need to work out how to get the Pi name in here
echo -e ${WHITE}"    ${GREEN}friendly_name ${WHITE}to the Pi's name"$(tput sgr0)
sed -i 's|#friendly_name=|friendly_name=Raspberry Pi|g' /etc/minidlna.conf
echo -e ${WHITE}"    ${GREEN}inotify ${WHITE}switched on"$(tput sgr0)
sed -i 's|#inotify=yes|inotify=yes|g' /etc/minidlna.conf
echo -e ${WHITE}"    ${GREEN}root_container ${WHITE}changed to ${YELLOW}V${WHITE}ideo"$(tput sgr0)
sed -i 's|#root_container=.|root_container=V|g' /etc/minidlna.conf

echo -e ${WHITE}"Restarting ${PURPLE}MiniDLNA ${WHITE}to pick up the config changes"$(tput sgr0)
service minidlna restart

echo -e ${WHITE}"Generate ${PURPLE}MiniDLNA${WHITE}'s database"$(tput sgr0)
#minidlnad -R
service minidlna force-reload

echo -e ${WHITE}"Install Complete"$(tput sgr0)
