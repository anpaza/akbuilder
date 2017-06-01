# The rules to build initramfs

.PHONY: initramfs

# the directory with initramfs template
INITRAMFS.DIR ?= $(PLATFORM.DIR)initramfs
INITRAMFS.OUT = $(OUT)$(notdir $(INITRAMFS.DIR))-$(KERNEL.RELEASE)/
OUTDIRS += $(INITRAMFS.OUT)

HELP += $(NL)initramfs - Build the initial RAM filesystem for $(PLATFORM)

INITRAMFS.FILE = $(INITRAMFS.OUT)$(notdir $(INITRAMFS.DIR))-$(KERNEL.RELEASE).gz
INITRAMFS.MODDIR = $(INITRAMFS.OUT)tree/lib/modules/$(KERNEL.RELEASE)/
INITRAMFS.MODFILES = $(addprefix $(INITRAMFS.MODDIR),$(INITRAMFS.MODULES))

initramfs: $(INITRAMFS.FILE)

$(INITRAMFS.FILE): $(INITRAMFS.OUT).stamp.copy $(INITRAMFS.MODFILES) $(INITRAMFS.EXTRA)
	cd $(INITRAMFS.OUT)tree && \
	find . | cpio --quiet -o -H newc | gzip > $(call CFN,$(INITRAMFS.FILE))

# git does not store empty dirs, so we have to create them manually
$(INITRAMFS.OUT).stamp.copy: $(call DIRSTAMP,$(INITRAMFS.OUT)) $(wildcard $(INITRAMFS.DIR)/*)
	$(call RMDIR,$(INITRAMFS.OUT)tree)
	$(call RCP,$(INITRAMFS.DIR)/.,$(INITRAMFS.OUT)tree/)
	$(call MKDIR,$(addprefix $(INITRAMFS.OUT)tree/,boot data dev lib oem proc sys system))
	sed -i -e 's/^ro.kernel.build=.*/ro.kernel.build=$(KERNEL.RELEASE)/' \
		$(INITRAMFS.OUT)tree/default.prop
	$(call TOUCH,$@)

define INITRAMFS.MKRULE.MODULE
$$(INITRAMFS.MODDIR)$1: $2 $$(INITRAMFS.OUT).stamp.copy
	$$(call MKDIR,$$(@D))
	$$(call CP,$$<,$$@)

endef

$(eval $(foreach _,$(INITRAMFS.MODULES),$(call INITRAMFS.MKRULE.MODULE,$_,$(INITRAMFS.DEP.$_))))
