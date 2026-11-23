include $(SW_SOC_ROOT)/common/config.mk

VORTEX_ROOT  := $(SW_SOC_ROOT)/projects/vortex
VORTEX_DIR   := $(VORTEX_ROOT)/vortex
BUILD_DIR    := $(VORTEX_DIR)/build
BIN_DIR      := $(VORTEX_ROOT)/bin
ZCU_PATH		 := hw/syn/xilinx/zcu102
PLATFORM_DIR := $(VORTEX_DIR)/$(ZCU_PATH)/bare/platform/simplyv
CONFIG_JSON  := $(HW_UNITS_ROOT)/custom_vortex/assets/simplyv.json
KERNEL       ?= vecadd

VX_FLAGS    := PLATFORM=simplyv CONFIG_JSON=$(CONFIG_JSON) KERNEL=$(KERNEL) HOST_XLEN=$(XLEN)
VX_TOOLDIR  ?= $(VORTEX_ROOT)/tools

.PHONY: all pull install bare clean 

all: bare

pull: $(VORTEX_DIR)

$(VORTEX_DIR)/configure: 
	git -C $(SIMPLYV_ROOT_DIR) submodule update --init -depth 1 $(VORTEX_DIR)

toolchain: pull $(VX_TOOLDIR)/.installed
	
$(VX_TOOLDIR)/.installed: 
	mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && ../configure --xlen=64 --tooldir=$(VX_TOOLDIR) && \
	./ci/toolchain_install.sh --riscv64 --llvm
	touch $@

install: toolchain 
	mkdir -p $(PLATFORM_DIR)
	cp src/platform.mk src/hal.c $(PLATFORM_DIR)
	cp $(SW_SOC_ROOT)/common/ld/variables.ld $(PLATFORM_DIR)
	cp $(SW_SOC_ROOT)/common/ld/memory.ld $(PLATFORM_DIR)
	cp $(SW_SOC_ROOT)/common/ld/sections.ld $(PLATFORM_DIR)
	cp $(SW_SOC_ROOT)/common/startup.s $(PLATFORM_DIR)

bare: install
	cd $(BUILD_DIR) && ../configure --xlen=64 --tooldir=$(VX_TOOLDIR) && \
  . ./ci/toolchain_env.sh && \
	$(MAKE) -C $(BUILD_DIR)/$(ZCU_PATH) bare $(VX_FLAGS)
	mkdir -p $(BIN_DIR)
	mv $(BUILD_DIR)/$(ZCU_PATH)/bare/app.elf $(BIN_DIR)

clean:
	$(MAKE) -C $(BUILD_DIR)/$(ZCU_PATH) clean-bare-sw $(VX_FLAGS)

