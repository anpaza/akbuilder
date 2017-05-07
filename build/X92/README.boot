What is it?
-----------

This is a modified kernel for X92 Android-TV box.
A list of changes compared to the original kernel may be found in the Changes file.


How to boot
-----------

Copy all files from the directory, corresponding to your box variant
(2G for boxes with 2Gb memory, 3G for boxes with 3Gb memory) to an
USB stick or SD card. Insert it into the respective slot.

Now press the button inside the AV jack with a toothpick or match,
disconnect the power connector and insert it back. Keep the button
pressed for relatively long time. If your USB stick has a LED, you
can see when it starts flashing - you can remove the toothpick.


What kernel is loaded?
----------------------

You can determine which kernel (stock or modified) is loaded by:

* initial 'boot' animation
* display content (modified kernel shows time/date/cpu temperature)
* the output of 'uname -r' command, for example from a PC:
    > adb connect 192.168.1.253 # the IP address of your X92
    > adb shell uname -r
