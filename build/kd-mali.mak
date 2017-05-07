# The rules to build Mali out-of-tree kernel driver

.PHONY: kd-mali kd-mali-clean

ifndef KD_MALI.DIR
$(error Mali kernel driver source directory not defined)
endif

KD_MALI.OUT = $(call CFN,$(OUT)$(notdir $(KD_MALI.DIR))-$(KERNEL.RELEASE))/
OUTDIRS += $(KD_MALI.OUT)

HELP += $(NL)kd-mali - Build the Mali kernel driver for $(PLATFORM)
HELP += $(NL)kd-mali-clean - Clean the generated files for the Mali kernel driver

KD_MALI.FILE = $(KD_MALI.OUT)mali_kbase.ko

kd-mali: $(KD_MALI.FILE)

kernel-clean: kd-mali-clean

kd-mali-clean:
	$(KERNEL.MAKE) clean M=$(KD_MALI.OUT)

$(KD_MALI.FILE): $(KD_MALI.OUT).stamp.copy $(KERNEL.FILE)
	$(KERNEL.MAKE) modules M=$(KD_MALI.OUT:/=) \
	EXTRA_CFLAGS="-DCONFIG_MALI_PLATFORM_DEVICETREE -DCONFIG_MALI_MIDGARD_DVFS -DCONFIG_MALI_BACKEND=gpu" \
	CONFIG_MALI_MIDGARD=m CONFIG_MALI_PLATFORM_DEVICETREE=y CONFIG_MALI_MIDGARD_DVFS=y CONFIG_MALI_BACKEND=gpu
	$(call TOUCH,$@)

$(KD_MALI.OUT).stamp.copy: $(call DIRSTAMP,$(KD_MALI.OUT))
	$(call RCP,$(KD_MALI.DIR)/.,$(KD_MALI.OUT))
	$(call TOUCH,$@)
