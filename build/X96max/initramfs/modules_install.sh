#!/system/bin/sh

MODDIR=/lib/modules/`uname -r`

# Если раздел /odm не смонтирован, мы всё испортим
grep -q "^[^ ]* /odm " /proc/mounts || exit 1

# Во избежание неверной работы при повторном запуске размонтируем зеркала
grep -q "^[^ ]* $MODDIR " /proc/mounts && umount $MODDIR
grep -q "^[^ ]* /vendor/lib/modules " /proc/mounts && umount /vendor/lib/modules

# Сделаем копию модулей ядра на разделе /odm
if [ ! -d /odm$MODDIR -o $MODDIR/modules.dep -nt /odm$MODDIR/modules.dep ] ; then
	mount -o remount,rw /odm

	# Если есть модули от другой версии kernel-zap, подметаем
	rm -rf `find /odm/lib/modules -name '*-zap-*'`

	# Копируем модули с initramfs на /odm чтобы не расходовать ОЗУ попусту
	mkdir -p /odm$MODDIR
	cp -a $MODDIR /odm$MODDIR/..

	mount -o remount,ro /odm
fi

# Освобождаем ОЗУ (файлы в /lib/modules находятся на tmpfs)
mount -o remount,rw /
rm -f $MODDIR/*
mount -o remount,ro /

# Отзеркалим модули из /odm/lib в /lib
mount --bind /odm$MODDIR $MODDIR
# ... а также в /vendor/lib
mount --bind /odm$MODDIR /vendor/lib/modules

# Даём добро на дальнейшую загрузку
setprop sys.modules_install 1

# Загрузим btusb т.к. у нас он зависит ещё от трёх драйверов
modprobe btusb
