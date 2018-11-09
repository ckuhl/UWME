#lang racket/base

; MIPS VM: Emulate a MIPS computer!

(require racket/contract ; contracts
	 racket/cmdline ; command-line arguments
	 racket/list ; range
	 racket/file ; file->bytes

	 "cpu.rkt" ; do processing
	 "registerfile.rkt" ; working space
	 "memory.rkt" ; store things
	 "constants.rkt") ; constants like `word-size`

;; Set up and run the virtual machine
(define (run)
  (define loader-mode (make-parameter 'none))
  (define pc-initial-index (make-parameter 0))
  ; show-binary imported from CPU?

  ; TODO there is a way to do this functionally, maybe switch over?
  (define source-file
    (command-line
      #:program "UWME"

      #:multi
      [("-p" "--set-pc")
       n
       "Set the initial value of the program counter"
       (pc-initial-index n)]

      #:once-each
      [("-b" "--show-binary")
       "Show the binary code of each instruction after its execution"
       (show-binary #t)]

      [("-v" "--verbose")
       "Show verbose output of operation"
       (show-verbose #t)]

      [("-m" "--more-info")
       "Show more information on each run"
       (show-more #t)]

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
      [(equal? (loader-mode) 'twoints) (list (load-twoints registers) memory)]
      [(equal? (loader-mode) 'array) (load-array registers memory)]
      [else (list registers memory)]))

  ; set starting time to entering the loop
  (start-time (current-inexact-milliseconds))

  ; GO!
  (eprintf "Running MIPS program.~n")
  (apply run-cpu (values reg-mem)))

;; Helper to load two integers from stdin into registers $1 and $2
(define/contract
  (load-twoints rf)
  (registerfile? . -> . registerfile?)
  (registerfile-set-swap
    rf
    #b00001 (begin (eprintf "Enter value for register 1: ")
		   (integer->integer-bytes (read) word-size #t #t))
    #b00010 (begin (eprintf "Enter value for register 2: ")
		   (integer->integer-bytes (read) word-size #t #t))))

;; Helper to load an array of n integers from stdin into memory
;; place the starting address of the array in register $1, and the size of
;; the array in register $2
(define/contract
  (load-array rf mem)
  (registerfile? memory? . -> . (list/c registerfile? memory?))

  (define array-size (begin (eprintf "Enter length of array: ") (read)))
  (define array-offset (memory-end-of-program mem))

  (define pairs
    (for/list ([i (range 0 array-size)])
      (begin (eprintf "Enter array element ~a: " i)
	     (cons
	       (+ array-offset (* array-size word-size))
	       (integer->integer-bytes (read) word-size #t #t)))))


  (list
    (memory-set-pairs mem pairs)
    (registerfile-set-swap
      rf
      #b00001 (integer->integer-bytes array-offset word-size #t #t)
      #b00010 (integer->integer-bytes array-size word-size #t #t))))


(run)
