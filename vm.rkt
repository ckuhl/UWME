#lang racket/base

(provide (struct-out vm)
         register-get
         register-set
         memory-get
         memory-set)


;; Wrapper for registers / memory / PC
(define-struct vm (rf mem) #:transparent)


;; get the value of [register] from [machine]
(define (register-get machine register)
  (hash-ref (vm-rf machine) register))


;; Set [register] to [value] and return updated [machine]
(define (register-set machine register value)
  (struct-copy
    vm machine
    [rf (hash-set (vm-rf machine) register value)]))


;; the the value at [address] in the [machine]'s memory
(define (memory-get machine address)
  (hash-ref (vm-mem machine) address))


;; set [address] in the [machine]'s memory to [value]
(define (memory-set machine address value)
  (struct-copy
    vm machine
    [mem (hash-set (vm-mem machine) address value)]))
