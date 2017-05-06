# Platform-specific targets

# Compiler prefix for target platform
KERNEL_GCC_PREFIX ?= aarch64-linux-gnu-
# The directory prefix where to look for the AMLogic openlinux buildroot source code
AMLOGIC_BUILDROOT_DIR ?= ../buildroot-openlinux-20170310
# The directory for the linux_vfd project (https://github.com/anpaza/linux_vfd)
LINUX_VFD_DIR ?= ../linux_vfd
# The directory prefix where to look for Linary GCC build
LINARO_GCC_DIR ?= $(AMLOGIC_BUILDROOT_DIR)/toolchain
# Kernel directory suffix (3.14 or 4.9)
PLATFORM_KERNEL_VER ?= 3.14

# /// automatically find the required components under the dir prefixes defined above /// #

PLATFORM_CC_DIR ?= $(word 1,$(foreach _,$(shell find $(LINARO_GCC_DIR) -type d -name 'gcc-linaro-*aarch64*'),$(call CHECK_CC_DIR,$_)))

# Check if C Compiler directory is valid
CHECK_CC_DIR = $(if $(wildcard $1/bin/$(KERNEL_GCC_PREFIX)gcc),$1)

PLATFORM_KERNEL_CONFIG = build/$(PLATFORM)/kernel/config-$(PLATFORM_KERNEL_VER)
PLATFORM_KERNEL_PATCHES = $(wildcard build/$(PLATFORM)/kernel/linux-$(PLATFORM_KERNEL_VER)-*.patch)
#PLATFORM_KERNEL_EXTRASRC = build/$(PLATFORM)/kernel/src-$(PLATFORM_KERNEL_VER)
# Make a link from '.' to 'customer' so that we can build dtbs
define PLATFORM_KERNEL_COPY
	ln -s $(call CFN,$(KERNEL.OUT)) $(KERNEL.OUT)customer
	ln -s $(call CFN,$(LINUX_VFD_DIR)/vfd) $(KERNEL.OUT)drivers/amlogic/input/

endef

# Use the DTS files from kernel tree
KERNEL.DTS ?= gxm_x92_2g.dts
KERNEL.DTS.DIR = $(KERNEL.OUT)arch/arm64/boot/dts/amlogic/

# One kernel to rule them all...
KERNEL.DIR ?= $(AMLOGIC_BUILDROOT_DIR)/kernel/aml-$(PLATFORM_KERNEL_VER)
KERNEL.SUFFIX ?= -zap-1
KERNEL.ARCH = arm64
KERNEL.LOADADDR ?= 0x1080000
include build/kernel.mak

# Also we want the out-of-tree kernel drivers
KD_MALI.DIR ?= $(AMLOGIC_BUILDROOT_DIR)/hardware/aml-$(PLATFORM_KERNEL_VER)/arm/gpu/midgard/r13p0/kernel/drivers/gpu/arm/midgard
include build/kd-mali.mak

KD_AP6XXX.DIR ?= $(AMLOGIC_BUILDROOT_DIR)/hardware/aml-$(PLATFORM_KERNEL_VER)/wifi/broadcom/drivers/ap6xxx/bcmdhd_1_201_59_x
include build/kd-ap6xxx.mak

# and we want the 32-bit ARM daemon for LCD display on initramfs
VFDD_ARCH = armeabi-v7a
include build/vfdd.mak

# Build our own initramfs
INITRAMFS.DIR ?= build/$(PLATFORM)/initramfs
INITRAMFS.MODULES ?= mali.ko dwc3.ko dwc_otg.ko dhd.ko
INITRAMFS.DEP.mali.ko = $(KD_MALI.FILE)
INITRAMFS.DEP.dwc3.ko = $(KERNEL.OUT)drivers/usb/dwc3/dwc3.ko
INITRAMFS.DEP.dwc_otg.ko = $(KERNEL.OUT)drivers/amlogic/usb/dwc_otg/310/dwc_otg.ko
INITRAMFS.DEP.dhd.ko = $(KD_AP6XXX.FILE)
INITRAMFS.EXTRA = $(addprefix $(INITRAMFS.OUT)tree/,vfdd vfdd.ini)
include build/initramfs.mak

# Also we want to rebuild Android boot.img
# Find user's boot.img that user wants to put new kernel into
BOOTIMG.ORIG ?= $(wildcard data/boot.img)
include build/bootimg.mak

$(KERNEL.OUT)arch/arm64/boot/dts/amlogic/gxm_q201_2g.dts: $(KERNEL.OUT).stamp.copy

# The rule for generating the DTS for q201-3g which is missing from amlogic kernel tree
$(KERNEL.DTS.DIR)gxm_q201_3g.dts: \
	$(KERNEL.OUT)arch/arm64/boot/dts/amlogic/gxm_q201_2g.dts
	sed $< \
		-e 's/gxm_q201_2g/gxm_q201_3g/' \
		-e 's/linux,usable-memory = <0x0 0x0 0x0 0x80000000>;/linux,usable-memory = <0x0 0x0 0x0 0xc0000000>;/' \
		> $@

# Create the X92-specific DTS
X92_DTS_PATCH = build/$(PLATFORM)/kernel/x92-dts.patch
$(KERNEL.DTS.DIR)gxm_x92_2g.dts: $(X92_DTS_PATCH) $(KERNEL.DTS.DIR)gxm_q201_2g.dts
	$(call APPLY.PATCH,$<,,-o $@ $(word 2,$^))

$(KERNEL.DTS.DIR)gxm_x92_3g.dts: $(X92_DTS_PATCH) $(KERNEL.DTS.DIR)gxm_q201_3g.dts
	$(call APPLY.PATCH,$<,,-o $@ $(word 2,$^))

$(KERNEL.OUT)drivers/usb/dwc3/dwc3.ko: kernel-modules
$(KERNEL.OUT)drivers/amlogic/usb/dwc_otg/310/dwc_otg.ko: kernel-modules

$(INITRAMFS.OUT)tree/vfdd: $(VFDD_BIN) $(INITRAMFS.OUT).stamp.copy
	$(call CP,$<,$@)

$(INITRAMFS.OUT)tree/vfdd.ini: $(VFDD_DIR)vfdd.ini $(INITRAMFS.OUT).stamp.copy
	$(call CP,$<,$@)

HELP += $(NL)bootfiles - Create the files needed to boot from SD card/USB stick

# To load from USB stick / SD card we need three files:
# boot.img, dtb.img and the u-Boot autoscript
bootfiles: $(OUT)$(BOOTIMG.FILE) $(OUT)dtb.img $(OUT)aml_autoscript

$(OUT)dtb.img: $(KERNEL.DTB)
	$(call CP,$<,$@)

AUTOSCRIPT_SRC = build/X92/uboot-script.txt
$(OUT)aml_autoscript: $(AUTOSCRIPT_SRC) $(OUT)$(BOOTIMG.FILE)
	sed -e 's/@BOOTIMG@/$(notdir $(OUT)$(BOOTIMG.FILE))/' $< > $@.tmp
	mkimage -T script -C none -n 'X92 custom kernel autoscript' -d $@.tmp $@
	$(call RM,$@.tmp)
