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

echo -e ${WHITE}"Setting up${GREEN} Wired${WHITE} and${GREEN} WIFI${WHITE} adapters"$(tput sgr0)

#Add handling to revert back to original
#Remove whitespace
ACTION=$1
ACTION=${ACTION,,} #Make lower case
ACTION=${ACTION//[[:blank:]]/} #Remove spaces

if [ "$ACTION" = "" ] || [ "$ACTION" = "update" ]; then
  #Showing /etc/network/interfaces before the change
  ScreenLines
  echo -e ${WHITE}"Current ${NONE}/etc/network/interfaces${WHITE}:"$(tput sgr0)
  cat /etc/network/interfaces

  echo -e ${WHITE}""$(tput sgr0)
  ScreenLines
  echo -e ${WHITE}"Replacing current ${NONE}/etc/network/interfaces ${WHITE}with our network config for Olympus"$(tput sgr0)
  sudo bash -c "echo 'auto lo

iface lo inet loopback
iface eth0 inet dhcp

auto wlan0
allow-hotplug wlan0
iface wlan0 inet dhcp
   wpa-scan-ssid 1
   wpa-ap-scan 1
   wpa-key-mgmt WPA-PSK
   wpa-proto RSN WPA
   wpa-pairwise CCMP TKIP
   wpa-group CCMP TKIP
   wpa-ssid Aura 
   wpa-psk 69a26ff097446d25c33e53f710ccfb79bf99b5f866469bf49dac5a04e1510a25

iface default inet dhcp' > /etc/network/interfaces"

  echo -e ${WHITE}"Replace complete"$(tput sgr0)

elif [ "$ACTION" = "revert" ]; then
  #Showing /etc/network/interfaces before the change
  echo -e ${WHITE}"Current ${NONE}/etc/network/interfaces${WHITE}:"$(tput sgr0)
  cat /etc/network/interfaces

  echo -e ${WHITE}""$(tput sgr0)
  echo -e ${WHITE}"Reset ${NONE}/etc/network/interfaces ${WHITE}to factory default"$(tput sgr0)
  sudo bash -c "echo 'auto lo

iface lo inet loopback
iface eth0 inet dhcp

allow-hotplug wlan0
iface wlan0 inet manual
wpa-roam /etc/wpa_supplicant/wpa_supplicant.conf
iface default inet dhcp' > /etc/network/interfaces"

  echo -e ${WHITE}"Rollback complete"$(tput sgr0)

else
  echo -e ${WHITE}"ERROR: No action supplied."$(tput sgr0)
  echo -e ${WHITE}"usage:"$(tput sgr0)
  echo -e ${WHITE}"To update the settings:"$(tput sgr0)
  echo -e ${WHITE}"sudo $0"$(tput sgr0)
  echo -e ${WHITE}"sudo $0 ${GREEN}\"update\""$(tput sgr0)
  echo -e ${WHITE}"sudo $0 ${GREEN}\"Update\""$(tput sgr0)
  echo -e ${WHITE}"sudo $0 ${GREEN}\"UPDATE\""$(tput sgr0)
  echo -e ${WHITE}"Or revert to default:"$(tput sgr0)
  echo -e ${WHITE}"sudo $0 ${GREEN}\"revert\""$(tput sgr0)
  echo -e ${WHITE}"sudo $0 ${GREEN}\"Revert\""$(tput sgr0)
  echo -e ${WHITE}"sudo $0 ${GREEN}\"REVERT\""$(tput sgr0)
  exit
fi

#Show the result of the change
ScreenLines
echo -e ${WHITE}"New ${NONE}/etc/network/interfaces${WHITE}:"$(tput sgr0)
cat /etc/network/interfaces

ScreenLines
echo -e ${WHITE}"Network setup complete"$(tput sgr0)