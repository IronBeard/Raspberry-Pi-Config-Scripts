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

#Ensure that a hostname has been provided as we rely on it to name the Pi.
if [ -z "$1" ]; then 
  echo -e ${WHITE}"usage: sudo $0 ${GREEN}\"New Raspberry Pi Name\"${WHITE} i.e:"$(tput sgr0)
  echo -e ${GREEN}"\"Air Pi\""$(tput sgr0)
  echo -e ${GREEN}"\"Portable Pi\""$(tput sgr0)
  exit
fi

#Remove whitespace from the hostname
NEW_HOSTNAME=$1
NEW_HOSTNAME=${NEW_HOSTNAME,,} #Make lower case
NEW_HOSTNAME=${NEW_HOSTNAME//[[:blank:]]/} #Remove spaces
echo -e ${WHITE}The Raspbery Pi will be named ${GREEN}$NEW_HOSTNAME$(tput sgr0)

#set the hostname
echo -e ${WHITE}Setting the new Hostname to ${GREEN}$NEW_HOSTNAME$(tput sgr0)
CURRENT_HOSTNAME=`cat /etc/hostname | tr -d " \t\n\r"`
echo $NEW_HOSTNAME > /etc/hostname 
sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts
