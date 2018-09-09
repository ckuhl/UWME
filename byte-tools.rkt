#lang racket

; General byte manipulation tools

(provide (contract-out [struct decoded ((opcode (and/c exact-nonnegative-integer? (between/c 0 (expt 2 6))))
					(rs (and/c exact-nonnegative-integer? (between/c 0 (expt 2 5))))
					(rt (and/c exact-nonnegative-integer? (between/c 0 (expt 2 5))))
					(rd (and/c exact-nonnegative-integer? (between/c 0 (expt 2 5))))
					(shamt (and/c exact-nonnegative-integer? (between/c 0 (expt 2 5))))
					(funct (and/c exact-nonnegative-integer? (between/c 0 (expt 2 6))))
					(immediate (and/c exact-nonnegative-integer? (between/c 0 (expt 2 16))))
					(address (and/c exact-nonnegative-integer? (between/c 0 (expt 2 26)))))])
	 make-decoded)

(require "constants.rkt")
(require "sparse-list.rkt")

(struct decoded (opcode rs rt rd shamt funct immediate address)
  #:transparent)

(define/contract
  (make-decoded word)
  ((and/c exact-nonnegative-integer? (</c (expt 2 32))) . -> . decoded?)
  (decoded
    (arithmetic-shift (bitwise-and opcode-mask word) opcode-offset)
    (arithmetic-shift (bitwise-and rs-mask word) rs-offset)
    (arithmetic-shift (bitwise-and rt-mask word) rt-offset)
    (arithmetic-shift (bitwise-and rd-mask word) rd-offset)
    (arithmetic-shift (bitwise-and shamt-mask word) shamt-offset)
    (arithmetic-shift (bitwise-and funct-mask word) funct-offset)
    (arithmetic-shift (bitwise-and immediate-mask word) immediate-offset)
    (arithmetic-shift (bitwise-and address-mask word) address-offset)
    ))

