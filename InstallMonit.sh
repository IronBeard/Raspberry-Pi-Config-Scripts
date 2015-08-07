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

echo -e ${WHITE}"Install ${PURPLE}monit 5.11 ${WHITE} build prerequisites"$(tput sgr0)
sudo apt-get -y install libssl-dev

echo -e ${WHITE}"Install ${PURPLE}monit 5.4 ${WHITE}from repo"$(tput sgr0)
sudo apt-get install -y monit

echo -e ${WHITE}"Create folder for ${PURPLE}monit"$(tput sgr0)
mkdir -v ~/monit
cd ~/monit

echo -e ${WHITE}"Get ${PURPLE}monit ${WHITE}from ${RED}http://mmonit.com/monit"$(tput sgr0)
#wget http://mmonit.com/monit/dist/binary/5.11/monit-5.11-linux-arm.tar.gz
#wget https://mmonit.com/monit/dist/binary/5.14/monit-5.14-linux-arm.tar.gz
wget http://mmonit.com/monit/dist/monit-5.11.tar.gz

echo -e ${WHITE}"Unpack ${PURPLE}monit ${WHITE}from the downloaded tar"$(tput sgr0)
#tar zxvf monit-5.11-linux-arm.tar.gz
tar zxvf monit-5.11.tar.gz

echo -e ${WHITE}"Build ${PURPLE}monit ${WHITE}from the downloaded source"$(tput sgr0)
cd monit-5.11/
./configure --without-pam
make
make install

echo -e ${WHITE}"Copy ${PURPLE}monit ${WHITE}over the installed ${PURPLE}monit 5.4"$(tput sgr0)
sudo cp -f -v ~/monit/monit-5.11/monit /usr/bin/monit

echo -e ${WHITE}"Move the${LIGHTBLUE} monitrc ${WHITE}config file to monits default location"$(tput sgr0)
sudo mv -v /etc/monit/monitrc /etc/monitrc

echo -e ${WHITE}"Deleting downloaded ${PURPLE}monit${WHITE}"$(tput sgr0)
#cd ..
#rm -r -v ~/monit/

echo -e ${WHITE}"Using to SED edit the service script and change the ${LIGHTBLUE}monitrc ${WHITE}path from:"$(tput sgr0)
echo -e ${WHITE}'CONFIG="/etc/monit/monitrc"'$(tput sgr0)
echo -e ${WHITE}"to:"$(tput sgr0)
echo -e ${WHITE}'CONFIG="/etc/monitrc"'$(tput sgr0)
sed -i 's|/etc/monit/monitrc|/etc/monitrc|g' /etc/init.d/monit
grep -C 2 "CONFIG=" /etc/init.d/monit

echo -e ${WHITE}"Setting the poll time to 60 seconds"$(tput sgr0)
sed -i 's|set daemon 120|set daemon 60 |g' /etc/monitrc
grep -C 2 "set daemon" /etc/monitrc

echo -e ${WHITE}"Creating default monitoring config in /etc/monit/conf.d/"$(tput sgr0)
echo '###############################################################################
#Default settings for the Olympus domain
###############################################################################
#
###############################################################################
## Global section
###############################################################################
#
  set mailserver mail.orcon.net.nz
#
  set alert GarethPhilpott@hotmail.com
#
  set httpd port 2812
     use address 0.0.0.0
     allow admin:monit
#
###############################################################################
## Services
###############################################################################
#
  check system UNITNAME.olympus.local
    if loadavg (1min) > 4 then alert
    if loadavg (5min) > 2 then alert
    if memory usage > 75% then alert
    if swap usage > 25% then alert
    if cpu usage (user) > 70% then alert
    if cpu usage (system) > 60% then alert
    if cpu usage (wait) > 50% then alert
#
  check filesystem root-filesystem with path /
       if space usage is greater than 75% for 5 cycles then alert
#
  check network eth0 with interface eth0
       start program "/sbin/ifup eth0 --force" with timeout 60 seconds
       stop program "/sbin/ifdown eth0 --force" with timeout 60 seconds
       if failed link then restart
#
  check network wlan0 with interface wlan0
       start program "/sbin/ifup wlan0 --force" with timeout 60 seconds
       stop program "/sbin/ifdown wlan0 --force" with timeout 60 seconds
       if failed link then restart
#
#Test AirPi - Monitors the shairport service
#  check process shairport with pidfile /var/run/shairport.pid
#       start program "/etc/init.d/shairport start" with timeout 60 seconds
#       stop program "/etc/init.d/shairport stop" with timeout 60 seconds
#
#Test Motion - Monitors the motion service
#  check process motion with pidfile /home/pi/capture/motion.pid
#       start program "/etc/init.d/motion start" with timeout 60 seconds
#       stop program "/etc/init.d/motion stop" with timeout 60 seconds
#
' > /etc/monit/conf.d/monitdef
cat /etc/monit/conf.d/monitdef

echo -e ${WHITE}"Set the correct hostname in ${LIGHTBLUE}monitdef"$(tput sgr0)
CURRENT_HOSTNAME=`cat /etc/hostname | tr -d " \t\n\r"`
sed -i "s|UNITNAME|$CURRENT_HOSTNAME|g" /etc/monit/conf.d/monitdef
grep -A 2 "$CURRENT_HOSTNAME" /etc/monit/conf.d/monitdef

echo -e ${WHITE}"Setting config scripts permissions"$(tput sgr0)
sudo chmod -v 600 /etc/monit/conf.d/*

echo -e ${WHITE}"Checking the ${PURPLE}monit ${WHITE}config syntax"$(tput sgr0)
service monit syntax

echo -e ${WHITE}"Restarting ${PURPLE}monit ${WHITE}to pick up the config changes"$(tput sgr0)
service monit restart

set +x
echo -e ${WHITE}""$(tput sgr0)
echo -e ${WHITE}"Final steps:"$(tput sgr0)
echo -e ${WHITE}""$(tput sgr0)
echo -e ${WHITE}"1. Configure any needed ${PURPLE}monit ${WHITE}settings in ${LIGHTBLUE}monitrc"$(tput sgr0)
echo -e ${WHITE}"    sudo nano /etc/monitrc"$(tput sgr0)
echo -e ${WHITE}"1. Configure any needed custom settings in ${LIGHTBLUE}monitdef"$(tput sgr0)
echo -e ${WHITE}"    sudo nano /etc/monit/conf.d/monitdef"$(tput sgr0)
echo -e ${WHITE}"3. Confirm that the syntax in both the ${LIGHTBLUE}monitrc ${WHITE} and ${LIGHTBLUE}monitdef ${WHITE}config files is correct"$(tput sgr0)
echo -e ${WHITE}"    sudo service monit syntax"$(tput sgr0)
echo -e ${WHITE}"4. Restart ${PURPLE}monit ${WHITE}to test the changes"$(tput sgr0)
echo -e ${WHITE}"    sudo service monit restart"$(tput sgr0)
echo -e ${WHITE}"5. Reboot"$(tput sgr0)
echo -e ${WHITE}""$(tput sgr0)

#Reset all attributes in case we changed anything
tput sgr0