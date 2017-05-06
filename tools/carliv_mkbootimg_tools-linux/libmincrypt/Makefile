# 
# Liviu Caramida (carliv@xda), Carliv Image Kitchen source
#
MAKEFLAGS += --silent
CC = gcc
AR = ar rcs
RM = rm -f
IDIR = -I../include
ifeq ($(target),32)
CFLAGS = -m32
CFLAGS += -std=c99 -pipe
else
CFLAGS = -std=c99 -pipe
endif
LIB = libmincrypt.a
LIB_OBJS = $(patsubst %.c,%.o,$(wildcard *.c))

all:$(LIB)

clean:
	$(RM) $(LIB_OBJS) $(LIB)

$(LIB):$(LIB_OBJS)
	$(AR) $@ $^

%.o:%.c
	$(CC) -o $@ $(CFLAGS) -c $< $(IDIR)

.PHONY: all clean
