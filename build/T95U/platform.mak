# Platform-specific targets

# Default device tree
KERNEL.DTS ?= gxm_t95u_2g.dts

# We want the Mali and Wi-Fi drivers
#PLATFORM.BUILD.KD_MALI = 1
#PLATFORM.BUILD.KD_AP6XXX = 1
PLATFORM.BUILD.INITRAMFS = 1
PLATFORM.BUILD.BOOTIMG = 1

# We build the USB driver from the kernel tree
PLATFORM.DWC3.KO = 1

# Include Mali and Wi-Fi drivers in initramfs
#INITRAMFS.MODULES = mali.ko dhd.ko
INITRAMFS.EXTRA = $(addprefix $(INITRAMFS.OUT)tree/,vfdd vfdd.ini afrd afrd.ini)

define PLATFORM.BUILD.EXTRA
# The directory for the linux_vfd project (https://github.com/anpaza/linux_vfd)
LINUX_VFD_DIR ?= ../linux_vfd/
# and we want the 32-bit ARM daemon for LCD display on initramfs
VFDD_ARCH = armeabi-v7a
include build/vfdd.mak

# The directory for the automatic framerate daemon (https://github.com/anpaza/afrd)
AFRD_DIR ?= ../afrd/
# and we want the 32-bit ARM daemon on initramfs
AFRD_ARCH = armeabi-v7a
include build/afrd.mak
endef

# Common definitions for all AMLogic-based platforms
include build/platform-amlogic.mak

# Create the t95u-specific DTS
$(KERNEL.DTS.DIR)gxm_t95u_2g.dts: $(PLATFORM.DIR)t95u-dts.patch $(KERNEL.DTS.DIR)gxm_q201_2g.dts
	$(call APPLY.PATCH,$<,,-o $@ $(word 2,$^))

# How vfdd files gets copied to initramfs build dir
$(INITRAMFS.OUT)tree/vfdd: $(VFDD_BIN) $(INITRAMFS.OUT).stamp.copy
	$(call CP,$<,$@)

$(INITRAMFS.OUT)tree/vfdd.ini: $(VFDD_DIR)vfdd.ini $(INITRAMFS.OUT).stamp.copy
	$(call CP,$<,$@)

# How afrd files gets copied to initramfs build dir
$(INITRAMFS.OUT)tree/afrd: $(AFRD_BIN) $(INITRAMFS.OUT).stamp.copy
	$(call CP,$<,$@)

$(INITRAMFS.OUT)tree/afrd.ini: $(AFRD_DIR)afrd.ini $(INITRAMFS.OUT).stamp.copy
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
endef

deploy:
	$(call DEPLOY,2G,gxm_t95u_2g.dts)
