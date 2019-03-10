changequote(<<,>>)dnl
changecom(`', `')dnl
What is it?
-----------

This is a modified kernel for PLATFORM Android-TV box.
A list of changes compared to the original kernel may be found
in the file CHANGES.txt.


How to boot
-----------

Copy all files from the directory, corresponding to your box variant
(2G for boxes with 2Gb memory, 3G for boxes with 3Gb memory) to an
USB stick or SD card. Insert it into the respective slot.

Now press the button inside the AV jack with a toothpick or match,
disconnect the power connector and insert it back. Keep the button
pressed for relatively long time. If your USB stick has a LED, you
can see when it starts flashing - you can remove the toothpick.

After first successful boot the box will always try to load the new
kernel from USB/SD sticard. To return to the stock kernel, just remove
the sticard from the slot.

Also, if you boot into recovery mode (TWRP or stock recovery),
bootloader config is reset, thus the new kernel will not autoload
anymore. To restore kernel autoboot, just boot once again using the
toothpick trick.


What kernel is loaded?
----------------------

You can determine which kernel (stock or modified) is loaded by:

* initial 'boot' animation
* display content (modified kernel shows time/date/cpu temperature)
* the output of 'uname -r' command, for example from a PC:
    > adb connect 192.168.1.253 # the IP address of your PLATFORM
    > adb shell uname -r


How to flash it?
----------------

It is recommended first to check if the kernel works for you by
booting it directly from USB/SD sticard. If you don't want to
keep the sticard in slot on every boot, you can flash the kernel
into EMMC memory.

For this, first copy the respective UPDATE-*.zip to an USB/SD
sticard. DO NOT EXTRACT ANYTHING from the archive, just copy it!

Now, don't insert the sticard yet, boot into recovery (both system
recovery or TWRP are fine). Press the button at the bottom of
the AV jack with a match and pull out/insert back the power cord.

When recovery program loads, insert the sticard into the device.
Choose "Install" or "Install update". Select the UPDATE*.zip archive
you just copied to the sticard. During install, a backup copy of
your current kernel will be created.

If something went wrong, you can boot into recovery again and
run the installer again. It will detect the backup copy and will
uninstall instead of installing. After a successful restore,
the backup copy will be removed.
