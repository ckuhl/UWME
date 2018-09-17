# goose
## University of Waterloo MIPS Virtual Machine Emulator
_You can [read the project log](https://ckuhl.com/blog/tag/mips-vm/) on my
website!_

`goose` is a MIPS computer emulator. Specifically, it emulates the the
specification used in the University of Waterloo's
[Foundations of Sequential Programs course](https://www.student.cs.uwaterloo.ca/~cs241/),
affectionately known as "Baby compilers".

A [project log](LOG.md) was kept of the work done and amount of time taken.

A [list of things to do](TODO.md) has also been kept.


## How to use it
To emulate `java mips.twoints`:
`racket main.rkt --twoints <binary>`

To emulate `java mips.array`:
`racket main.rkt --array <binary>`


## Lessons learned
- clearly delineate your parts, and ensure that you can't muck them up
	- i.e. bytes vs. integer, etc.


## Read more
I blogged about the project as I developed it.

1. [MIPS VM: Planning](https://ckuhl.com/blog/mips-vm-planning/)


## UW MIPS CPU specification
### Hardware
#### Registers
- 32 general registers + $PC, $IR, $HI, $LO
- $0 is permantently set to 0
- $30 has the last valid memory address (i.e. is stack pointer)
- $31 has the address of the subroutine that called it

#### Memory
- 0x01000000 bytes of memory by default (i.e. 1 MiB)
	- (this is default stack pointer address)
- Program loaded into address 0x0 by default
- memory accesses must be memory aligned

#### CPU
- follows a subset of MIPS as defined in the [MIPS Reference](https://www.student.cs.uwaterloo.ca/~cs241/mips/mipsref.pdf)
- ???

### Software
#### On set up
- two ways to load variable data
	- `mips.twoints` which loads (signed?) integers into $1 and $2
	- `mips.array` which loads (signed?) integers into an array of length $2 starting at address $1
		- address $1 is the next byte after the end of the program by default

#### On termination
- outputs that program terminated successfully to stderr
- writes the value of registers $1 - $31 to stderr
