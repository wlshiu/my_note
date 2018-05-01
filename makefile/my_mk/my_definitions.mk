
# get the Makefiles in sub-dirctories (1 depth) of current dirctory
define subdir-makefiles
$(wildcard $(1)/*/Makefile)
endef

$(info $(call subdir-makefiles,.))

