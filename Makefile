# set paths to dasm and xvic
DASM = dasm
XVIC = xvic

out/main.prg: src/* data/levels/binary_levels/*
	${DASM} $< -o'out/main.prg' -l'out/main.lst' -I'src'


run: 
	${XVIC} out/main.prg

clean: 
	del /f /q out\*