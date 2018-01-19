#!/bin/bash

#DESCRIPTION
#    .
#NOTES
#    File Name      : ConfigureHostAPD.sh
#    Author         : Gareth Philpott
#    Date           : 16/09/2017
#    Prerequisite   : hostapd isc-dhcp-server iptables-persistent
#    Copyright 2017 - Gareth Philpott
#EXAMPLE
#    ./ConfigureHostAPD.sh

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

echo -e ${WHITE}"Checking for prerequisites"$(tput sgr0)
packages="hostapd isc-dhcp-server iptables-persistent"

for package in $packages; do
    dpkg -s "$package" >/dev/null 2>&1 || {
		apt-get -y install hostapd isc-dhcp-server iptables-persistent
}
done

echo -e ${WHITE}"Backup ${PURPLE}dhcpcd ${WHITE}config for rollback"$(tput sgr0)
cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.bak
echo -e ${WHITE}"Using SED to edit ${LIGHTBLUE}dhcpd.conf ${WHITE}to change the:"$(tput sgr0)
echo -e ${WHITE}"    ${GREEN}option domain-name ${WHITE}commented out"$(tput sgr0)
sed -i 's|option domain-name "example.org";|\#option domain-name "example.org";|g' /etc/dhcp/dhcpd.conf
echo -e ${WHITE}"    ${GREEN}option domain-name-servers ${WHITE}commented out"$(tput sgr0)
sed -i 's|option domain-name-servers ns1.example.org, ns2.example.org;|\#option domain-name-servers ns1.example.org, ns2.example.org;|g' /etc/dhcp/dhcpd.conf
echo -e ${WHITE}"    ${GREEN}authoritative ${WHITE}uncommented"$(tput sgr0)
sed -i 's|#authoritative;|authoritative;|g' /etc/dhcp/dhcpd.conf

echo -e ${WHITE}"    ${GREEN}DHCP configuration ${WHITE}added"$(tput sgr0)
bash -c "echo 'subnet 192.168.42.0 netmask 255.255.255.0 {
	range 192.168.42.200 192.168.42.254;
	option broadcast-address 192.168.42.255;
	option routers 192.168.42.1;
	default-lease-time 600;
	max-lease-time 7200;
	option domain-name "local";
	option domain-name-servers 8.8.8.8, 8.8.4.4;
}
' >> /etc/dhcp/dhcpd.conf"

echo -e ${WHITE}"Backup ${PURPLE}isc-dhcp-server ${WHITE}config for rollback"$(tput sgr0)
cp /etc/default/isc-dhcp-server /etc/default/isc-dhcp-server.bak
echo -e ${WHITE}"Using SED to edit ${LIGHTBLUE}isc-dhcp-server ${WHITE}to change the:"$(tput sgr0)
echo -e ${WHITE}"    ${GREEN}INTERFACES ${WHITE}to use wlan0"$(tput sgr0)
sed -i 's|INTERFACES=""|INTERFACES="wlan0"|g' /etc/default/isc-dhcp-server

echo -e ${WHITE}"Setting up${GREEN} Wired${WHITE} and${GREEN} WIFI${WHITE} adapters"$(tput sgr0)
echo -e ${WHITE}"Replacing current ${NONE}/etc/network/interfaces ${WHITE}with our network config for Olympus"$(tput sgr0)
bash -c "echo '# interfaces(5) file used by ifup(8) and ifdown(8)

# Please note that this file is written to be used with dhcpcd
# For static IP, consult /etc/dhcpcd.conf and 'man dhcpcd.conf'

# Include files from /etc/network/interfaces.d:
source-directory /etc/network/interfaces.d

auto lo
iface lo inet loopback

iface eth0 inet manual

allow-hotplug wlan0
iface wlan0 inet static
  address 192.168.42.1
  netmask 255.255.255.0
' > /etc/network/interfaces"

echo -e ${WHITE}"Setting the IP Address in the shell"$(tput sgr0)
ifconfig wlan0 192.168.42.1

echo -e ${WHITE}"Using the shell to create ${LIGHTBLUE}hostapd.conf ${WHITE}with Olympus settings"$(tput sgr0)
bash -c "echo 'interface=wlan0
driver=nl80211
ssid=Boreas
country_code=US
hw_mode=g
channel=6
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=I love my wife
wpa_key_mgmt=WPA-PSK
wpa_pairwise=CCMP
wpa_group_rekey=86400
ieee80211n=1
wme_enabled=1' > /etc/hostapd/hostapd.conf"

echo -e ${WHITE}"Backup ${PURPLE}hostapd ${WHITE}config for rollback"$(tput sgr0)
cp /etc/default/hostapd /etc/default/hostapd.bak
echo -e ${WHITE}"Using SED to edit ${LIGHTBLUE}hostapd ${WHITE}to change the:"$(tput sgr0)
echo -e ${WHITE}"    ${GREEN}DAEMON_CONF ${WHITE}to point to the ${LIGHTBLUE}hostapd.conf"$(tput sgr0)
sed -i 's|DAEMON_CONF=""|\DAEMON_CONF="/etc/hostapd/hostapd.conf"|g' /etc/hostapd/hostapd.conf

echo -e ${WHITE}"Backup ${PURPLE}hostapd ${WHITE}config for rollback"$(tput sgr0)
cp /etc/init.d/hostapd /etc/init.d/hostapd.bak
echo -e ${WHITE}"Using SED to edit ${LIGHTBLUE}hostapd ${WHITE}to change the:"$(tput sgr0)
echo -e ${WHITE}"    ${GREEN}DAEMON_CONF ${WHITE}to point to ${LIGHTBLUE}hostapd"$(tput sgr0)
sed -i 's|DAEMON_CONF=|DAEMON_CONF=/etc/hostapd/hostapd.conf|g' /etc/init.d/hostapd

echo -e ${WHITE}"Using printf to edit ${LIGHTBLUE}sysctl.conf ${WHITE}to start IP forwarding on boot up"$(tput sgr0)
printf "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

echo -e ${WHITE}"Starting IP forwarding"$(tput sgr0)
sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

echo -e ${WHITE}"Create the network translation between the ethernet port ${YELLOW}eth0 ${WHITE}and the wifi port ${YELLOW}wlan0"$(tput sgr0)
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT
iptables -t nat -S
iptables -S

echo -e ${WHITE}"Save the translation setup so it triggers on boot"$(tput sgr0)
sh -c "iptables-save > /etc/iptables/rules.v4"

echo -e ${WHITE}"Set the services to run on boot"$(tput sgr0)
update-rc.d hostapd enable
update-rc.d isc-dhcp-server enable

echo -e ${WHITE}"Install Complete"$(tput sgr0)