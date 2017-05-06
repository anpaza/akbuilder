# 
# Liviu Caramida (carliv@xda), Carliv Image Kitchen source
#
MAKEFLAGS += --silent
OUT = ../out
CC=gcc
ifeq ($(target),32)
CFLAGS = -m32
CFLAGS += -std=c99 -pipe
else
CFLAGS = -std=c99 -pipe
endif
RM = rm -f
CP = cp

all:mkbootfs

mkbootfs:
	$(CC) $@.c -o $@
	strip $@
	$(CP) $@ $(OUT)

clean:
	$(RM) mkbootfs

.PHONY: all clean
