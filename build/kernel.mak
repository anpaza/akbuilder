# Rules for building kernel
# This file should be included from platform mak, if appropiate

# Rules for building kernel
# This file should be included from platform defines.mak, if appropiate

.PHONY: kernel kernel-menuconfig kernel-modules

KERNEL.OUT = $(OUT)$(notdir $(KERNEL.DIR))$(KERNEL.SUFFIX)/
OUTDIRS += $(KERNEL.OUT)

HELP += $(NL)kernel - Build the $(PLATFORM) kernel
HELP += $(NL)kernel-clean - Clean the generated files from kernel tree
HELP += $(NL)kernel-modules - Build the modules for the $(PLATFORM) kernel
HELP += $(NL)kernel-menuconfig - Configure the $(PLATFORM) kernel
HELP += $(NL)kernel-getconfig - Copy config from kernel directory to $(PLATFORM_KERNEL_CONFIG)

KERNEL.OPTS ?= ARCH=$(KERNEL.ARCH) CROSS_COMPILE=$(KERNEL_GCC_PREFIX) \
	LOADADDR="$(KERNEL.LOADADDR)" EXTRAVERSION="$(KERNEL.SUFFIX)"
KERNEL.MAKE = +$(MAKE) -C $(KERNEL.OUT) -w $(KERNEL.OPTS)

# Sanity check

ifeq ($(PLATFORM_CC_DIR),)
$(error Platform compiler directory not found! Please define PLATFORM_CC_DIR in local-config.mak!)
endif
ifeq ($(KERNEL.DIR),)
$(error Kernel source directory not found! Please define KERNEL_DIR in local-config.mak!)
endif

KERNEL.FILE ?= $(KERNEL.OUT)arch/$(KERNEL.ARCH)/boot/Image.gz
ifdef KERNEL.DTS
KERNEL.DTB ?= $(KERNEL.DTS.DIR)$(patsubst %.dts,%.dtb,$(KERNEL.DTS))
endif

kernel: $(KERNEL.FILE) $(KERNEL.DTB)

kernel-modules: $(KERNEL.OUT).stamp.modules

kernel-clean: 
	$(KERNEL.MAKE) clean

kernel-menuconfig: $(KERNEL.OUT).stamp.config
	$(KERNEL.MAKE) menuconfig
	$(call TOUCH,$(KERNEL.OUT).stamp.config)

kernel-getconfig: $(KERNEL.OUT).stamp.config
	$(call UCOPY,$(KERNEL.OUT).config,$(PLATFORM_KERNEL_CONFIG))

$(KERNEL.FILE): $(KERNEL.OUT).stamp.config
	$(KERNEL.MAKE) Image.gz

$(KERNEL.OUT).stamp.copy: $(call DIRSTAMP,$(KERNEL.OUT))
	$(call RCP,$(KERNEL.DIR)/.,$(KERNEL.OUT))
	$(if $(PLATFORM_KERNEL_EXTRASRC),$(call RCP,$(PLATFORM_KERNEL_EXTRASRC)/.,$(KERNEL.OUT)))
	$(if $(PLATFORM_KERNEL_COPY),$(PLATFORM_KERNEL_COPY))
	$(call TOUCH,$@)

$(KERNEL.OUT).stamp.patch: $(KERNEL.OUT).stamp.copy
	$(foreach _,$(PLATFORM_KERNEL_PATCHES),$(call APPLY.PATCH,$_,$(KERNEL.OUT),-p 1))
	$(call TOUCH,$@)

$(KERNEL.OUT).stamp.config: $(KERNEL.OUT).stamp.patch $(PLATFORM_KERNEL_CONFIG)
	sed -e 's/^CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION=""/' \
	    -e 's/^CONFIG_LOCALVERSION_AUTO=.*/# CONFIG_LOCALVERSION_AUTO is not set/' \
	    -e 's/^CONFIG_DEFAULT_HOSTNAME=.*/CONFIG_DEFAULT_HOSTNAME="$(PLATFORM)"/' \
		$(PLATFORM_KERNEL_CONFIG) > $(KERNEL.OUT).config
	$(KERNEL.MAKE) oldconfig
	$(KERNEL.MAKE) prepare
	$(call TOUCH,$@)

$(KERNEL.OUT).stamp.modules: $(KERNEL.OUT).stamp.config
	$(KERNEL.MAKE) modules
	$(call TOUCH,$@)

ifdef KERNEL.DTS
$(KERNEL.DTB): $(KERNEL.DTS.DIR)$(KERNEL.DTS)
	$(KERNEL.MAKE) $(subst $(KERNEL.DTS.DIR),,$@)

$(KERNEL.DTS.DIR)$(KERNEL.DTS): $(KERNEL.OUT).stamp.config
endif
