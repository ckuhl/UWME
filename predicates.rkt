#lang racket

(provide immutable-hash?
	 has-n-bits?)

; alias predicate for an immutable hash
(define immutable-hash? (and/c hash? hash-equal? immutable?))

; check if a number falls in the range [0, 2^n-1]
(define (unsigned-number-size-n?
	  (and/c exact-nonnegative-integer? (between/c 0 (expt 2 n)))))

; check if a number falls in the range [-2^(n-1), 2^(n-1)-1]
(define (signed-number-size-n?
	  (and/c exact-integer? (between/c (- (expt 2 (sub1 n)))
					   (sub1 (expt 2 (sub1 n)))))))
