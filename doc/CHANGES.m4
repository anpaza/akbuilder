changequote(<<,>>)dnl
changecom(`', `')dnl
The difference between the modified and the stock PLATFORM kernel:

  * Modified kernel is based on the AMLogic kernel source released on 16th May 2017.
    Stock kernel is based on an older AMLogic kernel source (Oct-2016 or so).
ifelse(<<PLATFORM>>, <<X92>>, <<
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

        USB - blinks when reading from USB storage
        APPS - blinks when writing to USB storage
        CARD - blinks when reading from internal memory
        SETUP - blinks when writing to internal memory

    This driver and daemon is available separately from the GitHub:
    https://github.com/anpaza/linux_vfd
>>)
  * Implemented colorspace force mode for HDMI output. Now you can force one of
    the following output modes:

        RGB444 - "usual" mode as used by all computer monitors. 8 bit for every
                 of the R,G,B components, 24 bits per pixel.
        YUV444 - also known as YCbCr 4:4:4, high-quality video output mode,
                 Y,U,V components (brightness Y and two chromatic values U & V)
                 use 8 bit per every pixel, 24 bits per pixel.
        YUV422 - also known as YCbCr 4:2:2, standard mode, used for encoding in MPEG
                 and JPEG standards, the Y component (brightness) is defined for every
                 pixel, the U and V components are defined once for every two horizontally
                 adjanced pixels. 32 bits per 2 pixels, or 16 bits per pixel.
        YUV420 - also known as YCbCr 4:2:0, lower-quality mode used with limited bandwidth.
                 Brightness Y is defined for every pixel, but chroma values U & V are
                 defined once per every group of 2x2 pixels.
                 48 bits per 4 pixels, or 12 bits per pixel.

    To change the current mode, write the name of desired mode into the sysfs attribute
    force_color_space:

        echo rgb444 > /sys/class/amhdmitx/amhdmitx0/force_color_space

    To restore default mode (autodetect using TV EDID data), write AUTO to this attribute:

        echo auto > /sys/class/amhdmitx/amhdmitx0/force_color_space

  * Implemented color depth switching for HDMI output:

	echo 0  > /sys/class/amhdmitx/amhdmitx0/force_color_depth
	echo 24 > /sys/class/amhdmitx/amhdmitx0/force_color_depth
	echo 30 > /sys/class/amhdmitx/amhdmitx0/force_color_depth
	echo 36 > /sys/class/amhdmitx/amhdmitx0/force_color_depth
	echo 48 > /sys/class/amhdmitx/amhdmitx0/force_color_depth

    The default value is 0, which gives same behaviour as stock kernel
    (always 24 bits per pixel).

  * Implemented color quantization range switching
    (see HDMI 1.3 specs, chapter 6.6 "Video Quantization Ranges"):

        echo MODE > /sys/class/amhdmitx/amhdmitx0/force_color_range

    where MODE is one of:

        default - for RGB colors range from 16 to 235 (below 16 - black, above 235 - white)
                  for YUB colors (video) - Y from 16 to 235, Cb and Cr - from 16 to 240
        limited - for RGB colors range from 16 to 240
                  for YUB colors (video) - Y from 16 to 235, Cb and Cr - from 16 to 240
        full    - for RGB colors range from 1 to 254 (standard does not allow 0 and 255)
                  for YUB colors (video) - from 1 to 254
        all     - for RGB colors range from 0 to 255 (non-standard)
                  for YUB colors (video) - from 0 to 255

    After rebooting the mode is "default".

  * Added kernel module overlay.ko - overlay file system support.
    More details about overlayfs: https://en.wikipedia.org/wiki/OverlayFS
    For now it is not used, but I have plans about it.
