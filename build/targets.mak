.PHONY: help clean outdirs

# Show help by default
help:
	$(call SAY,$-)
	$(call SAY,Choose one of the following targets for building:)
	$(call SAY,$-$(HELP))
	$(call SAY,$-)

clean:
	$(call RM,$(OUT))

outdirs: $(call DIRSTAMP,$(sort $(OUTDIRS)))

# Make all created directories as old as $(OUT), to prevend false rebuild triggers
%/.stamp.dir:
	$(call MKDIR,$(@D))
	$(call TOUCH,$@)
