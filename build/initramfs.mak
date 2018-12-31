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
INITRAMFS.EXTRA += $(INITRAMFS.MODDIR)modules.dep

# The list of empty directories to create on initramfs
INITRAMFS.DIRS ?= boot data dev lib oem proc sys system

initramfs: $(INITRAMFS.FILE)

$(INITRAMFS.FILE): $(INITRAMFS.OUT).stamp.copy $(INITRAMFS.MODFILES) $(INITRAMFS.EXTRA)
	cd $(INITRAMFS.OUT)tree && \
	find . | cpio --quiet -o -H newc -R 0:0 | gzip > $(call CFN,$(INITRAMFS.FILE))

# git does not store empty dirs, so we have to create them manually
$(INITRAMFS.OUT).stamp.copy: $(call DIRSTAMP,$(INITRAMFS.OUT)) $(wildcard $(INITRAMFS.DIR)/*)
	$(call RMDIR,$(INITRAMFS.OUT)tree)
	$(call RCP,$(INITRAMFS.DIR)/.,$(INITRAMFS.OUT)tree/)
	$(call MKDIR,$(addprefix $(INITRAMFS.OUT)tree/,$(INITRAMFS.DIRS)))
	if [ -f $(INITRAMFS.OUT)tree/default.prop ] ; then \
		sed -i -e 's/^ro.kernel.build=.*/ro.kernel.build=$(KERNEL.RELEASE)/' \
			$(INITRAMFS.OUT)tree/default.prop; \
	fi
	$(call TOUCH,$@)

$(INITRAMFS.MODDIR)modules.dep: $(INITRAMFS.MODFILES) $(KERNEL.FILE)
	cp $(KERNEL.OUT)modules.{builtin,order} $(INITRAMFS.MODDIR)
	depmod -a -b $(INITRAMFS.OUT)tree $(KERNEL.RELEASE)
	rm -f $(INITRAMFS.MODDIR)modules.{*.bin,devname,softdep,builtin,order}

define INITRAMFS.MKRULE.MODULE
$(if $2,\
$$(INITRAMFS.MODDIR)$1: $2 $$(INITRAMFS.OUT).stamp.copy
	$$(call MKDIR,$$(@D))
	$$(call CP,$$<,$$@)
,$$(warning INITRAMFS.DEP.$_ is not defined))
endef

$(eval $(foreach _,$(INITRAMFS.MODULES),$(call INITRAMFS.MKRULE.MODULE,$_,$(INITRAMFS.DEP.$_))))

.PHONY: initramfs-showrules
initramfs-showrules:
	$(call SAY,$(foreach _,$(INITRAMFS.MODULES),$(call INITRAMFS.MKRULE.MODULE,$_,$(INITRAMFS.DEP.$_))\n))
