#!/bin/bash

# Restart the miniDLNA service and rescan the media.
# This would normally be done when files are copied to the device
# however a complete replacement of the files seems to confuse it.

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

echo -e ${WHITE}"Rescanning ${PURPLE}miniDLNA ${WHITE} media"$(tput sgr0)
minidlna -R
service minidlna restart
echo -e ${WHITE}"Depending on the size of the media archive this could take some time."$(tput sgr0)
