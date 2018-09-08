# Work log
## 2018-09-06
### Morning (0.74 hours)
- defined most bitmask constants in "constants.rkt"


## 2018-09-07
### Morning (0.75 hours)
- define decoded word struct in "mips-vm.rkt"
- define opcodes and functions in "constants.rkt"

### Noon (0.5 hours)
- fix module import / exports
- get "mips-vm.rkt" running

### Evening (4.5 hours)
- wrote fetch-decode-execute loop
- debugged until simple program ran

## 2018-09-08
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

