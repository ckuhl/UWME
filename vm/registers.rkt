#lang racket

(provide initialize-registers
	 registers?)

(require "constants.rkt") ; magic numbers

(define (registers? v)
  (and (hash? v)
       (hash-equal? v)
       (immutable? v)))

; Initialize registers
(define/contract
  (initialize-registers pc)
  (exact-nonnegative-integer? . -> . registers?)
  (make-immutable-hash (append (for/list ([i (range 0 30)]) (cons i 0))
			       (list
				 (cons 30 (integer->integer-bytes stack-pointer 4 #f))
				 (cons 31 (integer->integer-bytes return-address 4 #f))
				 (cons 'HI (bytes 0 0 0 0))
				 (cons 'LO (bytes 0 0 0 0))
				 (cons 'PC (integer->integer-bytes pc 4 #f))
				 (cons 'IR (bytes 0 0 0 0))
				 (cons 'MAR (bytes 0 0 0 0))
				 (cons 'MDR (bytes 0 0 0 0))))))

