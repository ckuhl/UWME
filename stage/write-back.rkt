#lang racket/base

;; Write back stage of the classic RISC pipeline

(require racket/contract "../vm.rkt")
(provide/contract [write-back (vm? . -> . vm?)])


(define (write-back machine)
  machine)
