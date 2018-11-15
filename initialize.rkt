#lang racket/base

; MIPS VM: Emulate a MIPS computer!

(require racket/contract ; contracts
         racket/cmdline ; command-line arguments
         racket/list ; range
         racket/file ; file->bytes

         "cycle.rkt" ; do processing
         "registerfile.rkt" ; working space
         "memory.rkt" ; store things
         "constants.rkt"
         "word.rkt") ; constants like `word-size`

;; Set up and run the virtual machine
(define (run)
  (define loader-mode (make-parameter 'none))
  (define pc-initial-index (make-parameter 0))

  ; TODO there is a way to do this functionally, maybe switch over? (use closures)
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
  (define registers (initialize-rf))
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
  (rf? . -> . rf?)
  (rf-set
    (rf-set rf
            #b00001
            (begin (eprintf "Enter value for register 1: ")
                   (signed->bytes (read))))
    #b00010
    (begin (eprintf "Enter value for register 2: ")
           (signed->bytes (read)))))

;; Helper to load an array of n integers from stdin into memory
;; place the starting address of the array in register $1, and the size of
;; the array in register $2
(define/contract
  (load-array rf mem)
  (rf? memory? . -> . (list/c rf? memory?))

  (define array-size (begin (eprintf "Enter length of array: ") (read)))
  (define array-offset (memory-end-of-program mem))

  (define pairs
    (for/list ([i (range 0 array-size)])
      (eprintf "Enter array element ~a: " i)
      (cons
        (+ array-offset (* array-size word-size))
        (signed->bytes (read)))))


  (list
    (memory-set-pairs mem pairs)
    (rf-set-swap
      rf
      #b00001 (signed->bytes array-offset)
      #b00010 (signed->bytes array-size))))


(run)
