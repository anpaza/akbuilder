# Platform-specific targets

# Default device tree
KERNEL.DTS ?= gxm_x92_2g.dts

PLATFORM.BUILD.INITRAMFS = 1
PLATFORM.BUILD.BOOTIMG = 1

# We want the Mali and Wi-Fi drivers
PLATFORM.BUILD.KD_MALI = 1
PLATFORM.BUILD.KD_AP6XXX = 1
# The path to driver to use for our platform
KD_AP6XXX.DRVDIR ?= ap6xxx/bcmdhd.1.363.59.144.x.cn

# We build the USB driver from the kernel tree
PLATFORM.DWC3.KO = 1

# Include Mali and Wi-Fi drivers in initramfs
INITRAMFS.MODULES = mali.ko dhd.ko
INITRAMFS.EXTRA = $(addprefix $(INITRAMFS.OUT)tree/,vfdd vfdd.ini afrd afrd.ini)

define PLATFORM.BUILD.EXTRA
# The directory for the linux_vfd project (https://github.com/anpaza/linux_vfd)
LINUX_VFD_DIR ?= ../linux_vfd/
# and we want the 32-bit ARM daemon for LCD display on initramfs
VFDD_ARCH = armeabi-v7a
include build/vfdd.mak
PLATFORM.KERNEL_COPY += ln -s $$(call CFN,$$(LINUX_VFD_DIR)/vfd) $$(KERNEL.OUT)drivers/amlogic/input/$$(NL)

# The directory for the automatic framerate daemon (https://github.com/anpaza/afrd)
AFRD_DIR ?= ../afrd/
# and we want the 32-bit ARM daemon on initramfs
AFRD_ARCH = armeabi-v7a
include build/afrd.mak
endef

# Common definitions for all AMLogic-based platforms
include build/platform-amlogic.mak

# Create the X92-specific DTS
$(KERNEL.DTS.DIR)gxm_x92_2g.dts: $(PLATFORM.DIR)x92-dts.patch $(KERNEL.DTS.DIR)gxm_q201_2g.dts
	$(call APPLY.PATCH,$<,,-o $@ $(word 2,$^))

$(KERNEL.DTS.DIR)gxm_x92_3g.dts: $(PLATFORM.DIR)x92-dts-3g.patch $(KERNEL.DTS.DIR)gxm_x92_2g.dts
	$(call APPLY.PATCH,$<,,-o $@ $(word 2,$^))

# How vfdd files gets copied to initramfs build dir
$(INITRAMFS.OUT)tree/vfdd: $(VFDD_BIN) $(INITRAMFS.OUT).stamp.copy
	$(call CP,$<,$@)

$(INITRAMFS.OUT)tree/vfdd.ini: $(VFDD_DIR)config/vfdd-x92.ini $(INITRAMFS.OUT).stamp.copy
	$(call CP,$<,$@)

# How afrd files gets copied to initramfs build dir
$(INITRAMFS.OUT)tree/afrd: $(AFRD_BIN) $(INITRAMFS.OUT).stamp.copy
	$(call CP,$<,$@)

$(INITRAMFS.OUT)tree/afrd.ini: $(AFRD_DIR)config/afrd-android7-.ini $(INITRAMFS.OUT).stamp.copy
	$(call CP,$<,$@)

.PHONY: deploy
HELP += $(NL)deploy - Deploy the final kernel files for $(PLATFORM)

define DEPLOY
	rm -f $(OUT){aml_autoscript,kernel.img,dtb.img}
	+$(MAKE) bootfiles BOOTIMG.FILE=kernel.img KERNEL.DTS=$2
	mkdir -p $(OUT)deploy/$1
	mv -f $(OUT){aml_autoscript,kernel.img,dtb.img} $(OUT)deploy/$1
	for x in doc/aml-$(PLATFORM.KERNEL_VER)/{README-boot*.m4,CHANGES*.m4} ; do \
		m4 -DPLATFORM="$(PLATFORM)" $$x > $(OUT)deploy/$1/`basename $$x .m4`.txt ; \
	done
	tools/upd-maker/upd-maker -n "Custom kernel for X92 by zap" \
		-fs $(PLATFORM.DIR)update-kernel.sh \
		-o $(OUT)deploy/$1/UPDATE_$1_kernel$(KERNEL.SUFFIX)-$(BDATE).zip \
		$(OUT)deploy/$1/kernel.img $(OUT)deploy/$1/dtb.img
endef

deploy:
	$(call DEPLOY,2G,gxm_x92_2g.dts)
	$(call DEPLOY,3G,gxm_x92_3g.dts)
