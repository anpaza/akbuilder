# Provide the rules to rebuild boot.img by replacing kernel in it

# We need the boot.img tools
include build/carliv_mkbootimg_tools.mak

ifndef KERNEL.FILE
$(error KERNEL.FILE not defined! Can't build boot image without kernel)
endif
ifndef INITRAMFS.FILE
$(error INITRAMFS.FILE not defined! Can't build boot image without initramfs)
endif
ifndef KERNEL.DTB
$(error KERNEL.DTB not defined! Can't build boot image without a .dtb machine description)
endif

BOOTIMG.FILE ?= boot.img

BOOTIMG.KERNEL ?= $(KERNEL.FILE)
BOOTIMG.RAMDISK ?= $(INITRAMFS.FILE)
BOOTIMG.SECOND ?= $(KERNEL.DTB)

BOOTIMG.BASE ?= 0x0
BOOTIMG.KERNEL_OFS ?= 0x1080000

HELP += $(NL)bootimg - Create Android boot image (kernel + initramfs + dtb)

.PHONY: bootimg
bootimg: $(OUT)$(BOOTIMG.FILE)

$(OUT)$(BOOTIMG.FILE): $(MBI_PACK) $(BOOTIMG.KERNEL) $(BOOTIMG.RAMDISK) $(BOOTIMG.SECOND)
	$(MBI_PACK) -o $@ --board $(PLATFORM) \
		--base $(BOOTIMG.BASE) --kernel_offset $(BOOTIMG.KERNEL_OFS) \
		--kernel $(BOOTIMG.KERNEL) \
		--ramdisk $(BOOTIMG.RAMDISK) \
		--second $(BOOTIMG.SECOND)
