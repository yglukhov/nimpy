
COMMA=,
NIM_SRC = $(filter-out main$(COMMA), $(patsubst nim/%.nim, %$(COMMA), $(wildcard nim/*.nim)))
NIM_DEPS_MK = nim/intermediate/deps.mk

# NIM_FLAGS = --gc:regions
NIM_FLAGS = --os:standalone --gc:none

ifneq ($(findstring STM32, $(CMSIS_MCU)),)
	NIM_FLAGS += --cpu:arm
endif

$(NIM_DEPS_MK) : # always_rebuild
	echo 'import $(NIM_SRC) nimpy/py_micro; py_micro.private_mp_implement_glue()' > nim/main.nim
	nim c --nimcache:nim/intermediate --genDeps --compileOnly --noMain $(NIM_FLAGS) nim/main.nim
	rm nim/main.nim

	@echo 'SRC_MOD += $$(wildcard nim/intermediate/*.c)' >> $(NIM_DEPS_MK)
	@echo 'all : .rm_deps_mk' >> $(NIM_DEPS_MK)
	@echo '.rm_deps_mk :' >> $(NIM_DEPS_MK)
	@echo '	rm $(NIM_DEPS_MK)' >> $(NIM_DEPS_MK)

.clean_nim_intermediates:
	rm -rf nim/intermediate nim/main.nim

clean: .clean_nim_intermediates

-include $(NIM_DEPS_MK)

CFLAGS_MOD += -Wno-unused-but-set-variable -Wno-error -Wno-double-promotion

