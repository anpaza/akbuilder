# The rules to build the "media modules" out-of-tree kernel drivers
# These are the AMLogic decoders for various video formats.

.PHONY: kd-mm kd-mm-clean

ifndef KD_MEDIAMOD.DIR
$(error Media modules kernel driver source directory not defined)
endif

KD_MEDIAMOD.OUT = $(call CFN,.)/$(OUT)$(notdir $(KD_MEDIAMOD.DIR))-$(KERNEL.RELEASE)/
OUTDIRS += $(KD_MEDIAMOD.OUT)

HELP += $(NL)kd-mm - Build the video decoder drivers for $(PLATFORM)
HELP += $(NL)kd-mm-clean - Clean the generated files for the video decoder drivers

KD_MEDIAMOD.MODULES = firmware.ko vpu.ko stream_input.ko media_clock.ko decoder_common.ko \
	aml_hardware_dmx.ko encoder.ko amvdec_mmjpeg.ko amvdec_mmpeg4.ko amvdec_vc1.ko \
	amvdec_mjpeg.ko amvdec_mmpeg12.ko amvdec_h264.ko amvdec_ports.ko amvdec_mpeg4.ko \
	amvdec_h265.ko amvdec_mh264.ko amvdec_avs2.ko amvdec_mpeg12.ko amvdec_vp9.ko \
	amvdec_real.ko amvdec_avs.ko amvdec_h264mvc.ko
KD_MEDIAMOD.FILES = $(addprefix $(KD_MEDIAMOD.OUT)modules_out/,$(KD_MEDIAMOD.MODULES))
KD_MEDIAMOD.PATCHES ?= $(wildcard build/patches/$(notdir $(KD_MEDIAMOD.DIR))/*.patch)
KD_MEDIAMOD.MAKE = $(MAKE) -C $(KD_MEDIAMOD.OUT:/=) KDIR=$(call CFN,$(KERNEL.OUT)) \
	MEDIA_DRIVERS=$(KD_MEDIAMOD.OUT)drivers \
	MODS_OUT=$(KD_MEDIAMOD.OUT)modules_out \
	TOOLS=$(KERNEL_GCC_PREFIX) \
	-f Media.mk

kd-mm: $(KD_MEDIAMOD.FILES)

kernel-clean: kd-mm-clean

kd-mm-clean: $(KD_MEDIAMOD.OUT).stamp.patch
	+$(KD_MEDIAMOD.MAKE) clean

$(KD_MEDIAMOD.FILES): $(KD_MEDIAMOD.OUT).stamp.build

$(KD_MEDIAMOD.OUT).stamp.build: $(KD_MEDIAMOD.OUT).stamp.patch $(KERNEL.FILE)
	+$(KD_MEDIAMOD.MAKE) modules
	+$(KD_MEDIAMOD.MAKE) copy-modules
	$(call TOUCH,$@)

$(KD_MEDIAMOD.OUT).stamp.copy: $(call DIRSTAMP,$(KD_MEDIAMOD.OUT))
	$(call RCP,$(KD_MEDIAMOD.DIR)/.,$(KD_MEDIAMOD.OUT))
	$(call TOUCH,$@)

$(KD_MEDIAMOD.OUT).stamp.patch: $(KD_MEDIAMOD.OUT).stamp.copy
	$(foreach _,$(KD_MEDIAMOD.PATCHES),$(call APPLY.PATCH,$_,$(KD_MEDIAMOD.OUT),-p 1))
	$(call TOUCH,$@)

.PHONY: kd-mm-touch
kd-mm-touch:
	$(call RM,$(KD_MEDIAMOD.OUT).stamp.build)
