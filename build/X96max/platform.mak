# Platform-specific targets

AMLOGIC_BUILDROOT_DIR = ../OpenLinux_20180907
PLATFORM.KERNEL_VER ?= 4.9
PLATFORM.CC_DIR ?= $(AMLOGIC_BUILDROOT_DIR)/toolchain/gcc/linux-x86/aarch64/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu

# Default device tree
KERNEL.DTS ?= g12a_x96max_4g.dts
# Build a .cpio.gz file with initramfs file system
PLATFORM.BUILD.INITRAMFS = 1
# Pack kernel and initramfs into boot.img (aka recovery.img)
PLATFORM.BUILD.BOOTIMG = 1

# We want the Mali and Wi-Fi drivers
PLATFORM.BUILD.KD_MALI = 1
# The path to Mali driver inside the buildroot ARM directory
KD_MALI.DRVDIR ?= dvalin/kernel/drivers/gpu/arm/midgard

# Broadcom 6235 driver for Wi-Fi
PLATFORM.BUILD.KD_AP6XXX = 1
# The path to driver to use for our platform
KD_AP6XXX.DRVDIR ?= ap6xxx/bcmdhd.1.579.77.41.1.cn

# Build the video format decoder drivers
PLATFORM.BUILD.MEDIAMOD = 1

# Include Mali, Wi-Fi and "media module" drivers in initramfs
INITRAMFS.MODULES = mali.ko dhd.ko $(KD_MEDIAMOD.MODULES)
# And support for Bluetooth USB dongles
INITRAMFS.MODULES += btusb.ko btintel.ko btbcm.ko btrtl.ko
# NFS support
INITRAMFS.MODULES += nfsd.ko exportfs.ko nfs.ko nfsv2.ko nfsv3.ko nfs_acl.ko grace.ko \
	lockd.ko sunrpc.ko rpcsec_gss_krb5.ko auth_rpcgss.ko
INITRAMFS.EXTRA = $(addprefix $(INITRAMFS.OUT)tree/,vfdd vfdd.ini afrd afrd.ini)
INITRAMFS.DIRS = acct boot cache config data dev lib mnt oem odm proc storage system sys vendor

define PLATFORM.BUILD.EXTRA
# The directory for the linux_vfd project (https://github.com/anpaza/linux_vfd)
LINUX_VFD_DIR ?= ../linux_vfd/
# and we want the 32-bit ARM daemon for LCD display on initramfs
VFDD_ARCH = armeabi-v7a
include build/vfdd.mak
# Install vdd into kernel tree
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
$(KERNEL.DTS.DIR)g12a_x96max_4g.dts: $(PLATFORM.DIR)x96max-dts-4g.patch $(KERNEL.DTS.DIR)g12a_s905x2_u211.dts
	$(call APPLY.PATCH,$<,,-o $@ $(word 2,$^))

$(KERNEL.DTS.DIR)g12a_x96max_3g.dts: $(PLATFORM.DIR)x96max-dts-3g.patch $(KERNEL.DTS.DIR)g12a_x96max_4g.dts
	$(call APPLY.PATCH,$<,,-o $@ $(word 2,$^))

$(KERNEL.DTS.DIR)g12a_x96max_2g.dts: $(PLATFORM.DIR)x96max-dts-2g.patch $(KERNEL.DTS.DIR)g12a_x96max_4g.dts
	$(call APPLY.PATCH,$<,,-o $@ $(word 2,$^))

# How vfdd files gets copied to initramfs build dir
$(INITRAMFS.OUT)tree/vfdd: $(VFDD_BIN) $(INITRAMFS.OUT).stamp.copy
	$(call CP,$<,$@)

$(INITRAMFS.OUT)tree/vfdd.ini: $(VFDD_DIR)config/vfdd-x96max.ini $(INITRAMFS.OUT).stamp.copy
	$(call CP,$<,$@)

# How afrd files gets copied to initramfs build dir
$(INITRAMFS.OUT)tree/afrd: $(AFRD_BIN) $(INITRAMFS.OUT).stamp.copy
	$(call CP,$<,$@)

$(INITRAMFS.OUT)tree/afrd.ini: $(AFRD_DIR)config/afrd-x96max.ini $(INITRAMFS.OUT).stamp.copy
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
#	$(call DEPLOY,2G,g12a_x96max_2g.dts)
	$(call DEPLOY,3G,g12a_x96max_3g.dts)
	$(call DEPLOY,4G,g12a_x96max_4g.dts)
