#lang racket/base


(require racket/contract "../vm.rkt")
(provide/contract [instruction-fetch (vm? . -> . vm?)])

(require "../bytes.rkt")


;; Load a a word into and return it
(define (instruction-fetch machine)
  (define pc (register-get machine 'PC))
  (define pc-value (bytes->integer pc #:signed? #f))
  (define updated-pc (integer->bytes (+ 4 pc-value) #:signed? #f))
  (register-set* machine
                 (cons 'MDR (memory-get machine pc-value))
                 (cons 'PC updated-pc)))
