# This makefile will include the LCD display daemon vfdd into initramfs
# Get it from https://github.com/anpaza/linux_vfd

ifeq ($(wildcard $(LINUX_VFD_DIR)vfdd/vfdd.c),)
$(error Please define LINUX_VFD_DIR to point to linux_vfd directory!)
endif

ifndef VFDD_ARCH
$(error Please define VFDD_ARCH to the architecture of your vfdd)
endif

# Try to find out NDK_ROOT ourselves
ifeq ($(NDK_ROOT),)
NDK_ROOT := $(strip $(dir $(shell which ndk-build 2>/dev/null)))
endif

ifeq ($(NDK_ROOT),)
$(error Could not find Android NDK directory, please define NDK_ROOT!)
endif

VFDD_DIR ?= $(LINUX_VFD_DIR)vfdd/
VFDD_BIN ?= $(VFDD_DIR)libs/$(VFDD_ARCH)/vfdd

# Always append '/' at the end of NDK_ROOT
NDK_ROOT := $(NDK_ROOT:/=)/

ifneq ($(NDK_ROOT),)
# Build vfdd if it isn't already
$(VFDD_BIN): $(wildcard $(VFDD_DIR)*.c $(VFDD_DIR)*.h)
	+cd $(VFDD_DIR) && $(NDK_ROOT)ndk-build
else
$(warning Please point NDK_ROOT to your Android NDK directory!)
endif
