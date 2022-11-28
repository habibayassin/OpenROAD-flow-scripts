export DESIGN_NAME = jpeg
export DESIGN_TOP_NAME = jpeg_encoder
export PLATFORM    = nangate45

export VERILOG_FILES = $(sort $(wildcard ./designs/src/$(DESIGN_NAME)/*.v))
export VERILOG_INCLUDE_DIRS = ./designs/src/$(DESIGN_NAME)/include
export SDC_FILE = ./designs/$(PLATFORM)/$(DESIGN_NAME)/constraint.sdc
export ABC_AREA = 1

# These values must be multiples of placement site
export DIE_AREA    = 0 0 549.86 550.2 
export CORE_AREA   = 10.07 9.8 539.98 540.4 

export PLACE_DENSITY_LB_ADDON = 0.20
