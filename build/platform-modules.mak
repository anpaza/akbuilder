# Common kernel modules for all platforms
INITRAMFS.MODULES += ch341.ko cp210x.ko ftdi_sio.ko pl2303.ko
# overlay.ko

# Tell initramfs builder where the .ko files are located, if it needs them
INITRAMFS.DEP.overlay.ko = $(KERNEL.OUT)fs/overlayfs/overlay.ko
INITRAMFS.DEP.ch341.ko = $(KERNEL.OUT)drivers/usb/serial/ch341.ko
INITRAMFS.DEP.cp210x.ko = $(KERNEL.OUT)drivers/usb/serial/cp210x.ko
INITRAMFS.DEP.ftdi_sio.ko = $(KERNEL.OUT)drivers/usb/serial/ftdi_sio.ko
INITRAMFS.DEP.pl2303.ko = $(KERNEL.OUT)drivers/usb/serial/pl2303.ko

# Make known in-tree kernel modules depend on kernel-module
$(INITRAMFS.DEP.overlay.ko) \
$(INITRAMFS.DEP.ch341.ko) \
$(INITRAMFS.DEP.cp210x.ko) \
$(INITRAMFS.DEP.ftdi_sio.ko) \
$(INITRAMFS.DEP.pl2303.ko): kernel-modules
