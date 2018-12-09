#lang racket/base

;; Memory access stage of the classic RISC pipeline

(require racket/contract "../vm.rkt")
(provide/contract [memory-access (vm? . -> . vm?)])


(define (memory-access machine)
  machine)
