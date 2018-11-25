#lang racket/base

(provide fetch)

(require
  "../boot-vm.rkt"
  "../bytes.rkt")


;; Load a word and return it
(define (fetch machine)
  (define rf (vm-rf machine))
  (define mem (vm-mem machine))
  (define pc (hash-ref rf 'PC))

  (define pc-address (bytes->unsigned pc))

  (hash-ref mem pc-address))
