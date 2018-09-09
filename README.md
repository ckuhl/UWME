# MIPS VM
A virtual machine emulating a MIPS virtual machine.

## Project structure
- `mips-vm.rkt` is the root project
- `constants.rkt` stores only constants (e.g. bitmasks, opcodes, etc.)

## Useful notes
To test using internal program:
`racket -l errortrace -t mips-vm.rkt`

To test using program over stdin:
`time racket -l errortrace -t mips-vm.rkt < test-files/a1p4.mips`

## Read more
You can read more about the development process as I blogged it.

1. [MIPS VM: Planning](https://ckuhl.com/blog/mips-vm-planning/)

