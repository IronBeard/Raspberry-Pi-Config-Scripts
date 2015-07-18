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

echo -e ${WHITE}"Creating folders"$(tput sgr0)

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
apt-get install -y sendemail

echo -e ${WHITE}"About to install ${PURPLE}wget"$(tput sgr0)
apt-get install -y wget

echo -e ${WHITE}"About to install ${PURPLE}Git"$(tput sgr0)
apt-get install -y git-core

echo -e ${WHITE}"About to install ${PURPLE}build tools"$(tput sgr0)
apt-get install -y build-essential
apt-get install -y cmake

#--------------------------------------

echo -e ${WHITE}"Enabling the Pi Camera and settings the GPU RAM to 128MB"$(tput sgr0)
set_config_var start_x 1 /boot/config.txt
CUR_GPU_MEM=$(get_config_var gpu_mem /boot/config.txt)
if [ -z "$CUR_GPU_MEM" ] || [ "$CUR_GPU_MEM" -lt 128 ]; then
  set_config_var gpu_mem 128 /boot/config.txt
fi
sed /boot/config.txt -i -e "s/^startx/#startx/"
sed /boot/config.txt -i -e "s/^fixup_file/#fixup_file/"

#--------------------------------------

cd /home/pi/build-motion-mmal

echo -e ${WHITE}"About to clone userland"$(tput sgr0)
git clone https://github.com/IronBeard/userland.git

echo -e ${WHITE}"Cloning ${PURPLE}mmal-test${WHITE} branch from GitHub ${RED}(IronBeard Repo)"$(tput sgr0)
#https://github.com/dozencrows/motion.git
#https://github.com/dozencrows/motion/tree/mmal-test
git clone https://github.com/IronBeard/motion.git --branch mmal-test --single-branch

echo -e ${WHITE}"Building ${PURPLE}motion${WHITE}"$(tput sgr0)
cd /home/pi/build-motion-mmal/motion
USERLANDPATH=/home/pi/build-motion-mmal/userland cmake .
make

echo -e ${WHITE}"Copying the newly built executable to target folder"$(tput sgr0)
cp ./motion /usr/bin/motion

echo -e ${WHITE}"Copying the domain motion.conf to /etc"$(tput sgr0)
cp ./motion.conf /etc/motion.conf

echo -e ${WHITE}"Setting folder persmissions"$(tput sgr0)
chmod -v 777 /etc/motion/motion.conf
chmod -v 777 /etc/motion.conf
chmod -v 777 /usr/bin/motion
touch /home/pi/capture/motion.log
chmod -v 777 /home/pi/capture/motion.log

#--------------------------------------

echo -e ${WHITE}"Setting ${PURPLE}motion${WHITE} for auto start"$(tput sgr0)
# Edit sudo nano /etc/default/motion abd set start_motion_daemon=yes
sed -i 's|start_motion_daemon=no|start_motion_daemon=yes|g' /etc/default/motion
grep -C 2 "start_motion_daemon=" /etc/default/motion
# Edit sudo nano /etc/motion.conf and set daemon on
sed -i 's|daemon off|daemon on|g' /etc/motion.conf
grep -C 2 "daemon o" /etc/motion.conf

echo -e ${WHITE}"Adding a status command to /etc/init.d/${PURPLE}motion${WHITE}"$(tput sgr0)
# Edit the /etc/init.d/motion file to add the status command
sed -i '99i\n\  status)\n      status_of_proc "$DAEMON" "$NAME" && exit 0 || exit $?\n    ;;' /etc/init.d/motion
sed -i 's|start\|stop\|restart\|reload|start\|stop\|status\|restart\|reload|g' /etc/init.d/motion
grep -C 2 "start|stop|status|restart|reload" /etc/init.d/motion

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
echo -e ${WHITE}"4. Set the designated recording directories owner to motion:motion"$(tput sgr0)
echo -e ${WHITE}"    sudo chown motion:motion ~/recordings/"$(tput sgr0)
echo -e ${WHITE}"5. Reboot"$(tput sgr0)
echo -e ${WHITE}""$(tput sgr0)

#Reset all attributes in case we changed anything
tput sgr0