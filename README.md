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

### Demonstration
```
$ make run
echo "0 47" | racket main.rkt --twoints examples/fibonacci.mips
Enter value for register 1: Enter value for register 2: Running MIPS program.
MIPS program completed normally.
$01 = 0x00000000   $02 = 0x00000000   $03 = 0x6d73e55f   $04 = 0x00000000   
$05 = 0x00000000   $06 = 0x00000000   $07 = 0x00000000   $08 = 0x00000000   
$09 = 0x00000000   $10 = 0x00000001   $11 = 0x43a53f82   $12 = 0x6d73e55f   
$13 = 0x00000000   $14 = 0x00000000   $15 = 0x00000000   $16 = 0x00000000   
$17 = 0x00000000   $18 = 0x00000000   $19 = 0x00000000   $20 = 0x00000000   
$21 = 0x00000000   $22 = 0x00000000   $23 = 0x00000000   $24 = 0x00000000   
$25 = 0x00000000   $26 = 0x00000000   $27 = 0x00000000   $28 = 0x00000000   
$29 = 0x00000000   $30 = 0x01000000   $31 = 0x8123456c   
```


## Components
- [intialization](vm/initialize.rkt) configures the intial state of three pieces of "hardware":
	- [the CPU](vm/cpu.rkt) handles all of the CPU business
		- i.e. the fetch/decode/execute cycle
	- [the memory](vm/memory.rkt) emulates the memory
	- [the registerfile](vm/registerfile.rkt) emulates the register file
- in addition there are a few utilities that make the above easier:
	- [the word struct](vm/word.rkt) provides all the fields of a word
	- [constants](vm/constants.rkt) stores all the magic numbers


## Lessons learned
- clearly delineate your parts, and ensure that you can't muck them up
	- i.e. bytes vs. integer, etc.
- plan ahead


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

