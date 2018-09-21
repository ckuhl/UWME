# uwme
## UnderWhelming MIPS Emulator
_You can [read the project log](https://ckuhl.com/blog/tag/mips-vm/) on my
website!_

## University of Waterloo MIPS Virtual Machine Emulator
UWME is a MIPS computer emulator. Specifically, it emulates the the
specification used in the University of Waterloo's [Foundations of Sequential
Programs course](https://www.student.cs.uwaterloo.ca/~cs241/), affectionately
known as "Baby compilers".


## Demonstration
```
$ racket main.rkt --twoints examples/collatz.mips
Enter value for register 1: 0
Enter value for register 2: 121
Running MIPS program.
MIPS program completed normally.
$01 = 0x00000000   $02 = 0x00000001   $03 = 0x0000005f   $04 = 0x00000000   
$05 = 0x00000000   $06 = 0x00000000   $07 = 0x00000000   $08 = 0x00000000   
$09 = 0x00000000   $10 = 0x00000000   $11 = 0x00000001   $12 = 0x00000002   
$13 = 0x00000003   $14 = 0x00000000   $15 = 0x00000000   $16 = 0x00000000   
$17 = 0x00000000   $18 = 0x00000000   $19 = 0x00000000   $20 = 0x00000000   
$21 = 0x00000000   $22 = 0x00000000   $23 = 0x00000000   $24 = 0x00000000   
$25 = 0x00000000   $26 = 0x00000000   $27 = 0x00000000   $28 = 0x00000000   
$29 = 0x00000000   $30 = 0x01000000   $31 = 0x8123456c
```

## How to use it
To emulate `java mips.twoints`:

`racket main.rkt --twoints <binary>`


To emulate `java mips.array`:

`racket main.rkt --array <binary>`


## Read more
I blogged about the project as I developed it.

1. [MIPS VM part 1: Planning](https://ckuhl.com/blog/mips-vm-planning/)
2. [MIPS VM part 2: Minimal Viable Product](https://ckuhl.com/blog/mips-vm-minimal-viable-product/)
3. [MIPS VM part 3: Cleanup](https://ckuhl.com/blog/mips-vm-cleanup/)
4. [MIPS VM part 4: Completing](https://ckuhl.com/blog/mips-vm-completing/)

