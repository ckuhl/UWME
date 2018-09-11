#lang racket

; MIPS VM: Emulate a MIPS computer!

(require racket/cmdline) ; command line arguments

(require "cpu.rkt" ; fetch
	 "hardware.rkt") ; "hardware" for the vm (registers and MEM)


; TODO Change initial $PC by CLI args
(define registers (initialize-registers 0))
(define MEM (initialize-memory (load-bytes-from-stdin)))

; TODO switch on commandline arguments
; need binary file to load
(eprintf "cmdline: ~V~n" (current-command-line-arguments))

(fetch registers MEM)

