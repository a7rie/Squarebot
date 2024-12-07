# set paths to dasm and xvic
DASM = ~aycock/599.82/bin/dasm
XVIC = ~aycock/599.82/bin/xvic
PYTHON = /usr/bin/python

BINARY_LEVELS_DIR := data/levels/binary_levels
ASCII_LEVELS_DIR := data/levels/ascii_levels

ASCII_LEVELS := $(wildcard $(ASCII_LEVELS_DIR)/*)
BINARY_LEVELS := $(patsubst $(ASCII_LEVELS_DIR)/%, $(BINARY_LEVELS_DIR)/%, $(ASCII_LEVELS))

all: out/main.prg 

out/main.prg: src/* ${BINARY_LEVELS}
	${DASM} main.s -o'out/main.prg' -l'out/main.lst' -I'src'


${BINARY_LEVELS_DIR}/%: ${ASCII_LEVELS_DIR}/%
	${PYTHON} ./data/levels/generateLevelBinary.py $< $@

run: 
	${XVIC} out/main.prg

clean:
	rm -f out/*
	rm -f ${BINARY_LEVELS_DIR}/*