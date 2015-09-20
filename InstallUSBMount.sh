# Install USBMount
apt-get install -y usbmount ntfs-3g

# Backup config
cp /etc/usbmount/usbmount.conf /etc/usbmount/usbmount.conf.bak

# Alter the usbmount.conf to include NTFS
sed -i 's|FILESYSTEMS="vfat ext2 ext3 ext4 hfsplus"|FILESYSTEMS="vfat ext2 ext3 ext4 hfsplus ntfs"|g' /etc/usbmount/usbmount.conf
sed -i 's|FS_MOUNTOPTIONS=""|FS_MOUNTOPTIONS="-fstype=ntfs,gid=users,umask=0 -fstype=vfat,gid=users,umask=0 -fstype=ext4,gid=users,umask=0"|g' /etc/usbmount/usbmount.conf