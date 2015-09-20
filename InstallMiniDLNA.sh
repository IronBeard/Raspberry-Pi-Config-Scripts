# Install MiniDLNA
apt-get -y install minidlna

# Backup config
cp /etc/minidlna.conf /etc/minidlna.conf.bak

# Edit minidlna.conf to add the media locations
sed -i 's|media_dir=/var/lib/minidlna|media_dir=V,/media/usb0\nmedia_dir=V,/media/usb1\nmedia_dir=V,/media/usb2\nmedia_dir=V,/media/usb3\nmedia_dir=V,/media/usb4\nmedia_dir=V,/media/usb5\nmedia_dir=V,/media/usb6\nmedia_dir=V,/media/usb7\n|g' /etc/minidlna.conf
sed -i 's|#friendly_name=|friendly_name=Raspberry Pi|g' /etc/minidlna.conf
sed -i 's|#inotify=yes|inotify=yes|g' /etc/minidlna.conf

# Stop and Start the miniDLNA service
service minidlna restart

# Generate minidlna's database
sudo minidlna -R