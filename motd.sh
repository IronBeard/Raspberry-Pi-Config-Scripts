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

echo -e ${WHITE}"Setting up the${GREEN} MOTD${WHITE} to display the Olympus domain${GREEN} MOTD${WHITE} style"$(tput sgr0)

#Add handling to revert back to original
#Remove whitespace
ACTION=$1
ACTION=${ACTION,,} #Make lower case
ACTION=${ACTION//[[:blank:]]/} #Remove spaces

if [ "$ACTION" = "" ] || [ "$ACTION" = "update" ]; then
  #Showing /etc/motd before the change
  ScreenLines
  echo -e ${WHITE}"Current ${NONE}/etc/motd${WHITE}:"$(tput sgr0)
  cat /etc/motd

  echo -e ${WHITE}""$(tput sgr0)
  ScreenLines
#May need to add a check in here and uninstall it if it is already there.
  echo -e ${WHITE}"Installing ${PURPLE}figlet"$(tput sgr0)
  sudo apt-get install -y figlet

  echo -e ${WHITE}""$(tput sgr0)
  ScreenLines
  echo -e ${WHITE}"Replacing current ${NONE}/etc/motd ${WHITE}with our MOTD for Olympus"$(tput sgr0)
  sudo bash -c "echo -en '\033[00;32m
                                 .~~.   .~~.
                                '\''. \\ '\'' '\'' / .'\'' \033[00;31m
                                 .~..~~~..~.
                                : .~.'\''~'\''.~. :
                               ~ (   ) (   ) ~
                              ( : '\''~'\''.~.'\''~'\'' : )
                               ~ .~ (   ) ~. ~
                                (  : '\''~'\'' :  )
                                 '\''~ .~~~. ~'\''
                                     '\''~'\'' \033[01;37m
' > /etc/motd"
  echo "$(figlet -c -w ${COLUMNS:-$(tput cols)} $HOSTNAME)" >> /etc/motd
  echo "" >> /etc/motd
  echo "" >> /etc/motd

  echo -e ${WHITE}""$(tput sgr0)
  ScreenLines
  echo -e ${WHITE}"Uninstalling ${PURPLE}figlet"$(tput sgr0)
  sudo apt-get purge -y figlet

  echo -e ${WHITE}"Replace complete"$(tput sgr0)

elif [ "$ACTION" = "revert" ]; then
  #Showing /etc/motd before the change
  echo -e ${WHITE}"Current ${NONE}/etc/motd${WHITE}:"$(tput sgr0)
  cat /etc/motd

  echo -e ${WHITE}""$(tput sgr0)
  echo -e ${WHITE}"Reset ${NONE}/etc/motd ${WHITE}to factory default"$(tput sgr0)
  sudo bash -c "echo '
The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.' > /etc/motd"

  echo -e ${WHITE}"Rollback complete"$(tput sgr0)

else
  echo -e ${WHITE}"ERROR: Incorrect action supplied."$(tput sgr0)
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
echo -e ${WHITE}"New ${NONE}/etc/motd${WHITE}:"$(tput sgr0)
cat /etc/motd

ScreenLines
echo -e ${WHITE}"MOTD setup complete"$(tput sgr0)