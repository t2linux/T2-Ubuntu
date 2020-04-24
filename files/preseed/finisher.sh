#KERNEL_VERSION=5.4.0-25-generic
#APPLE_BCE_DRIVER_GIT_URL=https://github.com/aunali1/mbp2018-bridge-drv.git
#APPLE_BCE_DRIVER_BRANCH_NAME=aur
#APPLE_BCE_DRIVER_COMMIT_HASH=c884d9ca731f2118a58c28bb78202a0007935998
#APPLE_IB_DRIVER_GIT_URL=https://github.com/roadrunner2/macbook12-spi-driver.git
#APPLE_IB_DRIVER_BRANCH_NAME=mbp15
#APPLE_IB_DRIVER_COMMIT_HASH=90cea3e8e32db60147df8d39836bd1d2a5161871
#
#mkdir -p /opt/drivers
#mkdir -p "/lib/modules/${KERNEL_VERSION}/extra"
#
#git clone --single-branch --branch ${APPLE_BCE_DRIVER_BRANCH_NAME} ${APPLE_BCE_DRIVER_GIT_URL} /opt/drivers/apple-bce
#git -C /opt/drivers/apple-bce/ checkout ${APPLE_BCE_DRIVER_COMMIT_HASH}
#PATH=/usr/share/Modules/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/bin make -C /lib/modules/${KERNEL_VERSION}/build/ M=/opt/drivers/apple-bce modules
#
#git clone --single-branch --branch ${APPLE_IB_DRIVER_BRANCH_NAME} ${APPLE_IB_DRIVER_GIT_URL} /opt/drivers/touchbar
#git -C /opt/drivers/touchbar/ checkout ${APPLE_IB_DRIVER_COMMIT_HASH}
#PATH=/usr/share/Modules/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/bin make -C /lib/modules/${KERNEL_VERSION}/build/ M=/opt/drivers/touchbar modules
#
#cp -rf /opt/drivers/apple-bce/*.ko /lib/modules/${KERNEL_VERSION}/extra/
#cp -rf /opt/drivers/touchbar/*.ko /lib/modules/${KERNEL_VERSION}/extra/
#
#### Add custom drivers to be loaded at boot
#echo -e 'hid-apple\nbcm5974\nsnd-seq\nbce\napple_ibridge\napple_ib_tb' > /etc/modules-load.d/apple-bce.conf
#echo -e 'blacklist thunderbolt' > /etc/modprobe.d/blacklist.conf
#echo -e 'add_drivers+="hid_apple snd-seq apple-bce"\nforce_drivers+="hid_apple snd-seq apple-bce"' > /etc/dracut.conf
#/usr/sbin/depmod -a ${KERNEL_VERSION}
#ls -la /boot/
#dracut -f /boot/initramfs-$KERNEL_VERSION.img $KERNEL_VERSION
#
### Copy audio config files
#mkdir -p /usr/share/alsa/cards/
#mv -fv /tmp/setup_files/audio/AppleT2.conf /usr/share/alsa/cards/AppleT2.conf
#mv -fv /tmp/setup_files/audio/apple-t2.conf /usr/share/pulseaudio/alsa-mixer/profile-sets/apple-t2.conf
#mv -fv /tmp/setup_files/audio/91-pulseaudio-custom.rules /usr/lib/udev/rules.d/91-pulseaudio-custom.rules
