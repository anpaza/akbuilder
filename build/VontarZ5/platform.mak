# Platform-specific targets

# Default device tree
KERNEL.DTS ?= gxm_z5_2g.dts

# We want the Mali and Wi-Fi drivers
PLATFORM.BUILD.KD_MALI = 1
PLATFORM.BUILD.KD_AP6XXX = 1
PLATFORM.BUILD.INITRAMFS = 1
PLATFORM.BUILD.BOOTIMG = 1

# Include Mali and Wi-Fi drivers in initramfs
INITRAMFS.MODULES ?= mali.ko dhd.ko

# Common definitions for all AMLogic-based platforms
include build/platform-amlogic.mak

# Create the platform-specific DTS
$(KERNEL.DTS.DIR)gxm_z5_2g.dts: $(PLATFORM.DIR)z5-dts.patch $(KERNEL.DTS.DIR)gxm_q201_2g.dts
	$(call APPLY.PATCH,$<,,-o $@ $(word 2,$^))

.PHONY: deploy
HELP += $(NL)deploy - Deploy the final kernel files for $(PLATFORM)

deploy:
	rm -f $(OUT){aml_autoscript,kernel.img,dtb.img}
	+$(MAKE) bootfiles BOOTIMG.FILE=kernel.img
	mkdir -p $(OUT)deploy
	mv -f $(OUT){aml_autoscript,kernel.img,dtb.img} $(OUT)deploy
	for x in doc/{README-boot*.m4,CHANGES*.m4} ; do \
		m4 -DPLATFORM="$(PLATFORM)" $$x > $(OUT)deploy/`basename $$x .m4`.txt ; \
	done
