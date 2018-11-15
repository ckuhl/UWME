#lang racket/base

; CPU: Modifies register and memory

(provide run-cpu ; run the processor

         ;; global variables
         show-binary
         show-more
         start-time
         show-verbose)

(require racket/contract
         racket/format ; ~r
         racket/math ; exact-round

         "constants.rkt" ; magic numbers
         "cpu.rkt" ; name-to-operation
         "memory.rkt" ; memory
         "registerfile.rkt" ; registers
         "word.rkt") ; word

; global configuration
(define show-binary (make-parameter #f))
(define show-more (make-parameter #f))
(define show-verbose (make-parameter #f))

(define start-time (make-parameter (current-inexact-milliseconds)))
(define cycle-timer (make-parameter (current-inexact-milliseconds)))
(define cycle-count (make-parameter 0))


;; wrapper function to run everything
(define/contract
  (run-cpu rf mem)
  (rf? memory? . -> . void?)
  (fetch rf mem))

;; fetch :: get next instruction from memory and update $PC
(define/contract
  (fetch rf mem)
  (rf? memory? . -> . void?)

  ;; TODO remove? global state for loop timer =================================
  (when (show-verbose)
    (printf "Cycle #~a, time: ~ams~n"
            (cycle-count)
            (/ (round (* 1000
                         (- (current-inexact-milliseconds)
                            (cycle-timer))))
               1000)))
  (cycle-timer (current-inexact-milliseconds))
  (cycle-count (add1 (cycle-count)))
  ;; ==========================================================================

  (define pc-value (bytes->unsigned (rf-ref rf 'PC)))
  (cond
    [(equal? pc-value return-address)
     (eprintf "MIPS program completed normally.~n")
     (when (show-more)
       (eprintf "~a cycles in ~as, VM freq. ~akHz~n"
                (cycle-count)
                (/ (round (- (current-inexact-milliseconds) (start-time))) 1000)
                (/ (cycle-count) (- (current-inexact-milliseconds) (start-time))))) ; Hz / ms == kHz / s
     (eprintf "~a~n" (format-rf rf))
     (exit 0)] ; quit gracefully
    [else
        (when (show-binary)
          (printf "~a: ~a~n"
                  (format-word-hex (bytes->word (rf-ref rf 'PC)))
                  (format-word-binary (bytes->word (memory-ref mem pc-value)))))

        (decode
          (rf-set-swap
            rf
            'IR (memory-ref mem pc-value)
            'PC (unsigned->bytes (+ pc-value 4)))
          mem)]))

;; decode :: interpret the current instruction
(define/contract (decode rf mem)
                 (rf? memory? . -> . void?)
                 (execute (bytes->word (rf-ref rf 'IR)) rf mem))


;; execute :: update rf and/or memory based on instruction
(define/contract
  (execute w rf mem)
  (word? rf? memory? . -> . void?)
  (printf "~a~n" (hash-ref opcode-to-name (word-op w)))
  (apply
    fetch
    (apply
      (hash-ref name-to-operation
                (hash-ref opcode-to-name (word-op w))
                (lambda () (raise-user-error
                             'CPU
                             "given opcode ~b does not exist"
                             (~r (word-op w) #:sign #f #:base 2 #:min-width 6 #:pad-string "0"))))
      (list w rf mem))))
