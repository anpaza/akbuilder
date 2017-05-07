How to make the custom kernel to boot automatically
---------------------------------------------------

To make the custom kernel boot automatically we can use the trick used by
the LibreELEC Linux distribution to boot on X92.

The trick works as follows: during the first boot using the button inside
the AV jack it will modify the u-Boot configuration so that on every normal
boot it will try to load two files named kernel.img and dtb.img from either
a USB stick or SD card.

So, if we rename our boot*.img file into kernel.img (for compatibility with
LibreELEC), the LibreELEC modifications to u-Boot config will autoload our
modified kernel as well.


If you use LibreELEC
--------------------

If you use LibreELEC, you just have to rename boot*.img into kernel.img
on the USB stick or on the SD card, and that's all.


If you don't use LibreELEC
--------------------------

For convenience, we have included the aml_autoscript file from LibreELEC
(which does the above described modifications to u-Boot config).

So, you have to (on the USB stick or SD card):
    * Rename boot*.img into kernel.img
    * Copy aml_autoscript from this directory over the old one.

Then, you have to boot once with the button-inside-AV-jack pressed,
and then you just leave the USB stick / SD card in the slot, and it
will automatically boot the modified kernel on every boot.
