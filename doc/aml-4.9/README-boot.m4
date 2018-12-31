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
(2G for boxes with 2Gb memory, 3G for boxes with 3Gb memory and so on)
to an USB stick or SD card. Insert it into the respective slot.

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
