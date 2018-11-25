#lang racket/base


(require racket/contract ; contracts
         racket/cmdline ; command-line arguments
         racket/list ; range
         racket/file ; file->bytes

         "boot-vm.rkt"
         "main-loop.rkt")


;; Set up and run the virtual machine
(define (run)
  (define show-binary (make-parameter #f))
  (define show-verbose (make-parameter #f))
  (define show-more (make-parameter #f))
  (define loader-mode (make-parameter 'none))

  (define source-file
    (command-line
      #:program "UWME"

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

  ;; load program into virtual machine memory
  (define mem-init (load-file source-file default-vm))

  ;; load registers from command line
  (define machine
    (cond
      [(equal? (loader-mode) 'twoints) (load-twoints mem-init)]
      [(equal? (loader-mode) 'array) (load-array mem-init)]
      [else mem-init]))

  ;; run virtual machine
  (eprintf "Running MIPS program.~n")
  (start machine)) ; TODO

; TODO
(run)
