#lang racket/base


(require racket/cmdline
         racket/match
         "boot-vm.rkt"
         "main-loop.rkt")


;; Configure the VM, then run the program
(define (start-from-command-line)
  (define show-verbose (make-parameter #f))
  (define loader-mode (make-parameter 'none))

  (define source-file
    (command-line
      #:program "UWME"

      #:once-each
      [("-v" "--verbose")
       "Show verbose output of operation"
       (show-verbose #t)]

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

      #:args (filename)

      filename))

  ;; load program from file
  (define mem-init (load-file source-file default-vm))

  ;; load registers / memory from stdin
  (define machine
    (match (loader-mode)
      ['twoints (load-twoints mem-init)]
      ['array (load-array mem-init)]
      ['none mem-init]))

  (eprintf "Running MIPS program.~n")
  (start machine))


(start-from-command-line)
