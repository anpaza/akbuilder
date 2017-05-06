# 
# Liviu Caramida (carliv@xda), Carliv Image Kitchen source
#
MAKEFLAGS += --silent
IDIR = -I../include
OUT = ../out
CC=gcc
ifeq ($(target),32)
CFLAGS = -m32
CFLAGS += -std=c99 -pipe
LIBS= -m32 ../libcutils/libcutils.a ../libmincrypt/libmincrypt.a
else
CFLAGS = -std=c99 -pipe
LIBS= ../libcutils/libcutils.a ../libmincrypt/libmincrypt.a
endif
RM = rm -f
CP = cp

all:mkbootimg unpackbootimg imageinfo

mkbootimg:
	$(CC) $@.c -o $@ $(IDIR) $(LIBS)
	strip $@
	$(CP) $@ $(OUT)
	
unpackbootimg:
	$(CC) $@.c -o $@ $(IDIR) $(LIBS)
	strip $@
	$(CP) $@ $(OUT)
	
imageinfo:
	$(CC) $@.c -o $@ $(IDIR) $(LIBS)
	strip $@
	$(CP) $@ $(OUT)

clean:
	$(RM) mkbootimg unpackbootimg imageinfo
	
.PHONY: all clean
