changequote(<<,>>)dnl
changecom(`', `')dnl
The difference between the modified and the stock PLATFORM kernel:

  * Modified kernel is based on the AMLogic kernel source version 4.9.113.
    Stock kernel is version 4.9.76.

ifelse(PLATFORM, <<X96max>>, <<dnl
  * The LED display driver (named 'vfd') has been rewritten from scratch,
    since the AMLogic sources do not contain it.
    The driver in modified kernel is way more advanced.
    To drive the LED display there's a daemon running now in background named vfdd.
    It is placed in boot.img (on initramfs), so it will start automatically only
    when you boot the modified kernel.

    In current configuration vfdd displays on the LED display sequentially
    the current time (9 seconds), then current date as "month day" (e.g. 05 09 - May 9),
    then current CPU temperature in degrees Celsius. Also the following blinking icons
    are used to show disk accesses:

        USB     blinks when reading from USB storage
        APPS    blinks when writing to USB storage
        CARD    blinks when reading from internal memory
        SETUP   blinks when writing to internal memory
        HDMI    displays HDMI state

    The source code for driver and daemon is available separately from the GitHub:
    https://github.com/anpaza/linux_vfd

    The configuration file for vfdd daemon is /vfdd.ini. If you want to customize it,
    copy it to /etc/. On next reboot, vfdd will automatically load /etc/vfdd.ini.
>>)dnl

  * Added NFS and SMB filesystem support drivers. To use them, you need the respective
    user-mode utilites. This is a work in progress.

  * Added kernel modules cp210x.ko, pl2303.ko, ch341.ko, ftdi_sio.ko, for USB-UART dongles,
    often used to connect simple devices like Arduino etc to computers. Since Android misses
    the udev daemon, you'll have to load the drivers manually, or you can load them at boot
    time by creating a script in /etc/init.d (who's name starts with digits) with a command like

        modprobe cp210x.ko (or pl2303.ko etc)

dnl  * Support for hard disks in Windows Dynamic Disk format has been enabled in this kernel.
dnl    Details about using Dynamic Disks in Android:
dnl    https://translate.google.com/translate?hl=ru&sl=ru&tl=en&u=https%3A%2F%2F4pda.ru%2Fforum%2Findex.php%3Fshowtopic%3D773971%26view%3Dfindpost%26p%3D62595635
dnl
dnl  * The hardware noise reduction is disabled by default, since it results in the so-called
dnl    "ghost/smoky effect" on dark scenes (/sys/module/di/parameters/nr2_en=0).
dnl
  * Added automatic framerate when using the hardware video decoder. To implement this
    we introduce a new daemon named afrd which runs in background and reacts to kernel
    broadcasts about starting and finishing video play.

    The configuration file for afrd is /afrd.ini, if you want to change it, copy it first
    to /etc/afrd.ini; the daemon will prefer it over /afrd.ini if it exists.

    The source code for automatic framerate daemon is available separately from the GitHub:
    https://github.com/anpaza/afrd
