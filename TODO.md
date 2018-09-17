# To do
## Correctness
- `[ ]` debug read-byte / write-byte and printf / eprintf
	- how do I get them all to work without fighting?
- `[ ]` look into writing tests (for success cases and error cases)
	- `[ ]` test that loading into memory works
	- `[ ]` test that each operation does what it is supposed to
		- `[ ]` test that e.g. `mult` fails if shamt field is non-zero
	- `[ ]` test that `fetch` does what it is supposed to
- `[X]` identical output to UW MIPS VM
- `[X]` handle lw special case for MMIO
- `[X]` handle sw special case for MMIO
- `[X]` handle unsigned binary math vs. signed
- `[X]` add contracts to functions in `ops.rkt`
- `[X]` add contracts to functions `alu.rkt`

## Features
- `[ ]` create error handling methods (to e.g. call `(cpu-error ...)`
	- `[ ]` define unix return codes (for e.g. testing)
- `[X]` take binary files as input
	- this is required to be able to pass input (to `lw` via MMIO) on the commandline
		- i.e. to be able to use automated testing
- `[X]` handle command line arguments
	- `[X]` use [cmdline](https://docs.racket-lang.org/reference/Command-Line_Parsing.html)
- `[X]` on termination print registers to stderr
- `[X]` take binary from stdin
	- `[X]` Use [read-byte](https://docs.racket-lang.org/reference/Byte_and_String_Input.html#%28def._%28%28quote._~23~25kernel%29._read-byte%29%29)

## Code quality
- `[ ]` clean up project structure (i.e. how [other MIPS interpreters](https://github.com/topics/mips?o=asc&s=stars) are laid out
- `[ ]` document code (see the [Racket style guide](https://docs.racket-lang.org/style/index.html))
	- `[ ]` See [documenting in source](https://docs.racket-lang.org/scribble/srcdoc.html)
- `[ ]` format code according to the [Racket style guide](https://docs.racket-lang.org/style/index.html)
- `[ ]` update memory & registerfile to use `for/fold` to update numerous
- `[ ]` rename opcode format predicate functions (and rewrite too)
- `[ ]` make ops (e.g. `add`, etc.) consistent in code style
	- (e.g. `(define s...` vs `(define rs...)`)
- `[ ]` move errors / completion to `wind-down` module?
	- i.e. have a single exit point
	- print out register content / memory / whatever
	- OR print out error message
	- exit with correct error code (0 / failure)
- `[X]` create printing utility functions (format-word, format-register, etc.)
	- these now live with _what_ they're printing
- `[X]` modularize code
- `[X]` clean up `execute` switch statement
- `[X]` create helper predicate functions (is-valid-word?)
- `[X]` move everything but the main project into submodules

## Publish
- `[X]` determine how to use [raco](https://docs.racket-lang.org/raco/index.html) to build an executable
	- not possible currently
- `[X]` write a Makefile to automate tasks
- `[ ]` optimization (timings before and after)
	- `[ ]` speed up code by replacing `#lang racket` with `#lang racket/base`
		- take timings before and after
	- `[ ]` make fully tail recursive
- `[ ]` decide on *ONE NAME* and remove all others (e.g. `UWME` vs `goose`)

## Project
- `[X]` move `TODO` and `LOG` into a subdirectory?
	- no, moved code instead
- `[ ]` update the [README](README.md) with more information
- `[X]` interlink the [log](LOG.md), [README](README.md), and this `TODO.md`

## Maybe
- `[ ]` add a [REPL](https://docs.racket-lang.org/xrepl/index.html) for debugging
- `[ ]` add syntax defitions to the [vim-racket](https://github.com/wlangstroth/vim-racket) plugin
	- exit
	- range
	- eof-object?
	- ~r / ~a / &c.
	- read-byte
	- current-input-port
	- integer-bytes->integer
	- 

