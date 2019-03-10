
# --- # kernel-zap UPDATE un/install support script # --- #

BACKUP=/data/local/backup-kernel-zap

backup_failed() {
	ui_print "Failed to backup $1"
	rm -f $BACKUP/kernel.img $BACKUP/dtb.img
	exit 1
}

restore_failed() {
	ui_print "Failed to restore $1"
	exit 1
}

MNT_DATA=`grep -q '^/dev/block/data' /proc/mounts`
test -z "$MNT_DATA" || mount /dev/block/data /data

if test -f $BACKUP/.ok ; then
	ui_print "Restoring kernel from backup in $BACKUP"
	dd if=$BACKUP/kernel.img of=/dev/block/boot || restore_failed "kernel"
	dd if=$BACKUP/dtb.img of=/dev/dtb || restore_failed "dtb"
	rm -rf $BACKUP
	ui_print "Restore finished"
	exit 0
fi

ui_print "Creating kernel backup in $BACKUP"
mkdir -p $BACKUP
dd if=/dev/block/boot of=$BACKUP/kernel.img || backup_failed "kernel"
dd if=/dev/dtb of=$BACKUP/dtb.img || backup_failed "DTB"
touch $BACKUP/.ok
ui_print "Backup done"

test -z "$MNT_DATA" || umount /data

# --- --- --- --- --- --- --- --- --- --- --- --- --- --- #
