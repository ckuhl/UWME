#lang racket

; MIPS VM: Emulate a MIPS computer!

(require racket/cmdline) ; command line arguments

(require "cpu.rkt" ; fetch/decode/execute loop
	 "byte-tools.rkt" ; tools for operating on bytes
	 "hardware.rkt" ; "hardware" for the vm
	 "constants.rkt" ; numeric constants, bit masks, etc.
	 "alu.rkt" ; ALU operations for R-type instructions
	 "ops.rkt" ; CPU operations
	 "sparse-list.rkt") ; Custom list data structure (access list as array)


; TODO Change initial $PC by CLI args
(define registers (initialize-registers 0))
(define MEM (initialize-memory (load-bytes-from-stdin)))

; TODO switch on commandline arguments
; (eprintf "cmdline: ~V~n" (current-command-line-arguments))

(fetch registers MEM)

