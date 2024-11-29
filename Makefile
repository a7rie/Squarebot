# set paths to dasm and xvic
DASM = dasm
XVIC = xvic
PYTHON = python

BINARY_LEVELS_DIR := data/levels/binary_levels
ASCII_LEVELS_DIR := data/levels/ascii_levels

ASCII_LEVELS := $(wildcard $(ASCII_LEVELS_DIR)/*)
BINARY_LEVELS := $(patsubst $(ASCII_LEVELS_DIR)/%, $(BINARY_LEVELS_DIR)/%, $(ASCII_LEVELS))

all: out/main.prg 

out/main.prg: src/* ${BINARY_LEVELS}
	${DASM} $< -o'out/main.prg' -l'out/main.lst' -I'src'


${BINARY_LEVELS_DIR}/%: ${ASCII_LEVELS_DIR}/%
	${PYTHON} .\data\levels\generateLevelBinary.py $< $@

run: 
	${XVIC} out/main.prg

clean: 
	del /f /q out\*
	del /f /q \data\levels\binary_levels\*