#lang racket/base

(provide (rename-out [main-loop start]))

(require
  "vm.rkt" ; for vm structure
  "bytes.rkt"

  "stage/fetch.rkt"
  "stage/decode.rkt"
  "stage/execute.rkt")

(define (main-loop machine [count 0])
  (define fetched (fetch   machine))
  (define decoded (decode  fetched))
  (define updated (execute decoded))
  ;; TODO (define memory-updated (...))
  ;; TODO (define written-back (...))

  ;; Increment PC here for right now...
  (define pc (hash-ref (vm-rf machine) 'PC))
  (define new-pc (unsigned->word (+ 4 (bytes->unsigned pc))))
  (main-loop (set-register 'PC new-pc) (add1 count)))
