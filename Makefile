# set paths to dasm and xvic
DASM = /Users/amine/Downloads/dasm-2.20.14.1-osx-x64/dasm
XVIC = /opt/homebrew/bin/xvic
PYTHON = /opt/homebrew/bin/python3

BINARY_LEVELS_DIR := /Users/amine/Documents/GitHub/Squarebot/data/levels/ascii_levels
ASCII_LEVELS_DIR := /Users/amine/Documents/GitHub/Squarebot/data/levels/binary_levels

ASCII_LEVELS := $(wildcard $(ASCII_LEVELS_DIR)/*)
BINARY_LEVELS := $(patsubst $(ASCII_LEVELS_DIR)/%, $(BINARY_LEVELS_DIR)/%, $(ASCII_LEVELS))

all: out/main.prg 

out/main.prg: src/* ${BINARY_LEVELS}
	${DASM} main.s -o'out/main.prg' -l'out/main.lst' -I'src'


${BINARY_LEVELS_DIR}/%: ${ASCII_LEVELS_DIR}/%
	${PYTHON} .\data\levels\generateLevelBinary.py $< $@

run: 
	${XVIC} out/main.prg

clean: 
	del /f /q out\*
	del /f /q \data\levels\binary_levels\*