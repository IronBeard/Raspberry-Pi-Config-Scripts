#!/bin/bash

#DESCRIPTION
#    .
#NOTES
#    File Name      : InstallAirPi.sh
#    Author         : Gareth Philpott
#    Date           : 09/01/2017
#    Prerequisite   : 
#    Copyright 2017 - Gareth Philpott
#EXAMPLE
#    ./InstallAirPi.sh

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
echo -e ${PURPLE}"git build-essential libssl-dev libcrypt-openssl-rsa-perl libao-dev libio-socket-inet6-perl libwww-perl avahi-utils pkg-config libmodule-build-perl"$(tput sgr0)
apt-get -y install git build-essential libssl-dev libcrypt-openssl-rsa-perl libao-dev libio-socket-inet6-perl libwww-perl avahi-utils pkg-config libmodule-build-perl

#Install Net::sdp
#echo -e ${WHITE}"Installing ${PURPLE}Net::sdp"$(tput sgr0)
#git clone https://github.com/njh/perl-net-sdp.git perl-net-sdp
echo -e ${WHITE}"Downloading ${PURPLE}Net::sdp${WHITE} from GitHub ${RED}(IronBeard Repo)"$(tput sgr0)
git clone https://github.com/IronBeard/perl-net-sdp.git perl-net-sdp

#Changing to the perl-net-sdp directory
cd perl-net-sdp

#Build & Install perl-net-sdp
echo -e ${WHITE}"Building and Installing ${PURPLE}perl-net-sdp"$(tput sgr0)
perl Build.PL
./Build
./Build test
./Build install

#Change directory back to the Home directory
cd

#Download hendrikw82 version of shairport
echo -e ${WHITE}"Installing ${PURPLE}Shairport"$(tput sgr0)
#git clone https://github.com/hendrikw82/shairport.git shairport
echo -e ${WHITE}"Downloading ${PURPLE}Shairport${WHITE} from GitHub ${RED}\(IronBeard Repo\)"$(tput sgr0)
git clone https://github.com/IronBeard/shairport.git shairport
#git clone https://github.com/abrasive/shairport.git shairport

#change to the shairport directory
cd shairport

#Install Shairport as service
echo -e ${WHITE}"Installing ${PURPLE}Shairport${WHITE} as service"$(tput sgr0)
make install

#Copy the sample init file to the init.d directory
echo -e ${WHITE}"Copying the ${PURPLE}Shairport${WHITE} init file to the init.d directory"$(tput sgr0)
cp shairport.init.sample /etc/init.d/shairport

#Set Shairport to run at start-up
echo -e ${WHITE}"Setting ${PURPLE}Shairport${WHITE} to run at start-up"$(tput sgr0)
insserv shairport

#Starting Shairport
echo -e ${WHITE}"Starting ${PURPLE}Shairport"$(tput sgr0)
service avahi-daemon start
/etc/init.d/shairport start

#Add the AP Name in the launch parameters
#sudo nano /etc/init.d/shairport
#Add -a [Name of Audio point] to the DAEMON_ARGS variable line
#DAEMON_ARGS="-w $PIDFILE -a AirPi"
echo -e ${WHITE}"Adding the Air Play Name (${GREEN}$AIRPLAY_NAME${WHITE}) to the ${PURPLE}Shairport${WHITE} config"$(tput sgr0)
sed -i "s/DAEMON_ARGS=\"-w \$PIDFILE\"/\DAEMON_ARGS=(-w \$PIDFILE -a \"$AIRPLAY_NAME\")/g" /etc/init.d/shairport
sed -i "s/\$DAEMON_ARGS/\"\${DAEMON_ARGS[\@]}\"/g" /etc/init.d/shairport

#Reset all attributes in case we changed anything
tput sgr0

#reboot
echo -e ${WHITE}"Install Complete."$(tput sgr0)
echo -e ${WHITE}"Rebooting..."$(tput sgr0)
reboot