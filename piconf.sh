#!/bin/bash

ASK_TO_REBOOT=0

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

get_init_sys() {
  if command -v systemctl > /dev/null && systemctl | grep -q '\-\.mount'; then
    SYSTEMD=1
  elif [ -f /etc/init.d/cron ] && [ ! -h /etc/init.d/cron ]; then
    SYSTEMD=0
  else
    echo "Unrecognised init system"
    return 1
  fi
}

do_expand_rootfs() {
  get_init_sys
  if [ $SYSTEMD -eq 1 ]; then
    ROOT_PART=$(mount | sed -n 's|^/dev/\(.*\) on / .*|\1|p')
  else
    if ! [ -h /dev/root ]; then
      whiptail --msgbox "Woah, /dev/root does not exist or is not a symlink. Don't know how to expand" 20 60 2
      return 0
    fi
    ROOT_PART=$(readlink /dev/root)
  fi

  PART_NUM=${ROOT_PART#mmcblk0p}
  if [ "$PART_NUM" = "$ROOT_PART" ]; then
    whiptail --msgbox "$ROOT_PART is not an SD card. Don't know how to expand" 20 60 2
    return 0
  fi

  # NOTE: the NOOBS partition layout confuses parted. For now, let's only
  # agree to work with a sufficiently simple partition layout
  if [ "$PART_NUM" -ne 2 ]; then
    whiptail --msgbox "Your partition layout is not currently supported by this tool. You are probably using NOOBS, in which case your root filesystem is already expanded anyway." 20 60 2
    return 0
  fi

  LAST_PART_NUM=$(parted /dev/mmcblk0 -ms unit s p | tail -n 1 | cut -f 1 -d:)
  if [ $LAST_PART_NUM -ne $PART_NUM ]; then
    whiptail --msgbox "$ROOT_PART is not the last partition. Don't know how to expand" 20 60 2
    return 0
  fi

  # Get the starting offset of the root partition
  PART_START=$(parted /dev/mmcblk0 -ms unit s p | grep "^${PART_NUM}" | cut -f 2 -d: | sed 's/[^0-9]//g')
  [ "$PART_START" ] || return 1
  # Return value will likely be error for fdisk as it fails to reload the
  # partition table because the root fs is mounted
  fdisk /dev/mmcblk0 <<EOF
p
d
$PART_NUM
n
p
$PART_NUM
$PART_START

p
w
EOF
  ASK_TO_REBOOT=1

  # now set up an init.d script
cat <<EOF > /etc/init.d/resize2fs_once &&
#!/bin/sh
### BEGIN INIT INFO
# Provides:          resize2fs_once
# Required-Start:
# Required-Stop:
# Default-Start: 3
# Default-Stop:
# Short-Description: Resize the root filesystem to fill partition
# Description:
### END INIT INFO

. /lib/lsb/init-functions

case "\$1" in
  start)
    log_daemon_msg "Starting resize2fs_once" &&
    resize2fs /dev/$ROOT_PART &&
    update-rc.d resize2fs_once remove &&
    rm /etc/init.d/resize2fs_once &&
    log_end_msg \$?
    ;;
  *)
    echo "Usage: \$0 start" >&2
    exit 3
    ;;
esac
EOF
  chmod +x /etc/init.d/resize2fs_once &&
  update-rc.d resize2fs_once defaults &&
  if [ "$INTERACTIVE" = True ]; then
    whiptail --msgbox "Root partition has been resized.\nThe filesystem will be enlarged upon the next reboot" 20 60 2
  fi
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

do_change_locale() {
#  dpkg-reconfigure locales
  #Check where we are at now
  locale
  #Use sed to comment en_GB.UTF-8 UTF-8 and uncomment en_NZ.UTF-8 UTF-8
  sed -i 's|en_GB.UTF-8 UTF-8|\# en_GB.UTF-8 UTF-8|g' /etc/locale.gen
  sed -i 's|\# en_NZ.UTF-8 UTF-8|en_NZ.UTF-8 UTF-8|g' /etc/locale.gen
  #Generate the locales
  locale-gen
  #Check the available locales
  locale -a
  #Check what has been set
  locale
  #Update locale
  update-locale LANG=en_NZ.UTF-8
  dpkg-reconfigure keyboard-configuration
}

do_change_timezone() {
#  dpkg-reconfigure tzdata
  echo "Pacific/Auckland" > /etc/timezone
  dpkg-reconfigure -f noninteractive tzdata
}

do_change_location() {
  do_change_locale
  do_change_timezone
}

do_memory_split() {
  set_config_var gpu_mem "16" /boot/config.txt
}

do_finish() {
  disable_raspi_config_at_boot
  if [ $ASK_TO_REBOOT -eq 1 ]; then
    whiptail --yesno "Would you like to reboot now?" 20 60 2
    if [ $? -eq 0 ]; then # yes
      sync
      reboot
    fi
  fi
  exit 0
}

do_setup_pi() {
  # Rename the Pi, needs to be done FIRST!!!!
  do_change_hostname
  # Expand the Filesystem to the full SD card
  do_expand_rootfs
  # set language and timezone
  do_change_location
  # Set the Memory split
  do_memory_split
  # Disable the raspi_config reminder
  disable_raspi_config_at_boot
  
  ASK_TO_REBOOT=1
}

do_default_packages() {
  # Setup Domain Networking
  ./setupNetworking.sh
  # Set the motd to the Domain default
  ./motd.sh
  # Install monit to allow network monitoring of the Pi
  ./InstallMonit.sh
  # Install usbmount and ntfs-3g
  ./InstallUSBMount.sh
  # Install samba (Not yet implemented)
  # Remove the unused wolfram-engine, minecraft-pi and sonic-pi
  apt-get purge -y wolfram-engine minecraft-pi sonic-pi
  apt-get autoremove -y
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

disable_raspi_config_at_boot() {
  if [ -e /etc/profile.d/raspi-config.sh ]; then
    rm -f /etc/profile.d/raspi-config.sh
    sed -i /etc/inittab \
      -e "s/^#\(.*\)#\s*RPICFG_TO_ENABLE\s*/\1/" \
      -e "/#\s*RPICFG_TO_DISABLE/d"
    telinit q
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

# Custom Installers
do_install_minidlna() {
  ./InstallMiniDLNA.sh
  whiptail --msgbox "MiniDLNA Installation Complete!" 20 60 1
}

do_install_airpi() {
  ./InstallAirPi.sh
  whiptail --msgbox "AirPi Installation Complete!" 20 60 1
}

do_install_motion() {
  do_camera
  ./InstallMotion.sh
  whiptail --msgbox "motion Installation Complete!" 20 60 1
}

do_update() {
  ./updatePi.sh
  whiptail --msgbox "Pi Updated!" 20 60 1
}

do_about() {
  whiptail --msgbox "\
This tool is a customised version of the raspi-config
designed to set the Pi up for use on the Olumpus Domain.
The setup option does the following:
Renames the Pi
Expand the Filesystem to the full SD card
Sets the language and timezone to NZ
Sets the Memory split to 16
Sets up the Domain Networking including wireless
Sets the motd to the Domain default
Installs monit to allow network monitoring of the Pi
Removes the unused wolfram-engine and minecraft-pi
and finally disables the raspi_config reminder\
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

#Add Install of SendEmail
calc_wt_size
while true; do
  FUN=$(whiptail --title "Raspberry Pi - Olympus Configuration/Installation Tool (piconf)" --menu "Configuration/Installation Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Finish --ok-button Select \
    "01 Setup Pi" "Setup the  Pi to run on the Olympus Domain" \
    "02 Install default packages" "Install all of the default packages on this Pi" \
    "03 Change User Password" "Change password for the default user (pi)" \
    "04 Install MiniDLNA" "MiniDLNA allows this Pi to act as a DLNA server" \
    "05 Install AirPi" "AirPi allows this Pi to act as an iTunes endpoint" \
    "06 Enable Camera" "Enable this Pi to work with the Raspberry Pi Camera" \
    "07 Install Motion" "Motion turns this Pi into a capable security camera" \
    "08 Update Pi" "Update this Pi's packages" \
    "09 About piconf" "Information about this configuration tool" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    do_finish
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      01\ *) do_setup_pi ;;
      02\ *) do_default_packages ;;
      03\ *) do_change_pass ;;
      04\ *) do_install_minidlna ;;
      05\ *) do_install_airpi ;;
      06\ *) do_camera ;;
      07\ *) do_install_motion ;;
      08\ *) do_update ;;
      09\ *) do_about ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
  else
    exit 1
  fi
done