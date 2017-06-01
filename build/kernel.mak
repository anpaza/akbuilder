# Rules for building kernel
# This file should be included from platform mak, if appropiate

# Rules for building kernel
# This file should be included from platform defines.mak, if appropiate

.PHONY: kernel kernel-getconfig kernel-menuconfig kernel-modules kernel-clean
.SUFFIXES: .dts .dtb

ifeq ($(KERNEL.DIR),)
$(error Kernel source directory not found! Please define KERNEL_DIR in local-config.mak!)
endif

# Figure out target kernel release (`uname -r`)
KERNEL.RELEASE.VERSION=$(shell sed -ne '/^VERSION *=/{; s/.*= *//; p; }' $(KERNEL.DIR)/Makefile)
KERNEL.RELEASE.PATCHLEVEL=$(shell sed -ne '/^PATCHLEVEL *=/{; s/.*= *//; p; }' $(KERNEL.DIR)/Makefile)
KERNEL.RELEASE.SUBLEVEL=$(shell sed -ne '/^SUBLEVEL *=/{; s/.*= *//; p; }' $(KERNEL.DIR)/Makefile)
KERNEL.RELEASE=$(KERNEL.RELEASE.VERSION).$(KERNEL.RELEASE.PATCHLEVEL).$(KERNEL.RELEASE.SUBLEVEL)$(KERNEL.SUFFIX)

KERNEL.OUT = $(OUT)$(notdir $(KERNEL.DIR))$(KERNEL.SUFFIX)/
OUTDIRS += $(KERNEL.OUT)

HELP += $(NL)kernel - Build the $(PLATFORM) kernel
HELP += $(NL)kernel-clean - Clean the generated files from kernel tree
HELP += $(NL)kernel-modules - Build the modules for the $(PLATFORM) kernel
HELP += $(NL)kernel-menuconfig - Configure the $(PLATFORM) kernel
HELP += $(NL)kernel-getconfig - Copy config from kernel directory to $(PLATFORM.KERNEL_CONFIG)

# If PLATFORM.CC_DIR is defined, use the path in KERNEL_GCC_PREFIX
ifneq ($(PLATFORM.CC_DIR),)
# convert relative path to absolute
PLATFORM.CC_DIR := $(call CFN,$(PLATFORM.CC_DIR))
KERNEL_GCC_PREFIX := $(PLATFORM.CC_DIR)/bin/$(KERNEL_GCC_PREFIX)
endif

KERNEL.OPTS ?= ARCH=$(KERNEL.ARCH) CROSS_COMPILE=$(KERNEL_GCC_PREFIX) \
	LOADADDR="$(KERNEL.LOADADDR)" EXTRAVERSION="$(KERNEL.SUFFIX)"
KERNEL.MAKE = +$(MAKE) -C $(KERNEL.OUT) -w $(KERNEL.OPTS)

KERNEL.FILE ?= $(KERNEL.OUT)arch/$(KERNEL.ARCH)/boot/Image.gz
ifdef KERNEL.DTS
KERNEL.DTB ?= $(KERNEL.DTS.DIR)$(patsubst %.dts,%.dtb,$(KERNEL.DTS))
endif

kernel: $(KERNEL.FILE) $(KERNEL.DTB)

kernel-modules: $(KERNEL.OUT).stamp.modules

kernel-clean:
	$(KERNEL.MAKE) clean
	$(call RM,$(KERNEL.OUT).stamp.modules)

kernel-menuconfig: $(KERNEL.OUT).stamp.config
	$(KERNEL.MAKE) menuconfig
	$(call TOUCH,$(KERNEL.OUT).stamp.config)

kernel-getconfig: $(KERNEL.OUT).stamp.config
	$(call UCOPY,$(KERNEL.OUT).config,$(PLATFORM.KERNEL_CONFIG))

$(KERNEL.FILE): $(KERNEL.OUT).stamp.config
	$(KERNEL.MAKE) Image.gz
	$(call TOUCH,$@)

$(KERNEL.OUT).stamp.copy: $(call DIRSTAMP,$(KERNEL.OUT))
	$(call RCP,$(KERNEL.DIR)/.,$(KERNEL.OUT))
	$(if $(PLATFORM.KERNEL_COPY),$(PLATFORM.KERNEL_COPY))
	$(call TOUCH,$@)

$(KERNEL.OUT).stamp.patch: $(KERNEL.OUT).stamp.copy
	$(foreach _,$(PLATFORM.KERNEL_PATCHES),$(call APPLY.PATCH,$_,$(KERNEL.OUT),-p 1))
	$(call TOUCH,$@)

$(KERNEL.OUT).stamp.config: $(KERNEL.OUT).stamp.patch $(PLATFORM.KERNEL_CONFIG)
	sed -e 's/^CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION=""/' \
	    -e 's/^CONFIG_LOCALVERSION_AUTO=.*/# CONFIG_LOCALVERSION_AUTO is not set/' \
	    -e 's/^CONFIG_DEFAULT_HOSTNAME=.*/CONFIG_DEFAULT_HOSTNAME="$(PLATFORM)"/' \
		$(PLATFORM.KERNEL_CONFIG) > $(KERNEL.OUT).config
	$(KERNEL.MAKE) oldconfig
	$(KERNEL.MAKE) prepare
	$(call TOUCH,$@)

$(KERNEL.OUT).stamp.modules: $(KERNEL.OUT).stamp.config | $(KERNEL.FILE)
	$(KERNEL.MAKE) modules
	$(call TOUCH,$@)

ifdef KERNEL.DTS
$(KERNEL.DTB): $(KERNEL.DTS.DIR)$(KERNEL.DTS) | $(KERNEL.FILE)
	$(KERNEL.MAKE) $(subst $(KERNEL.DTS.DIR),,$@)

#$(KERNEL.DTS.DIR)$(KERNEL.DTS): | $(KERNEL.OUT).stamp.config

# Wait until we make a copy of kernel tree before we look for any .dts files
$(KERNEL.DTS.DIR)%.dts: | $(KERNEL.OUT).stamp.config
	true
endif
