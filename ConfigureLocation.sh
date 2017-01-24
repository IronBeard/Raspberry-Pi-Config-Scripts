#!/bin/bash

locale
sed -i 's|en_GB.UTF-8 UTF-8|\# en_GB.UTF-8 UTF-8|g' /etc/locale.gen
sed -i 's|\# en_NZ.UTF-8 UTF-8|en_NZ.UTF-8 UTF-8|g' /etc/locale.gen
locale-gen
locale -a
locale
update-locale LANG=en_NZ.UTF-8
dpkg-reconfigure keyboard-configuration
  
echo "Pacific/Auckland" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata