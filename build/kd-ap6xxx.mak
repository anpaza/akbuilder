# The rules to build Wi-Fi AP6xxx out-of-tree kernel driver

.PHONY: kd-ap6xxx kd-ap6xxx-clean

ifndef KD_AP6XXX.DIR
$(error Broadcom AP6xxx kernel driver source directory not defined)
endif

KD_AP6XXX.OUT = $(call CFN,.)/$(OUT)$(notdir $(KD_AP6XXX.DIR))-$(KERNEL.RELEASE)/
OUTDIRS += $(KD_AP6XXX.OUT)

HELP += $(NL)kd-ap6xxx - Build the Broadcom AP6xxx kernel driver for $(PLATFORM)
HELP += $(NL)kd-ap6xxx-clean - Clean the generated files for the Broadcom AP6xxx driver

KD_AP6XXX.FILE = $(KD_AP6XXX.OUT)dhd.ko
KD_AP6XXX.PATCHES ?= $(wildcard build/patches/$(notdir $(KD_AP6XXX.DIR))/*.patch)
KD_AP6XXX.MAKE = $(MAKE) -C $(KD_AP6XXX.OUT:/=) KDIR=$(call CFN,$(KERNEL.OUT)) PWD=$(KD_AP6XXX.OUT:/=)

kd-ap6xxx: $(KD_AP6XXX.FILE)

kernel-clean: kd-ap6xxx-clean

kd-ap6xxx-clean: $(KD_AP6XXX.OUT).stamp.patch
	+$(KD_AP6XXX.MAKE) clean
#	$(KERNEL.MAKE) clean M=$(KD_AP6XXX.OUT)

$(KD_AP6XXX.FILE): $(KD_AP6XXX.OUT).stamp.patch $(KERNEL.FILE)
	+$(KD_AP6XXX.MAKE) bcmdhd_sdio
	mv $(KD_AP6XXX.OUT)dhd_sdio.ko $(KD_AP6XXX.OUT)dhd.ko
#	$(KERNEL.MAKE) modules M=$(KD_AP6XXX.OUT:/=) \
#	KCPPFLAGS='-DCONFIG_BCMDHD_FW_PATH=\"/etc/wifi/fw_bcmdhd.bin\" \
#	-DCONFIG_BCMDHD_NVRAM_PATH=\"/etc/wifi/nvram.txt\"'
	$(call TOUCH,$@)

$(KD_AP6XXX.OUT).stamp.copy: $(call DIRSTAMP,$(KD_AP6XXX.OUT))
	$(call RCP,$(KD_AP6XXX.DIR)/.,$(KD_AP6XXX.OUT))
	$(call TOUCH,$@)

$(KD_AP6XXX.OUT).stamp.patch: $(KD_AP6XXX.OUT).stamp.copy
	$(foreach _,$(KD_AP6XXX.PATCHES),$(call APPLY.PATCH,$_,$(KD_AP6XXX.OUT),-p 1))
	$(call TOUCH,$@)
