# The rules to build initramfs

.PHONY: initramfs

ifndef INITRAMFS.DIR
$(error initramfs source directory not defined)
endif

INITRAMFS.OUT = $(OUT)$(notdir $(INITRAMFS.DIR))-$(PLATFORM_KERNEL_VER)$(KERNEL.SUFFIX)/
OUTDIRS += $(INITRAMFS.OUT)

HELP += $(NL)initramfs - Build the initial RAM filesystem for $(PLATFORM)

INITRAMFS.FILE = $(INITRAMFS.OUT)$(notdir $(INITRAMFS.DIR))-$(PLATFORM_KERNEL_VER)$(KERNEL.SUFFIX).gz
INITRAMFS.MODDIR = $(INITRAMFS.OUT)tree/boot/modules-$(PLATFORM_KERNEL_VER)$(KERNEL.SUFFIX)/
INITRAMFS.MODFILES = $(addprefix $(INITRAMFS.MODDIR),$(INITRAMFS.MODULES))

initramfs: $(INITRAMFS.FILE)

$(INITRAMFS.FILE): $(INITRAMFS.OUT).stamp.copy $(INITRAMFS.MODFILES) $(INITRAMFS.EXTRA)
	cd $(INITRAMFS.OUT)tree && \
	find . | cpio --quiet -o -H newc | gzip > $(call CFN,$(INITRAMFS.FILE))

$(INITRAMFS.OUT).stamp.copy: $(call DIRSTAMP,$(INITRAMFS.OUT)) $(wildcard $(INITRAMFS.DIR)/*)
	$(call RMDIR,$(INITRAMFS.OUT)tree)
	$(call RCP,$(INITRAMFS.DIR)/.,$(INITRAMFS.OUT)tree/)
	sed -ie 's/^ro.kernel.build=.*/ro.kernel.build=$(PLATFORM_KERNEL_VER)$(KERNEL.SUFFIX)/' \
		$(INITRAMFS.OUT)tree/default.prop
	$(call TOUCH,$@)

define INITRAMFS.MKRULE.MODULE
$$(INITRAMFS.MODDIR)$1: $2 $$(INITRAMFS.OUT).stamp.copy
	$$(call MKDIR,$$(@D))
	$$(call CP,$$<,$$@)

endef

$(eval $(foreach _,$(INITRAMFS.MODULES),$(call INITRAMFS.MKRULE.MODULE,$_,$(INITRAMFS.DEP.$_))))
