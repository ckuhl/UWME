ASSEMBLER=asm.rkt
ASM = $(wildcard *.asm)


%.mips: %.asm
	racket ${ASSEMBLER} < $*.asm > $*.mips

all: $(ASM:.asm=.mips)

.PHONY: clean

clean:
	rm *.mips
