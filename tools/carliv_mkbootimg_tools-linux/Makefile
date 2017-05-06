# 
# Liviu Caramida (carliv@xda), Carliv Image Kitchen source
#
MAKEFLAGS += --silent

all:libmincrypt.a libcutils.a mkbootimg_tools mkbootfs

libmincrypt.a:
	$(MAKE) -C libmincrypt
	
libcutils.a:
	$(MAKE) -C libcutils

mkbootimg_tools:
	$(MAKE) -C mkbootimg
	
mkbootfs:
	$(MAKE) -C cpio

clean:
	$(MAKE) -C libmincrypt clean
	$(MAKE) -C libcutils clean
	$(MAKE) -C mkbootimg clean
	$(MAKE) -C cpio clean
	
clean_out:
	$(MAKE) -C out clean
	
.PHONY: all clean clean_out
