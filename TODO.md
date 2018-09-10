# To do
## Correctness
- `[X]` handle lw special case for MMIO
- `[X]` handle sw special case for MMIO
- `[X]` handle unsigned binary math vs. signed

## Features
- `[ ]` take binary files as input (binaryio?)
	- this is required to be able to pass input (to `lw` via MMIO) on the commandline
		- i.e. to be able to use automated testing
- `[ ]` handle command line arguments
	- `[ ]` use [cmdline](https://docs.racket-lang.org/reference/Command-Line_Parsing.html)
- `[ ]` create error handling methods (to e.g. call `(cpu-error ...)`
	- `[ ]` define return codes (for e.g. testing)
- `[X]` on termination print registers to stderr
- `[X]` take binary from stdin
	` `[X]` Use [read-byte](https://docs.racket-lang.org/reference/Byte_and_String_Input.html#%28def._%28%28quote._~23~25kernel%29._read-byte%29%29)

## Code quality
- `[ ]` document code (see the [Racket style guide](https://docs.racket-lang.org/style/index.html))
	- `[ ]` See [documenting in source](https://docs.racket-lang.org/scribble/srcdoc.html)
- `[ ]` determine better approach to naming
- `[ ]` format code according to the [Racket style guide](https://docs.racket-lang.org/style/index.html)
- `[ ]` clean up `execute` switch statement
- `[X]` create helper predicate functions (is-valid-word?)
	- `[ ]` create more helper predicate functions
- `[ ]` create printing utility functions (format-word, format-register, etc.)
- `[ ]` clean up project structure (i.e. how [other MIPS interpreters](https://github.com/topics/mips?o=asc&s=stars) are laid out
- `[X]` modularize code

## Testing
- `[ ]` look into writing tests (for success cases and error cases)
- `[X]` add contracts to functions in `ops.rkt`
- `[X]` add contracts to functions `alu.rkt`

## Publish
- `[ ]` determine how to use [raco](https://docs.racket-lang.org/raco/index.html) to build an executable
- `[ ]` speed up code by replacing `#lang racket` with `#lang racket/base`
- `[X]` write a Makefile to automate tasks
	- `[ ]` use upx to compress filesize(?)

## Project
- `[ ]` update the [README](./README.md) with more information
- `[ ]` interlink the [log](./LOG.md), [README](./README.md), and this `TODO`

## Maybe
- `[ ]` add syntax defitions to vim racket plugin
	- `[ ]` define/contract
	- `[ ]` ->
	- `[ ]` exit
	- `[ ]` and/c
	- `[ ]` between/c
	- `[ ]` range
	- `[ ]` ->*
	- `[ ]` listof
	- `[ ]` eof-object?
	- `[ ]` list/c
	- `[ ]` any/c
	- `[ ]` ~r
	- `[ ]` ~a
- `[ ]` add linker & relocator for MERL files

