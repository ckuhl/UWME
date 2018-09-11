#lang racket

; General byte manipulation tools

(require "predicates.rkt") ; unsigned-number-size-n?

(provide (contract-out [struct decoded ((opcode (unsigned-number-size-n? 6))
					(rs (unsigned-number-size-n? 5))
					(rt (unsigned-number-size-n? 5))
					(rd (unsigned-number-size-n? 5))
					(shamt (unsigned-number-size-n? 5))
					(funct (unsigned-number-size-n? 6))
					(immediate (unsigned-number-size-n? 16))
					(address (unsigned-number-size-n? 26)))])
	 make-decoded
	 unsigned->signed
	 signed->unsigned
	 read-word-from-memory)

(require "constants.rkt" ; magic numbers
	 "sparse-list.rkt") ; `read-word-from-memory` uses sparse-list-ref


(struct decoded (opcode rs rt rd shamt funct immediate address)
  #:transparent)

(define/contract
  (make-decoded word)
  ((unsigned-number-size-n? 32) . -> . decoded?)
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

;; Concert a decimal number representing an unsigned binary value to the
;equivalent value if the binary was signed
(define/contract
  (unsigned->signed number size)
  (->i ([x (y) (unsigned-number-size-n? y)]
	[y exact-positive-integer?])
       [result integer?])
  (cond
    [(>= number (expt 2 (sub1 size)))
     (- number (arithmetic-shift 1 size))]
    [else number]))

(define/contract
  (signed->unsigned number size)
  (->i ([x (y) (signed-number-size-n? y)]
	[y exact-positive-integer?])
       [result integer?])
  (cond
    [negative?
      (+ number (arithmetic-shift 1 size))]
    [else number]))

; Read word in as a series of bytes from memory, starting at addr + offset = 0
(define/contract
  (read-word-from-memory mem addr)
  (sparse-list? exact-nonnegative-integer? . -> . (unsigned-number-size-n? 32))
  (apply + (for/list ([offset (range 0 4)]
		      [bitshift (reverse (range 0 32 8))])
	     (arithmetic-shift (sparse-list-ref mem (+ offset addr)) bitshift))))

