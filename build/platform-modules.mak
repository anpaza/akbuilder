# Common kernel modules for all platforms
INITRAMFS.MODULES += ch341.ko cp210x.ko ftdi_sio.ko pl2303.ko
# overlay.ko

# Tell initramfs builder where the .ko files are located, if it needs them
# Make known in-tree kernel modules depend on kernel-module
$(foreach _,$(shell grep -v '^[[:space:]]*#' build/platform-modules.txt),\
$(eval INITRAMFS.DEP.$(notdir $_)=$(KERNEL.OUT)$_)\
$(eval $$(INITRAMFS.DEP.$(notdir $_)): kernel-modules))
