# Work log
## 2018-09-15
### Noon (start: 14:15)
- begin rewrite (finsh 16:30)
- begin debugging

## 2018-09-14
### Evening (3 hour)
- convert entire system to use bytes intstead of integers
	- the hard-to-find functions `integer->integer-bytes` and vice-versa aid

### Morning (1 hour)
- wrote byte tools
- began writing unit tests to ensure functionality of byte tools

## 2018-09-13
### Evening (1.75 hours)
- moved code to module, providing `(run)` function to run from program in root
- added more command line arguments
- further began implementing changeover to bytes
- began reading about / learning about macros

## 2018-09-11
### Evening (? hours)
- update test files
- update predicates
- move around code

## 2018-09-10
### Evening (3 hours)
- combined all CPU operations into the CPU file
- simplify the CPU logic to use a hash instead of switching on `cond`
- fixed error with reverse byte order

### Noon (0.25 hours)
- added another predicate: `non-zero?`

### Morning (0.5 hours)
- created helper predicate functions (e.g. `immutable-hash?`)

## 2018-09-09
### Noon (1 hour)
- added licence (AGPLv3)
- added self-documenting Makefile
- added .gitignore
- install racket7.0
- clean up "(require ...)" imports

## 2018-09-08
### Evening (4 hours)
- modularized code
- learned about `define/contract`
- add contracts to "ops.rkt"
- fixed `sw` mmio

### Noon (4 hours)
- added MMIO for lw and sw instructions
- added contracts to the ALU
- implemented signed/unsigned logic
- fixed logical error in operations using $HI:$LO
- fixed logical error in lis

### Morning (2 hours)
- wrote sparse list library
	- stores list indexes in an array only when they're inserted
	- this avoids creating a million element list for MEM
		- should memory access faster(?)
- implemented guards and contracts for sparse lists
	- learned how to use contracts, more about their functionality
		- by default only apply at module boundary (i.e. on import)
	- learned about guards for structs
		- apply on struct creation, can use without exporting struct
- wrote [TODO.md](./TODO.md) as place to store all improvements



## 2018-09-07
### Evening (4.5 hours)
- wrote fetch-decode-execute loop
- debugged until simple program ran

### Noon (0.5 hours)
- fix module import / exports
- get "mips-vm.rkt" running

### Morning (0.75 hours)
- define decoded word struct in "mips-vm.rkt"
- define opcodes and functions in "constants.rkt"

## 2018-09-06
### Morning (0.74 hours)
- defined most bitmask constants in "constants.rkt"
