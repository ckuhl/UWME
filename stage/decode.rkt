#lang racket/base

(provide
  decode
  decoded)

(require
  "../bytes.rkt")


(struct decoded
  (opcode
    reg-source
    reg-target
    reg-dest
    shamt
    funct
    immediate)
  #:transparent)

;; Decode an instruction into a set of fields
(define (decode bstr)
  (define integer-value (integer-bytes->integer bstr #f #t))

  (decoded
    (bitwise-bit-field integer-value 26 32)
    (bitwise-bit-field integer-value 21 26)
    (bitwise-bit-field integer-value 16 21)
    (bitwise-bit-field integer-value 11 16)
    (bitwise-bit-field integer-value  6 11)
    (bitwise-bit-field integer-value  0  6)
    (bytes->integer (subbytes bstr 2 4) #:signed? #t)))
