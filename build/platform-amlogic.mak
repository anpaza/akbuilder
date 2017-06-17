# Platform-specific targets

# Compiler prefix for target platform
KERNEL_GCC_PREFIX ?= aarch64-linux-gnu-
# The directory prefix where to look for the AMLogic openlinux buildroot source code
AMLOGIC_BUILDROOT_DIR ?= ../buildroot_openlinux
# The directory prefix where to look for Linary GCC build
PLATFORM.CC_DIR ?= $(AMLOGIC_BUILDROOT_DIR)/toolchain/gcc/linux-x86/aarch64/gcc-linaro-aarch64-linux-gnu-4.9
# Kernel directory suffix (3.14 or 4.9)
PLATFORM.KERNEL_VER ?= 3.14

PLATFORM.KERNEL_CONFIG = $(PLATFORM.DIR)linux-$(PLATFORM.KERNEL_VER)/config
PLATFORM.KERNEL_PATCHES = \
	$(sort $(wildcard build/patches/linux-$(PLATFORM.KERNEL_VER)/*.patch)) \
	$(sort $(wildcard $(PLATFORM.DIR)linux-$(PLATFORM.KERNEL_VER)/*.patch))
# Make a link from '.' to 'customer' so that we can build dtbs
define PLATFORM.KERNEL_COPY
	ln -s $(call CFN,$(KERNEL.OUT)) $(KERNEL.OUT)customer
	ln -s $(call CFN,$(LINUX_VFD_DIR)/vfd) $(KERNEL.OUT)drivers/amlogic/input/

endef

# Use the DTS files from kernel tree
KERNEL.DTS.DIR = $(KERNEL.OUT)arch/arm64/boot/dts/amlogic/

KERNEL.DIR ?= $(AMLOGIC_BUILDROOT_DIR)/kernel/aml-$(PLATFORM.KERNEL_VER)
KERNEL.SUFFIX ?= -zap-5
KERNEL.ARCH = arm64
KERNEL.LOADADDR ?= 0x1080000
include build/kernel.mak

# Include AMLogic-specific drivers into initramfs
INITRAMFS.MODULES += dwc3.ko dwc_otg.ko

# Tell initramfs builder where the .ko files are located, if it needs them
INITRAMFS.DEP.dwc3.ko = $(KERNEL.OUT)drivers/usb/dwc3/dwc3.ko
INITRAMFS.DEP.dwc_otg.ko = $(KERNEL.OUT)drivers/amlogic/usb/dwc_otg/310/dwc_otg.ko

# Make known in-tree kernel modules depend on kernel-module
$(INITRAMFS.DEP.dwc3.ko) \
$(INITRAMFS.DEP.dwc_otg.ko): kernel-modules

# Include extra modules for all platforms
include build/platform-modules.mak

# If platform needs the Mali driver, build it
ifneq ($(PLATFORM.BUILD.KD_MALI),)
# The path to Mali kernel driver
KD_MALI.DIR ?= $(AMLOGIC_BUILDROOT_DIR)/hardware/aml-$(PLATFORM.KERNEL_VER)/arm/gpu/midgard/r13p0/kernel/drivers/gpu/arm/midgard
include build/kd-mali.mak
INITRAMFS.DEP.mali.ko = $(KD_MALI.FILE)
endif

# If platform needs the Wi-Fi driver, build it
ifneq ($(PLATFORM.BUILD.KD_AP6XXX),)
KD_AP6XXX.DIR ?= $(AMLOGIC_BUILDROOT_DIR)/hardware/aml-$(PLATFORM.KERNEL_VER)/wifi/broadcom/drivers/ap6xxx/bcmdhd_1_201_59_x
include build/kd-ap6xxx.mak
INITRAMFS.DEP.dhd.ko = $(KD_AP6XXX.FILE)
endif

# Build additional modules before building initramfs
$(eval $(PLATFORM.BUILD.EXTRA))

# Build our own initramfs if needed
ifneq ($(PLATFORM.BUILD.INITRAMFS),)
include build/initramfs.mak
endif

# Build Android boot.img if needed
ifneq ($(PLATFORM.BUILD.BOOTIMG),)
include build/bootimg.mak
endif

HELP += $(NL)bootfiles - Create the files needed to boot from SD card/USB stick

# To load from USB stick / SD card we need three files:
# boot.img, dtb.img and the u-Boot autoscript
.PHONY: bootfiles
bootfiles: $(OUT)$(BOOTIMG.FILE) $(OUT)dtb.img $(OUT)aml_autoscript

$(OUT)dtb.img: $(KERNEL.DTB)
	$(call CP,$<,$@)

$(OUT)aml_autoscript: $(PLATFORM.DIR)uboot-script-libreelec.txt
	sed -e 's/@BOOTIMG@/$(notdir $(OUT)$(BOOTIMG.FILE))/' $< > $@.tmp
	mkimage -T script -C none -n '$(PLATFORM) custom kernel autoscript' -d $@.tmp $@
	$(call RM,$@.tmp)
