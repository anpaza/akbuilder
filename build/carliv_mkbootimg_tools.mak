# Defines for using carliv_mkbootimg_tools

MBI_DIR ?= tools/carliv_mkbootimg_tools-linux/
MBI_PACK ?= $(MBI_DIR)out/mkbootimg
MBI_UNPACK ?= $(MBI_DIR)out/unpackbootimg

# Build the tools if they aren't already
$(MBI_UNPACK): $(MBI_PACK)
$(MBI_PACK):
	$(MAKE) -j1 -C $(MBI_DIR:/=)
