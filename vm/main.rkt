#lang racket

; MIPS VM: Emulate a MIPS computer!

(require racket/cmdline) ; command line arguments

(require "cpu.rkt" ; do processing
	 "registers.rkt" ; working space
	 "memory.rkt") ; store things

(provide run)


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
  (define registers (initialize-registers 0))
  (define memory (initialize-memory (file->bytes source-file)))

  ; update based on actions taken
  (define reg-mem
    (cond
      [(equal? loader-mode 'twoints) (list (load-twoints registers) memory)]
      [(equal? loader-mode 'array) (load-array registers memory)]
      [else (list registers memory)]))

  ; begin program recursion
  (apply fetch (values reg-mem)))


(define (load-twoints registers)
  (hash-set
    (hash-set registers
	      #b00001
	      ((eprintf "Enter value for register 1: ")
	       (read)))
    #b00010
    ((eprintf "Enter value for register 2: ")
     (read))))

; TODO
(define (load-array registers mem)
  (list registers mem))

