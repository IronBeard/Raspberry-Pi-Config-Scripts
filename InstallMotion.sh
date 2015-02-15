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

echo -e ${WHITE}"About to create folders"$(tput sgr0)

cd /home/pi
mkdir -v capture
chmod -v 777 /home/pi/capture
mkdir -v build-motion-mmal
chmod -v 777 /home/pi/build-motion-mmal

cd /home/pi/build-motion-mmal
rm -rf -v userland
mkdir -v userland
chmod -v 777 /home/pi/build-motion-mmal/userland
rm -rf -v motion
mkdir -v motion
chmod -v 777 /home/pi/build-motion-mmal/motion

echo -e ${WHITE}"About to install the ${PURPLE}normal motion${WHITE} so as to use it's ${RED}daemon${WHITE} startup"$(tput sgr0)
apt-get install -y motion

echo -e ${WHITE}"About to install main ${PURPLE}motion-mmal${WHITE} dependencies"$(tput sgr0)
apt-get install -y libjpeg62 libjpeg62-dev libavformat53 libavformat-dev libavcodec53 libavcodec-dev libavutil51 libavutil-dev libc6-dev zlib1g-dev libmysqlclient18 libmysqlclient-dev libpq5 libpq-dev libbz2-dev fftw3-dev libfftw3-dev

echo -e ${WHITE}"About to install ${PURPLE}sendemail"$(tput sgr0)
sudo apt-get install -y sendemail

echo -e ${WHITE}"About to install ${PURPLE}wget"$(tput sgr0)
apt-get install -y wget

echo -e ${WHITE}"About to install ${PURPLE}Git"$(tput sgr0)
apt-get install -y git-core

echo -e ${WHITE}"About to install ${PURPLE}build tools"$(tput sgr0)
apt-get install -y build-essential
apt-get install -y cmake

#--------------------------------------

cd /home/pi/build-motion-mmal

echo -e ${WHITE}"About to clone userland"$(tput sgr0)
git clone https://github.com/raspberrypi/userland.git

echo -e ${WHITE}"About to clone ${PURPLE}mmal-test${WHITE} branch from GitHub ${RED}(dozencrows Repo)"$(tput sgr0)
#https://github.com/dozencrows/motion.git
#https://github.com/dozencrows/motion/tree/mmal-test
git clone https://github.com/dozencrows/motion.git --branch mmal-test --single-branch

echo -e ${WHITE}"About to build"$(tput sgr0)
cd /home/pi/build-motion-mmal/motion
USERLANDPATH=/home/pi/build-motion-mmal/userland cmake .
make

echo -e ${WHITE}"Copying the newly built executable to target folder"$(tput sgr0)
cp ./motion /usr/bin/motion
chmod -v 777 /usr/bin/motion

echo -e ${WHITE}"Setting folder persmissions"$(tput sgr0)
chmod -v 777 /etc/motion/motion.conf
chmod -v 777 /etc/motion.conf
chmod -v 777 /usr/bin/motion
touch /home/pi/capture/motion.log
chmod -v 777 /home/pi/capture/motion.log

#Use Sed
#Add how to change to auto start
#sudo nano /etc/default/motion
#start_motion_daemon=yes
sed -i 's|start_motion_daemon=no|start_motion_daemon=yes|g' /etc/default/motion
grep -C 2 "start_motion_daemon=" /etc/default/motion
#sudo nano /etc/motion.conf
#daemon on
sed -i 's|daemon off|daemon on|g' /etc/motion.conf
grep -C 2 "daemon o" /etc/motion.conf

set +x
echo -e ${WHITE}""$(tput sgr0)
echo -e ${WHITE}"Final steps:"$(tput sgr0)
echo -e ${WHITE}""$(tput sgr0)
echo -e ${WHITE}"1. Grab a working motion.conf from somewhere"$(tput sgr0)
echo -e ${WHITE}"    eg an example one from this thread"$(tput sgr0)
echo -e ${WHITE}"    http://www.raspberrypi.org/forums/viewtopic.php?f=43&t=75240&start=100"$(tput sgr0)
echo -e ${WHITE}"2. Add/change your own settings in it eg set target path to /home/pi/capture"$(tput sgr0)
echo -e ${WHITE}"    be sure to set the daemon to on in this config file too"$(tput sgr0)
echo -e ${WHITE}"3. Copy the new motion.conf to the corrrect place (not the same place a normal motion.conf) eg"$(tput sgr0)
echo -e ${WHITE}"    cp ./motion.conf /etc/motion.conf"$(tput sgr0)
echo -e ${WHITE}"4. Reboot"$(tput sgr0)
echo -e ${WHITE}""$(tput sgr0)

#Reset all attributes in case we changed anything
tput sgr0