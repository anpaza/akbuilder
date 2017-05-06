# The rules to build Mali out-of-tree kernel driver

.PHONY: kd-mali

ifndef KD_MALI.DIR
$(error Mali kernel driver source directory not defined)
endif

KD_MALI.OUT = $(OUT)$(notdir $(KD_MALI.DIR))-$(PLATFORM_KERNEL_VER)$(KERNEL.SUFFIX)/
OUTDIRS += $(KD_MALI.OUT)

HELP += $(NL)kd-mali - Build the Mali kernel driver for $(PLATFORM)

KD_MALI.FILE = $(KD_MALI.OUT)mali_kbase.ko

kd-mali: $(KD_MALI.FILE)

$(KD_MALI.FILE): $(KD_MALI.OUT).stamp.copy $(KERNEL.OUT).stamp.config
	$(MAKE) -C $(KERNEL.OUT) M=$(call CFN,$(KD_MALI.OUT)) \
	ARCH=$(KERNEL.ARCH) CROSS_COMPILE=$(KERNEL_GCC_PREFIX) \
	EXTRA_CFLAGS="-DCONFIG_MALI_PLATFORM_DEVICETREE -DCONFIG_MALI_MIDGARD_DVFS -DCONFIG_MALI_BACKEND=gpu" \
	CONFIG_MALI_MIDGARD=m CONFIG_MALI_PLATFORM_DEVICETREE=y CONFIG_MALI_MIDGARD_DVFS=y CONFIG_MALI_BACKEND=gpu modules
	$(call TOUCH,$@)

$(KD_MALI.OUT).stamp.copy: $(call DIRSTAMP,$(KD_MALI.OUT))
	$(call RCP,$(KD_MALI.DIR)/.,$(KD_MALI.OUT))
	$(call TOUCH,$@)
