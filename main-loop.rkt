#lang racket/base

;; Recursively run the stages of the processor until we finish

(provide (rename-out [main-loop start]))

(require
  "vm.rkt" ; for vm structure

  "stage/fetch.rkt"
  "stage/decode.rkt"
  "stage/execute.rkt"
  "stage/memory.rkt"
  "stage/write-back.rkt")

(define cycle
  (compose1
    write-back
    memory-access
    execute
    instruction-decode
    instruction-fetch))

(define (main-loop machine [count 0])
  (main-loop (cycle machine) (add1 count)))
