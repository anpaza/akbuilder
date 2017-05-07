#!/system/bin/sh
# switch kernel modules depending on currently running kernel

if [ ".$1" == ".install" ] ; then
	# this hack is needed to have modules.sh running
	# even without the custom kernel & initramfs

	JUNK=/system/bin/ddrtest.sh
	cmp -s $0 $JUNK && exit 0

	mount -o remount,rw /system
	cp $0 $JUNK
	mount -o remount,ro /system

        # ddrtest was already launched, so continue to our job...
fi

# /mnt is tmpfs, so it's suitable for a quick flag file...
flag=/mnt/.modules_sh
[ -f $flag ] && exit 0
touch $flag

system_rw=0

# Check for first boot, move stock drivers to separate directory
if [ ! -L /system/lib/mali.ko ]; then
	system_rw=1
	mount -o remount,rw /system
	krel=3.14.29
	mkdir -p /system/lib/modules/$krel
	mv /system/lib/*.ko /system/lib/modules/$krel
fi

krel=`uname -r`
modir=/lib/modules/$krel
[ ! -d $modir ] && modir=/system/lib/modules/$krel
[ ! -d $modir ] && exit 1

for m in $modir/*.ko; do
	mn=`basename $m`
	lnk=`readlink /system/lib/$mn 2>/dev/null`

	[ "$m" == "$lnk" ] && continue
	[ "$system_rw" == "0" ] && system_rw=1 && mount -o remount,rw /system
	ln -fs $m /system/lib/$mn
done

[ "$system_rw" == "1" ] && mount -o remount,ro /system
rm -f $flag
