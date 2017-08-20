# This makefile will include the Auto Framerate daemon afrd into initramfs
# Get it from https://github.com/anpaza/afrd

ifndef AFRD_ARCH
$(error Please define AFRD_ARCH to the architecture of your afrd)
endif

AFRD_BIN ?= $(AFRD_DIR)libs/$(AFRD_ARCH)/afrd

# Try to find out NDK_ROOT ourselves
ifeq ($(NDK_ROOT),)
NDK_ROOT := $(strip $(dir $(shell which ndk-build 2>/dev/null)))
endif

ifneq ($(NDK_ROOT),)
# Build afrd if it isn't already
$(AFRD_BIN): $(wildcard $(AFRD_DIR)*.c $(AFRD_DIR)*.h)
	+cd $(AFRD_DIR) && $(NDK_ROOT)ndk-build
else
$(warning Please point NDK_ROOT to your Android NDK directory!)
endif
