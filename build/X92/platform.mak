# Platform-specific targets

# Compiler prefix for target platform
KERNEL_GCC_PREFIX ?= aarch64-linux-gnu-
# The directory prefix where to look for the AMLogic openlinux buildroot source code
AMLOGIC_BUILDROOT_DIR ?= ../buildroot_openlinux_kernel_4.9
# The directory for the linux_vfd project (https://github.com/anpaza/linux_vfd)
LINUX_VFD_DIR ?= ../linux_vfd
# The directory prefix where to look for Linary GCC build
PLATFORM.CC_DIR ?= $(AMLOGIC_BUILDROOT_DIR)/toolchain/gcc/linux-x86/aarch64/gcc-linaro-aarch64-linux-gnu-4.9
# Kernel directory suffix (3.14 or 4.9)
PLATFORM.KERNEL_VER ?= 3.14

PLATFORM.KERNEL_CONFIG = build/$(PLATFORM)/linux-$(PLATFORM.KERNEL_VER)/config
PLATFORM.KERNEL_PATCHES = \
	$(sort $(wildcard build/patches/linux-$(PLATFORM.KERNEL_VER)/*.patch)) \
	$(sort $(wildcard build/$(PLATFORM)/linux-$(PLATFORM.KERNEL_VER)/*.patch))
# Make a link from '.' to 'customer' so that we can build dtbs
define PLATFORM.KERNEL_COPY
	ln -s $(call CFN,$(KERNEL.OUT)) $(KERNEL.OUT)customer
	ln -s $(call CFN,$(LINUX_VFD_DIR)/vfd) $(KERNEL.OUT)drivers/amlogic/input/

endef

# Use the DTS files from kernel tree
KERNEL.DTS ?= gxm_x92_2g.dts
KERNEL.DTS.DIR = $(KERNEL.OUT)arch/arm64/boot/dts/amlogic/

# One kernel to rule them all...
KERNEL.DIR ?= $(AMLOGIC_BUILDROOT_DIR)/kernel/aml-$(PLATFORM.KERNEL_VER)
KERNEL.SUFFIX ?= -zap-3
KERNEL.ARCH = arm64
KERNEL.LOADADDR ?= 0x1080000
include build/kernel.mak

# Also we want the out-of-tree kernel drivers
KD_MALI.DIR ?= $(AMLOGIC_BUILDROOT_DIR)/hardware/aml-$(PLATFORM.KERNEL_VER)/arm/gpu/midgard/r13p0/kernel/drivers/gpu/arm/midgard
include build/kd-mali.mak

KD_AP6XXX.DIR ?= $(AMLOGIC_BUILDROOT_DIR)/hardware/aml-$(PLATFORM.KERNEL_VER)/wifi/broadcom/drivers/ap6xxx/bcmdhd_1_201_59_x
include build/kd-ap6xxx.mak

# and we want the 32-bit ARM daemon for LCD display on initramfs
VFDD_ARCH = armeabi-v7a
include build/vfdd.mak

# Build our own initramfs
INITRAMFS.DIR ?= build/$(PLATFORM)/initramfs
INITRAMFS.MODULES ?= mali.ko dwc3.ko dwc_otg.ko dhd.ko overlay.ko
INITRAMFS.DEP.mali.ko = $(KD_MALI.FILE)
INITRAMFS.DEP.dwc3.ko = $(KERNEL.OUT)drivers/usb/dwc3/dwc3.ko
INITRAMFS.DEP.dwc_otg.ko = $(KERNEL.OUT)drivers/amlogic/usb/dwc_otg/310/dwc_otg.ko
INITRAMFS.DEP.dhd.ko = $(KD_AP6XXX.FILE)
INITRAMFS.DEP.overlay.ko = $(KERNEL.OUT)fs/overlayfs/overlay.ko
INITRAMFS.EXTRA = $(addprefix $(INITRAMFS.OUT)tree/,vfdd vfdd.ini)
include build/initramfs.mak

# Also we want to rebuild Android boot.img
# Find user's boot.img that user wants to put new kernel into
BOOTIMG.ORIG ?= $(wildcard data/boot.img)
include build/bootimg.mak

$(KERNEL.OUT)arch/arm64/boot/dts/amlogic/gxm_q201_2g.dts: $(KERNEL.OUT).stamp.copy

# Create the X92-specific DTS
X92_DTS_PATCH = build/$(PLATFORM)/x92-dts.patch
$(KERNEL.DTS.DIR)gxm_x92_2g.dts: $(X92_DTS_PATCH) $(KERNEL.DTS.DIR)gxm_q201_2g.dts
	$(call APPLY.PATCH,$<,,-o $@ $(word 2,$^))

X92_DTS_PATCH_3G = build/$(PLATFORM)/x92-dts-3g.patch
$(KERNEL.DTS.DIR)gxm_x92_3g.dts: $(X92_DTS_PATCH_3G) $(KERNEL.DTS.DIR)gxm_x92_2g.dts
	$(call APPLY.PATCH,$<,,-o $@ $(word 2,$^))

$(INITRAMFS.DEP.dwc3.ko) \
$(INITRAMFS.DEP.dwc_otg.ko) \
$(INITRAMFS.DEP.overlay.ko): kernel-modules

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

PLATFORM.UBOOT_AUTOSCRIPT ?= build/$(PLATFORM)/uboot-script-libreelec.txt
$(OUT)aml_autoscript: $(PLATFORM.UBOOT_AUTOSCRIPT)
	sed -e 's/@BOOTIMG@/$(notdir $(OUT)$(BOOTIMG.FILE))/' $< > $@.tmp
	mkimage -T script -C none -n '$(PLATFORM) custom kernel autoscript' -d $@.tmp $@
	$(call RM,$@.tmp)

.PHONY: deploy

define DEPLOY
	rm -f $(OUT){aml_autoscript,kernel.img,dtb.img}
	$(MAKE) bootfiles BOOTIMG.FILE=kernel.img KERNEL.DTS=$2
	mkdir -p $(OUT)deploy/$1
	mv -f $(OUT){aml_autoscript,kernel.img,dtb.img} $(OUT)deploy/$1
	for x in doc/{README-boot*.m4,CHANGES*.m4} ; do \
		m4 -DPLATFORM="$(PLATFORM)" $$x > $(OUT)deploy/$1/`basename $$x .m4`.txt ; \
	done
endef

deploy:
	$(call DEPLOY,2G,gxm_x92_2g.dts)
	$(call DEPLOY,3G,gxm_x92_3g.dts)
