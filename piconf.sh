#!/bin/bash

#Functions
function ScreenLines {
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
}

calc_wt_size() {
  WT_HEIGHT=17
  WT_WIDTH=$(tput cols)

  if [ -z "$WT_WIDTH" ] || [ "$WT_WIDTH" -lt 60 ]; then
    WT_WIDTH=80
  fi
  if [ "$WT_WIDTH" -gt 178 ]; then
    WT_WIDTH=120
  fi
  WT_MENU_HEIGHT=$(($WT_HEIGHT-8))
}

set_config_var() {
  lua - "$1" "$2" "$3" <<EOF > "$3.bak"
local key=assert(arg[1])
local value=assert(arg[2])
local fn=assert(arg[3])
local file=assert(io.open(fn))
local made_change=false
for line in file:lines() do
  if line:match("^#?%s*"..key.."=.*$") then
    line=key.."="..value
    made_change=true
  end
  print(line)
end

if not made_change then
  print(key.."="..value)
end
EOF
mv "$3.bak" "$3"
}

get_config_var() {
  lua - "$1" "$2" <<EOF
local key=assert(arg[1])
local fn=assert(arg[2])
local file=assert(io.open(fn))
for line in file:lines() do
  local val = line:match("^#?%s*"..key.."=(.*)$")
  if (val ~= nil) then
    print(val)
    break
  end
end
EOF
}

do_finish() {
  exit 0
}

do_change_hostname() {
  whiptail --msgbox "\
Please note: RFCs mandate that a hostname's labels \
may contain only the ASCII letters 'a' through 'z' (case-insensitive), 
the digits '0' through '9', and the hyphen.
Hostname labels cannot begin or end with a hyphen. 
No other symbols, punctuation characters, or blank spaces are permitted.\
" 20 70 1

  CURRENT_HOSTNAME=`cat /etc/hostname | tr -d " \t\n\r"`
  ENTERED_HOSTNAME=$(whiptail --inputbox "Please enter a hostname" 20 60 "$CURRENT_HOSTNAME" 3>&1 1>&2 2>&3)

  #Remove whitespace from the hostname
  NEW_HOSTNAME=$ENTERED_HOSTNAME
  NEW_HOSTNAME=${NEW_HOSTNAME,,} #Make lower case
  NEW_HOSTNAME=${NEW_HOSTNAME//[[:blank:]]/} #Remove spaces

  #set the hostname
  if [ $? -eq 0 ]; then
    echo $NEW_HOSTNAME > /etc/hostname
    sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts
    ASK_TO_REBOOT=1
  fi
}

do_change_pass() {
  whiptail --msgbox "You will now be asked to enter a new password for the pi user" 20 60 1
  passwd pi &&
  whiptail --msgbox "Password changed successfully" 20 60 1
}

do_setup_motd() {
  whiptail --msgbox "Not available yet..." 20 60 1
}

do_install_airpi() {
  whiptail --msgbox "Not available yet..." 20 60 1
}

# $1 is 0 to disable camera, 1 to enable it
set_camera() {
  # Stop if /boot is not a mountpoint
  if ! mountpoint -q /boot; then
    return 1
  fi

  [ -e /boot/config.txt ] || touch /boot/config.txt

  if [ "$1" -eq 0 ]; then # disable camera
    set_config_var start_x 0 /boot/config.txt
    sed /boot/config.txt -i -e "s/^startx/#startx/"
    sed /boot/config.txt -i -e "s/^start_file/#start_file/"
    sed /boot/config.txt -i -e "s/^fixup_file/#fixup_file/"
  else # enable camera
    set_config_var start_x 1 /boot/config.txt
    CUR_GPU_MEM=$(get_config_var gpu_mem /boot/config.txt)
    if [ -z "$CUR_GPU_MEM" ] || [ "$CUR_GPU_MEM" -lt 128 ]; then
      set_config_var gpu_mem 128 /boot/config.txt
    fi
    sed /boot/config.txt -i -e "s/^startx/#startx/"
    sed /boot/config.txt -i -e "s/^fixup_file/#fixup_file/"
  fi
}

do_camera() {
  if [ ! -e /boot/start_x.elf ]; then
    whiptail --msgbox "Your firmware appears to be out of date (no start_x.elf). Please update" 20 60 2
    return 1
  fi
  whiptail --yesno "Enable support for Raspberry Pi camera?" 20 60 2 \
    --yes-button Disable --no-button Enable
  RET=$?
  if [ $RET -eq 0 ] || [ $RET -eq 1 ]; then
    ASK_TO_REBOOT=1
    set_camera $RET;
  else
    return 1
  fi
}

do_install_motion() {
  whiptail --msgbox "Not available yet..." 20 60 1
}

do_setup_network() {
  whiptail --msgbox "Not available yet..." 20 60 1
}

do_update() {
  whiptail --msgbox "Not available yet..." 20 60 1
}

do_about() {
  whiptail --msgbox "\
This tool provides a straight-forward way of doing initial
configuration of the Raspberry Pi. Although it can be run
at any time, some of the options may have difficulties if
you have heavily customised your installation.\
" 20 70 1
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

#echo -e ${WHITE}`date`$(tput sgr0)

#Ensure that the script has been run as root
if [ `whoami` != root ]; then
  echo -e ${WHITE}"Due to the nature of the changes that this script makes please run it as ${RED}root${WHITE} or by using ${RED}sudo"$(tput sgr0)
  exit
fi

#echo -e ${WHITE}""$(tput sgr0)

#Add Install of SendEmail, maybe bundle all the base packages into one single install option "Install ..."
calc_wt_size
while true; do
  FUN=$(whiptail --title "Raspberry Pi - Olympus Configuration/Installation Tool (piconf)" --menu "Configuration/Installation Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Finish --ok-button Select \
    "1 Rename Pi" "Rename this Pi" \
    "2 Change User Password" "Change password for the default user (pi)" \
    "3 Setup MOTD" "Customises the MOTD for this Pi" \
    "4 Install AirPi" "AirPi allows this Pi to act as an iTunes endpoint" \
    "5 Enable Camera" "Enable this Pi to work with the Raspberry Pi Camera" \
    "6 Install Motion" "Motion turns this Pi into a capable security camera" \
    "7 Setup Networking" "Configure the network on this Pi for the Olympus Domain" \
    "8 Update Pi" "Update this Pi's packages" \
    "9 About piconf" "Information about this configuration tool" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    do_finish
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      1\ *) do_change_hostname ;;
      2\ *) do_change_pass ;;
      3\ *) do_setup_motd ;;
      4\ *) do_install_airpi ;;
      5\ *) do_camera ;;
      6\ *) do_install_motion ;;
      7\ *) do_setup_network ;;
      8\ *) do_update ;;
      9\ *) do_about ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
  else
    exit 1
  fi
done