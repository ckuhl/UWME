#lang racket/base

(provide fetch)

(require
  "../vm.rkt"
  "../bytes.rkt")


;; Load a word and return it
(define (fetch machine)
  (define pc (register-get machine 'PC))
  (define pc-value (bytes->unsigned pc))
  (memory-get machine pc-value))