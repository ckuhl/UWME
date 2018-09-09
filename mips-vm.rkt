#lang racket

; MIPS VM: Emulate a MIPS computer!

(require racket/format) ; Output while running
(require racket/cmdline) ; command line arguments

(require "cpu.rkt")
(require "byte-tools.rkt")
(require "programs.rkt") ; demo programs
(require "hardware.rkt") ; "hardware" for the vm
(require "constants.rkt") ; numeric constants, bit masks, etc.
(require "alu.rkt") ; ALU operations for R-type instructions
(require "ops.rkt") ; CPU operations
(require "sparse-list.rkt") ; Custom list data structure (access list as array)


 ; TODO Change initial $PC by CLI args
(define registers (initialize-registers 0))
(define MEM (initialize-memory p1))

; TODO switch on commandline arguments
; (eprintf "cmdline: ~V~n" (current-command-line-arguments))

(fetch registers MEM)

