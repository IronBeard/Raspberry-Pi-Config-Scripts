#!/bin/bash

#DESCRIPTION
#    .
#NOTES
#    File Name      : ConfigureSAMBA.sh
#    Author         : Gareth Philpott
#    Date           : 16/09/2017
#    Prerequisite   : samba samba-common-bin
#    Copyright 2017 - Gareth Philpott
#EXAMPLE
#    ./ConfigureSAMBA.sh

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

#Passwords - No spaces before or after the =
passpi=""
passgareth=""
passtoni=""

# Backup the config before editing
cp /etc/samba/smb.conf /etc/samba/smb.conf.bak
cp smb.conf /etc/samba/smb.conf

# Check the config for errors
# -s to suppress the carry on prompt
# -v to be verbose
testparm -s -v

# Add users
pass=$(perl -e 'print crypt($ARGV[0], "password")' $passgareth)
useradd -m -p $pass gareth -G users

pass=$(perl -e 'print crypt($ARGV[0], "password")' $passtoni)
useradd -m -p $pass toni -G users

# Add pi users to the SAMBA users - User must exist before adding to SAMBA
(echo "$passpi"; echo "$passpi") | smbpasswd -s -a pi
(echo "$passgareth"; echo "$passgareth") | smbpasswd -s -a gareth
(echo "$passtoni"; echo "$passtoni") | smbpasswd -s -a toni

# Add su to user
#visudo
# Add to the end of the file
echo 'gareth ALL=(ALL:ALL) ALL' | EDITOR='tee -a' visudo
echo 'toni ALL=(ALL:ALL) ALL' | EDITOR='tee -a' visudo

#User List
groups $(cut -f1 -d":" /etc/passwd) | sort

# Check Samba users
# -L to list users
# -v to be verbose
pdbedit -L
# Get more detail
pdbedit -L -v