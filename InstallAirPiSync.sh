#!/bin/bash

#DESCRIPTION
#    .
#NOTES
#    File Name      : InstallAirPiSync.sh
#    Author         : Gareth Philpott
#    Date           : 05/11/2017
#    Prerequisite   : 
#    Copyright 2017 - Gareth Philpott
#EXAMPLE
#    ./InstallAirPiSync.sh

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

#Ensure that a hostname has been provided as we rely on it to name the Pi and the shairport instance.
if [ -z "$1" ]; then 
  echo -e ${WHITE}"usage: sudo $0 ${GREEN}\"AirTunes Endpoint Name\"${WHITE} i.e:"$(tput sgr0)
  echo -e ${GREEN}"\"Air Pi\""$(tput sgr0)
  echo -e ${GREEN}"\"Portable Pi\""$(tput sgr0)
  exit
fi

#AirPlay Name
AIRPLAY_NAME=$1
echo -e ${WHITE}"The AirTunes Endpoint Name will be ${GREEN}$AIRPLAY_NAME"$(tput sgr0)

#Remove whitespace from the hostname
NEW_HOSTNAME=$1
NEW_HOSTNAME=${NEW_HOSTNAME,,} #Make lower case
NEW_HOSTNAME=${NEW_HOSTNAME//[[:blank:]]/} #Remove spaces
echo -e ${WHITE}"The Raspbery Pi will be named ${GREEN}$NEW_HOSTNAME"$(tput sgr0)

#set the hostname
echo -e ${WHITE}"Setting the new Hostname to ${GREEN}$NEW_HOSTNAME"$(tput sgr0)
CURRENT_HOSTNAME=`cat /etc/hostname | tr -d " \t\n\r"`
echo $NEW_HOSTNAME > /etc/hostname 
sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts

#Update/Upgrade
echo -e ${WHITE}"Update and Upgrade to the latest Packages"$(tput sgr0)
apt-get -y update && apt-get -y upgrade

#Change the audio output to the Audiojack instead of HDMI
echo -e ${WHITE}"Change the audio output to the ${YELLOW}Audiojack${WHITE} instead of ${YELLOW}HDMI"$(tput sgr0)
amixer cset numid=3 1

#Install All
echo -e ${WHITE}"Installing all of the required base Packages"$(tput sgr0)
echo -e ${PURPLE}"autoconf automake avahi-daemon build-essential git libasound2-dev libavahi-client-dev libconfig-dev libdaemon-dev libpopt-dev libssl-dev libtool xmltoman"$(tput sgr0)
apt-get -y install autoconf automake avahi-daemon build-essential git libasound2-dev libavahi-client-dev libconfig-dev libdaemon-dev libpopt-dev libssl-dev libtool xmltoman

#Download hendrikw82 version of shairport
echo -e ${WHITE}"Installing ${PURPLE}Shairport"$(tput sgr0)
echo -e ${WHITE}"Downloading ${PURPLE}Shairport${WHITE} from GitHub ${RED}\(IronBeard Repo\)"$(tput sgr0)
git clone https://github.com/mikebrady/shairport-sync.git

#Change to the shairport directory
cd /home/pi/shairport-sync

#Install Shairport as service
echo -e ${WHITE}"Installing ${PURPLE}Shairport${WHITE} as service"$(tput sgr0)
echo -e ${WHITE}"Running ${GREEN}autoreconf"$(tput sgr0)
autoreconf -i -f
echo -e ${WHITE}"Running ${GREEN}configure"$(tput sgr0)
./configure --with-alsa --with-avahi --with-ssl=openssl --with-systemd --with-metadata
echo -e ${WHITE}"Running ${GREEN}make"$(tput sgr0)
make
echo -e ${WHITE}"Running the install"$(tput sgr0)
make install

#Set Shairport to run at start-up
echo -e ${WHITE}"Setting ${PURPLE}Shairport${WHITE} to run at start-up"$(tput sgr0)
systemctl enable shairport-sync

#Starting Shairport
echo -e ${WHITE}"Starting ${PURPLE}Shairport"$(tput sgr0)
service shairport-sync start

#Reset all attributes in case we changed anything
tput sgr0

#Reboot
echo -e ${WHITE}"Install Complete."$(tput sgr0)
echo -e ${WHITE}"Rebooting..."$(tput sgr0)
reboot