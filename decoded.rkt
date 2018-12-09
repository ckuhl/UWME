#lang racket/base

;; Representation of the decoded fields of an instruction

(provide (struct-out decoded)
         empty-decoded
         decoded-create)

(require "bytes.rkt")


;; The fields of interest to extract from a word
(define-struct
  decoded
  (opcode
    reg-source
    reg-target
    reg-dest
    shamt
    funct
    immediate)
  #:transparent)

(define empty-decoded (make-decoded 0 0 0 0 0 0 0))

(define (decoded-create bstr)
  (define integer-value (bytes->integer bstr #:signed? #f))
  (decoded
    (bitwise-bit-field integer-value 26 32)
    (bitwise-bit-field integer-value 21 26)
    (bitwise-bit-field integer-value 16 21)
    (bitwise-bit-field integer-value 11 16)
    (bitwise-bit-field integer-value  6 11)
    (bitwise-bit-field integer-value  0  6)
    (bytes->integer (subbytes bstr 2 4) #:signed? #t)))
