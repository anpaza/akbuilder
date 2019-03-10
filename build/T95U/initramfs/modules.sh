#!/system/bin/sh
# switch kernel modules depending on currently running kernel

system_is_rw=0

function system_rw() {
	if [ "$system_is_rw" == "0" ] ; then
		system_is_rw=1
		mount -o remount,rw /system
	fi
}

if [ ".$1" == ".install" ] ; then
	# this hack is needed to have modules.sh running
	# even without the custom kernel & initramfs

	JUNK=/system/bin/ddrtest.sh
	cmp -s $0 $JUNK && exit 0

	system_rw
	cp $0 $JUNK
	mount -o remount,ro /system

	exit 0
fi

# /dev is tmpfs, so it's suitable for a quick flag file...
flag=/dev/.modules_sh
[ -f $flag ] && exit 0
touch $flag

krel=`uname -r`
# dhd.ko is loaded by Android at late stage (when WiFi is enabled)
mods="dhd.ko"

if [ -d /lib/modules/$krel ] ; then
	# running a modified kernel
	for m in $mods ; do
		l=`readlink /system/lib/$m 2>/dev/null`
		if [ "$l" != "/lib/modules/$krel/$m" ] ; then
			system_rw
			# if module is not a link, it's the stock driver
			if [ ! -L /system/lib/$m ] ; then
				mv /system/lib/$m /system/lib/$m.stock
			fi
			ln -fs "/lib/modules/$krel/$m" "/system/lib/$m"
		fi
	done
else
	# running the stock kernel
	for m in $mods ; do
		# If module is a link, replace by stock driver
		if [ -L "/system/lib/$m" ]; then
			system_rw
			rm -f "/system/lib/$m"
			mv /system/lib/$m.stock /system/lib/$m
		fi
	done
fi

[ "$system_is_rw" == "1" ] && mount -o remount,ro /system
rm -f $flag
