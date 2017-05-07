# The rules to build Mali out-of-tree kernel driver

.PHONY: kd-ap6xxx kd-ap6xxx-clean

ifndef KD_AP6XXX.DIR
$(error Broadcom AP6xxx kernel driver source directory not defined)
endif

KD_AP6XXX.OUT = $(call CFN,$(OUT)$(notdir $(KD_AP6XXX.DIR))-$(KERNEL.RELEASE))/
OUTDIRS += $(KD_AP6XXX.OUT)

HELP += $(NL)kd-ap6xxx - Build the Broadcom AP6xxx kernel driver for $(PLATFORM)
HELP += $(NL)kd-ap6xxx-clean - Clean the generated files for the Broadcom AP6xxx driver

KD_AP6XXX.FILE = $(KD_AP6XXX.OUT)dhd.ko

kd-ap6xxx: $(KD_AP6XXX.FILE)

kernel-clean: kd-ap6xxx-clean

kd-ap6xxx-clean:
	$(KERNEL.MAKE) clean M=$(KD_AP6XXX.OUT)

$(KD_AP6XXX.FILE): $(KD_AP6XXX.OUT).stamp.copy $(KERNEL.FILE)
	$(KERNEL.MAKE) modules M=$(KD_AP6XXX.OUT:/=) \
	KCPPFLAGS='-DCONFIG_BCMDHD_FW_PATH=\"/etc/wifi/fw_bcmdhd.bin\" \
	-DCONFIG_BCMDHD_NVRAM_PATH=\"/etc/wifi/nvram.txt\"'
	$(call TOUCH,$@)

$(KD_AP6XXX.OUT).stamp.copy: $(call DIRSTAMP,$(KD_AP6XXX.OUT))
	$(call RCP,$(KD_AP6XXX.DIR)/.,$(KD_AP6XXX.OUT))
	$(call TOUCH,$@)
