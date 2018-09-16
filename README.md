# UWME
## UnderWhelming MIPS Emulator
_You can [read the project log](https://ckuhl.com/blog/tag/mips-vm/) on my
website!_

UWME is a MIPS computer emulator. Specifically, it emulates the the
specification used in the University of Waterloo's
[Foundations of Sequential Programs course](https://www.student.cs.uwaterloo.ca/~cs241/),
affectionately known as "Baby compilers".

A copy of the ISA can be found
[on the course website](https://www.student.cs.uwaterloo.ca/~cs241/mips/mipsref.pdf).


## Project structure
- `UWME.rkt` is the main program
- `cpu.rkt` is where the fetch/decode/execute cycle happens
- `hardware.rkt` provides the registers and memory
- `output.rkt` provides output utilities
- `sparse-list.rkt` provides an efficient list implementation for the memory
- `predicates.rkt` has predicate functions for contracts
- `byte-tools.rkt` provides tools for working with binary numbers in Racket
- `constants.rkt` provides opcodes, bitmasks, etc.

## Lessons
- clearly delineate your parts, and ensure that you can't muxck them up
	- i.e. bytes vs. integer, etc.

## Read more
I blogged about the project as I developed it.

1. [MIPS VM: Planning](https://ckuhl.com/blog/mips-vm-planning/)

