# The rules to build Mali out-of-tree kernel driver

.PHONY: kd-ap6xxx

ifndef KD_AP6XXX.DIR
$(error Broadcom AP6xxx kernel driver source directory not defined)
endif

KD_AP6XXX.OUT = $(OUT)$(notdir $(KD_AP6XXX.DIR))-$(PLATFORM_KERNEL_VER)$(KERNEL.SUFFIX)/
OUTDIRS += $(KD_AP6XXX.OUT)

HELP += $(NL)kd-ap6xxx - Build the Broadcom AP6xxx kernel driver for $(PLATFORM)

KD_AP6XXX.FILE = $(KD_AP6XXX.OUT)dhd.ko

kd-ap6xxx: $(KD_AP6XXX.FILE)

$(KD_AP6XXX.FILE): $(KD_AP6XXX.OUT).stamp.copy $(KERNEL.OUT).stamp.config
	$(MAKE) modules -C $(KERNEL.OUT) M=$(call CFN,$(KD_AP6XXX.OUT)) \
	ARCH=$(KERNEL.ARCH) CROSS_COMPILE=$(KERNEL_GCC_PREFIX) \
	KCPPFLAGS='-DCONFIG_BCMDHD_FW_PATH=\"/etc/wifi/fw_bcmdhd.bin\" -DCONFIG_BCMDHD_NVRAM_PATH=\"/etc/wifi/nvram.txt\"'
	$(call TOUCH,$@)

$(KD_AP6XXX.OUT).stamp.copy: $(call DIRSTAMP,$(KD_AP6XXX.OUT))
	$(call RCP,$(KD_AP6XXX.DIR)/.,$(KD_AP6XXX.OUT))
	$(call TOUCH,$@)
