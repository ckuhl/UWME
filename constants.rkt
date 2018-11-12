#lang racket/base

(provide (all-defined-out))


(define opcode-to-name
  (make-immutable-hash
    '((#b000000 . r-type)
      (#b100011 . lw)
      (#b101011 . sw)
      (#b000100 . beq)
      (#b000101 . bne))))

(define funct-to-name
  (make-immutable-hash
    '((#b100000 . add)
      (#b100010 . sub)
      (#b011000 . mult)
      (#b011001 . multu)
      (#b011010 . div)
      (#b011011 . divu)
      (#b010000 . mfhi)
      (#b010010 . mflo)
      (#b010100 . lis)
      (#b101010 . slt)
      (#b101011 . sltu)
      (#b001000 . jr)
      (#b001001 . jalr))))

(define word-size 4) ; in bytes

(define return-address #x8123456c)

(define hi-result-mask #xffff0000)
(define lo-result-mask #x0000ffff)
(define       lsb-mask #x000000ff)
