#!/bin/bash

#DESCRIPTION
#    .
#NOTES
#    File Name      : ConfigureMOTD.sh
#    Author         : Gareth Philpott
#    Date           : 14/10/2017
#    Prerequisite   : figlet
#    Copyright 2017 - Gareth Philpott
#EXAMPLE
#    ./ConfigureMOTD.sh

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

echo -e ${WHITE}"Setting up the${GREEN} MOTD${WHITE} to display the Olympus domain${GREEN} MOTD${WHITE} style"$(tput sgr0)

echo -e ${WHITE}"Current ${NONE}/etc/motd${WHITE}:"$(tput sgr0)
cat /etc/motd

echo -e ${WHITE}"Replacing current ${NONE}/etc/motd ${WHITE}with our MOTD for Olympus"$(tput sgr0)
bash -c "echo -en '\033[00;32m
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
echo -e ${WHITE}"Adding extra space to ${NONE}/etc/motd ${WHITE}so it displays correctly"$(tput sgr0)
echo "" >> /etc/motd
echo "" >> /etc/motd

echo -e ${WHITE}"New ${NONE}/etc/motd${WHITE}:"$(tput sgr0)
cat /etc/motd

echo -e ${WHITE}"MOTD setup complete"$(tput sgr0)