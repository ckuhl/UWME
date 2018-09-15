#lang racket

; implement the registerfile of a MIPS processor

(provide create-registerfile
	 registerfile?
	 registerfile-ref
	 registerfile-set
	 registerfile-set*)

(require "constants.rkt") ; magic numbers


;; registerfile container
; k: default key value
; _impl: internal representation of registers
(struct registerfile k _impl)

; Initialize registers
(define/contract
  (initialize-registers pc default)
  (exact-nonnegative-integer? bytes? . -> . registerfile?)
  (make-immutable-hash
    (append (for/list ([i (range 0 30)]) (cons i default))
	    (list
	      (cons 30 (integer->integer-bytes stack-pointer 4 #f))
	      (cons 31 (integer->integer-bytes return-address 4 #f))
	      (cons 'HI default)
	      (cons 'LO default)
	      (cons 'PC (integer->integer-bytes pc 4 #f))
	      (cons 'IR default)
	      (cons 'MAR default)
	      (cons 'MDR default)))))

;; get the value of a single register
(define/contract
  (registerfile-ref rf k)
  (registerfile? (or/c symbol? exact-nonnegative-integer?) . -> . bytes?)
  (hash-ref (registerfile-_impl rf) k))

;; get the value of a single register as an integer
(define/contract
  (registerfile-integer-ref rf k signed)
  (registerfile? (or/c symbol? exact-nonnegative-integer?) . -> . exact-integer?)
  (integer-bytes->integer (registerfile-ref rf k) word-size signed))

;; set a single register
(define/contract
  (registerfile-set rf k v)
  (registerfile? (or/c symbol? exact-nonnegative-integer?) bytes? . -> . registerfile?)
  (make-registerfile (registerfile-k rf)
		     (hash-set (registerfile-_impl rf) k v)))


;; helper to set registerfile from an integer
(define/contract
  (registerfile-integer-set rf k v signed)
  (registerfile? (or/c symbol? exact-nonnegative-integer?) exact-integer? boolean? . -> . registerfile?)
  (registerfile-set rf k (integer->integer-bytes v word-width signed)))

;; helper to set multiple values frmo an integer
(define/contract
  (registerfile-integer-set* rf k v signed . kvs)
  (registerfile? (or/c symbol? exact-nonnegative-integer?) exact-integer? boolen? . -> . registerfile?)
  (registerfile-set* rf
		     k
		     (integer->integer-bytes v word-width signed)
		     (for ([i (range (length kvs))][j kvs])
		       (cond [(even? i) j]
			     [else (integer->integer-bytes j word-width signed)]))))


;; return a single predicate that sequentially applies a list of predicates to a list
; (e.g. (listof-alternating boolean? integer? string?) would apply to:
; (list #t 3 "str" #f -1231 "as" #t)
(define (listof-alternating . contracts)
  ((listof (any? . -> . boolean?)) . -> . ((listof any?) . -> . boolean?))
  (define c (length contracts))
  (lambda (lst)
    (and (for ([i lst]
	       [n (range (length lst))])
	   ((list-ref contracts (remainder n c)) i)))))

;; set multiple registers
(define/contract
  (registerfile-set* rf k v . kvs)
  (registerfile? (or/c symbol? exact-nonnegative-integer?) bytes? #:rest (listof-alternating (or/c symbol? exact-nonnegative-integer?) bytes?) . ->* . registerfile?)
  (make-registerfile (registerfile-k rf)
		     (hash-set* (registerfile-_impl rf) k v)))

