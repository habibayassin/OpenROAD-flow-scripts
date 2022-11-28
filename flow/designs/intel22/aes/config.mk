$(info [INFO-FLOW] AES Design)
DESIGN_DIR                   := $(realpath $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST)))))
DESIGN_PDK_HOME              := $(realpath $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST)))))

export DESIGN_NAME = aes
export DESIGN_TOP_NAME = aes_cipher_top
export PLATFORM    = intel22

export VERILOG_FILES = $(sort $(wildcard $(DESIGN_HOME)/src/$(DESIGN_NAME)/*.v))
export SDC_FILE      = $(DESIGN_DIR)/constraint.sdc

# These values must be multiples of placement site
# x=0.19 y=1.4
export DIE_AREA    = 0 0 250 250
export CORE_AREA   = 1.26 1.89 248 248


export PLACE_DENSITY = uniform

export ABC_CLOCK_PERIOD_IN_PS = 2600
