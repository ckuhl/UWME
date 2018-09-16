#lang racket

; MIPS VM: Emulate a MIPS computer!

(require racket/cmdline) ; command line arguments

(require "cpu.rkt" ; do processing
	 "registerfile.rkt" ; working space
	 "memory.rkt") ; store things

(provide run)

;; Set up and run the virtual machine
(define (run)
  (define loader-mode (make-parameter 'none))
  (define pc-initial-index (make-parameter 0))

  (define source-file
    (command-line
      #:program "UWME"

      #:multi
      [("-p" "--set-pc")
       n
       "Set the initial value of the program counter"
       (pc-initial-index n)] ; TODO how to set vars?

      #:once-any
      ["--none"
       "Load no addition data"
       (loader-mode 'none)]

      ["--twoints"
       "Load two integers into registers $1 and $2"
       (loader-mode 'twoints)]

      ["--array"
       "Specify an array length and then that many integers"
       (loader-mode 'array)]

      #:args (filename) ; one positional argument

      filename))

  ; initialize registers and memory
  (define registers (initialize-registerfile))
  (define memory (initialize-memory (file->bytes source-file)))

  ; update registers and/or memory based on the flag set taken
  (define reg-mem
    (cond
      [(equal? loader-mode 'twoints) (list (load-twoints registers) memory)]
      [(equal? loader-mode 'array) (load-array registers memory)]
      [else (list registers memory)]))

  ; GO!
  (apply run-cpu (values reg-mem)))

;; Helper to load two integers from stdin into registers $1 and $2
(define (load-twoints rf)
  (registerfile-set-swap
    rf
    #b00000 (begin (eprintf "Enter value for register 1: ") (read))
    #b00010 (begin (eprintf "Enter value for register 2: ") (read))))

;; Helper to load an array of n integers from stdin into memory, and place
;; the starting address of the array in register $TODO
; TODO implement load-array functionality
(define (load-array rf mem)
  (list rf mem))

