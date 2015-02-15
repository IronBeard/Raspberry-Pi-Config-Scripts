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
  echo -e ${WHITE}"Due to the nature of the changes that this script makes please run it as ${RED}root${WHITE} or by using ${RED}sudo"$(tput sgr0)
  exit
fi

#Remove whitespace
FIRMWARE=$1
FIRMWARE=${FIRMWARE,,} #Make lower case
FIRMWARE=${FIRMWARE//[[:blank:]]/} #Remove spaces

echo -e ${WHITE}"UPDATING SYSTEM SOFTWARE – ${LIGHTBLUE}UPDATE"$(tput sgr0)
echo -e ${YELLOW}"sudo apt-get update"$(tput sgr0)
sudo apt-get update

echo -e ${WHITE}"UPDATING SYSTEM SOFTWARE – ${LIGHTBLUE}UPGRADE"$(tput sgr0)
echo -e ${YELLOW}"sudo apt-get -y upgrade"$(tput sgr0)
sudo apt-get -y upgrade

echo -e ${WHITE}"UPDATING SYSTEM SOFTWARE – ${LIGHTBLUE}DISTRIBUTION"$(tput sgr0)
echo -e ${YELLOW}"sudo apt-get -y dist-upgrade"$(tput sgr0)
sudo apt-get -y dist-upgrade

echo -e ${WHITE}"REMOVING APPLICATION ORPHANS"$(tput sgr0)
echo -e ${YELLOW}"sudo apt-get -y autoremove --purge"$(tput sgr0)
sudo apt-get -y autoremove --purge

echo -e ${WHITE}"UPDATING FIRMWARE"$(tput sgr0)
#Test whether the "firmware" flag has been provided.
if [ "$FIRMWARE" = "firmware" ]; then
  echo -e ${YELLOW}"sudo apt-get install rpi-update"$(tput sgr0)
  #Just incase it's not on this Pi
  sudo apt-get install rpi-update
  echo -e ${YELLOW}"sudo rpi-update"$(tput sgr0)
  sudo rpi-update
else
  echo -e ${GREEN}"firmware${WHITE} flag not present, not updating the Pi firmware"$(tput sgr0)
  echo -e ${WHITE}"usage:"$(tput sgr0)
  echo -e ${WHITE}"sudo $0 ${GREEN}firmware${LIGHTPURPLE} Or${WHITE} sudo $0"$(tput sgr0)
  exit
fi