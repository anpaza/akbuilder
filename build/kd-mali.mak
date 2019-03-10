# The rules to build Mali out-of-tree kernel driver

.PHONY: kd-mali kd-mali-clean

ifndef KD_MALI.DIR
$(error Mali kernel driver source directory not defined)
endif

KD_MALI.OUT = $(call CFN,.)/$(OUT)$(notdir $(KD_MALI.DIR))-$(KERNEL.RELEASE)/
OUTDIRS += $(KD_MALI.OUT)

HELP += $(NL)kd-mali - Build the Mali kernel driver for $(PLATFORM)
HELP += $(NL)kd-mali-clean - Clean the generated files for the Mali kernel driver

KD_MALI.FILE = $(KD_MALI.OUT)mali_kbase.ko
KD_MALI.DEFS = CONFIG_MALI_MIDGARD=m \
	       CONFIG_MALI_PLATFORM_DEVICETREE=y \
	       CONFIG_MALI_BACKEND=gpu

# DVFS and DEVFREQ are mutually exclusive;
# DVFS is obsolete and used in older kernels
ifneq ($(filter 3.%,$(PLATFORM.KERNEL_VER)),)
KD_MALI.DEFS += CONFIG_MALI_MIDGARD_DVFS=y
else
KD_MALI.DEFS += CONFIG_MALI_DEVFREQ=y
endif

kd-mali: $(KD_MALI.FILE)

kernel-clean: kd-mali-clean

kd-mali-clean:
	$(KERNEL.MAKE) clean M=$(KD_MALI.OUT)

$(KD_MALI.FILE): $(KD_MALI.OUT).stamp.copy $(KERNEL.FILE)
	$(KERNEL.MAKE) modules M=$(KD_MALI.OUT:/=) $(KD_MALI.DEFS) \
	EXTRA_CFLAGS="$(subst =y,,$(filter-out %=m,,$(addprefix -D,$(KD_MALI.DEFS))))"
	$(call TOUCH,$@)

$(KD_MALI.OUT).stamp.copy: $(call DIRSTAMP,$(KD_MALI.OUT))
	$(call RCP,$(KD_MALI.DIR)/.,$(KD_MALI.OUT))
	$(call TOUCH,$@)
