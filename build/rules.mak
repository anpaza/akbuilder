# Default target
.PHONY: all
all: help

# A newline
define NL


endef
# A comma
COMMA=,
# A empty
EMPTY=
# A space
SPACE=$(EMPTY) $(EMPTY)
# This function should print its argument to the terminal
SAY = @echo -e '$(subst $(NL),\n,$(subst ','\'',$1))'
# Append text $2 to file $1
FAP = $(call SAY,$2) >> $1
# Return the contents of a text file
FREAD = $(strip $(shell cat $1))
# Return the canonical filename
CFN = $(shell readlink -f $1)
# Create a possibly multi-level directory
MKDIR = mkdir -p $(1:/=)
# How to remove one or more files without stupid questions
RM = rm -f $1
# How to remove a directory recursively
RMDIR = rm -rf $1
# How to copy a file
CP = cp $1 $2
# How to create a symbolic link
LN_S = ln -fs $(call CFN,$1) $2
# Recursively copy a whole tree
RCP = cp -a $1 $2
# How to set the last modification date on a file to current
TOUCH = touch $1
# Set the modification time of $1 from $2
TOUCHR = touch $1 -r $2
# Copy $1 to $2 if contents differ
UCOPY = cmp -s $1 $2 || cp -a $1 $2
# Move file $1 to $2 if contents differ, otherwise remove $1
UMOVE = cmp -s $1 $2 && rm -f $1 || mv -f $1 $2
# Separator line -- $-, that is :-)
-=------------------------------------------------------------------------
# A stamp file for every created directory
DIRSTAMP = $(addsuffix .stamp.dir,$1)
# Output directory base
OUT = out/$(PLATFORM)/
# The directory with platform sources
PLATFORM.DIR = build/$(PLATFORM)/

# Append to OUTDIRS all output directories
OUTDIRS = $(OUT)

# Append to HELP to display additional target info
HELP += $(NL)all - Build everything
HELP += $(NL)clean - Delete all target and intermediate files

# Apply patch file $1 relative to dir $2 with extra options $3
define APPLY.PATCH
	$(call SAY,[1;37mApplying patch file [1;34m$1[0m)
	patch $(if $2,-d "$2") $3 <$(if $1,"$1")

endef

include $(PLATFORM.DIR)platform.mak
include build/targets.mak
