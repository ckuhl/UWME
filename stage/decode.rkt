#lang racket/base

;; Decode the instruction in the MDR into signals

(require racket/contract "../vm.rkt")
(provide/contract [instruction-decode (vm? . -> . vm?)])

(require "../decoded.rkt")


(define (instruction-decode machine)
  (define bstr (register-get machine 'MDR))
  (struct-copy vm machine
               [decoded (decoded-create bstr)]))
