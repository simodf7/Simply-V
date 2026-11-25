HAL_SRC_DIR := $(VORTEX_HOME)/hw/syn/xilinx/zcu102/bare/platform/simplyv
HAL_LIB_DIR := $(ROOT_DIR)/hw/syn/xilinx/zcu102/bare
TINYIO_DIR  := $(SW_SOC_ROOT)/lib/tinyio

RV_PREFIX := riscv$(HOST_XLEN)-unknown-elf-
CC  = $(RV_PREFIX)gcc
CXX = $(RV_PREFIX)g++
AR  = $(RV_PREFIX)ar
NM  = $(RV_PREFIX)nm
CP  = $(RV_PREFIX)objcopy

ifeq ($(HOST_XLEN), 64)
HOST_MARCH ?= rv64imac_zicsr_zifencei
HOST_MABI  ?= lp64
else
HOST_MARCH ?= rv32imc_zicsr_zifencei
HOST_MABI  ?= ilp32
endif

CFLAGS += -march=$(HOST_MARCH) -mabi=$(HOST_MABI)
CPPFLAGS += -I$(HAL_LIB_DIR)/include -I$(TINYIO_DIR)/inc
CPPFLAGS += -I$(SW_SOC_ROOT)/lib/simplyv/inc

ifdef SW_CONFIGS
	CPPFLAGS += $(SW_CONFIGS)
endif


LDFLAGS += -march=$(HOST_MARCH) -mabi=$(HOST_MABI)
LDFLAGS += -nostdlib \
           -T$(HAL_LIB_DIR)/variables.ld \
           -T$(HAL_LIB_DIR)/memory.ld \
           -T$(HAL_LIB_DIR)/sections.ld

LDLIBS  += -lgcc -lc
LDLIBS  += -L$(SW_SOC_ROOT)/lib/simplyv/lib -lsimplyv

OBJCP_FLAGS += -I binary -O elf$(HOST_XLEN)-littleriscv -B riscv
PLATFORM_FILES := $(addprefix $(HAL_LIB_DIR)/, variables.ld memory.ld sections.ld startup.s)
STARTUP_FILE := $(HAL_LIB_DIR)/startup.s

TINYIO_SRCS   := $(addprefix $(TINYIO_DIR)/src/, print.c tinyIO.c uart.c)
PLATFORM_OBJS := $(addprefix $(HAL_LIB_DIR)/, print.o tinyIO.o uart.o)

.PHONY: platform
platform: $(PLATFORM_FILES) $(TINYIO_SRCS)

$(HAL_LIB_DIR)/%: $(HAL_SRC_DIR)/%
	cp $< $@


