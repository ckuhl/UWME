#lang racket

; implement the registerfile of a MIPS processor

(provide initialize-registerfile
	 registerfile?
	 registerfile-ref
	 registerfile-integer-ref
	 registerfile-set
	 registerfile-integer-set
	 registerfile-set*
	 registerfile-integer-set*)

(require "constants.rkt") ; magic numbers


;; registerfile container
; k: default key value
; _impl: internal representation of registers
(struct registerfile (_impl))

; Initialize registers
(define/contract
  (initialize-registerfile [pc 0] [default (bytes 0 0 0 0)])
  (() (exact-nonnegative-integer? bytes?) . ->* . registerfile?)
  (registerfile
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
	      (cons 'MDR default))))))

;; get the value of a single register
(define/contract
  (registerfile-ref rf k)
  (registerfile? (or/c symbol? exact-nonnegative-integer?) . -> . bytes?)
  (hash-ref (registerfile-_impl rf) k))

;; get the value of a single register as an integer
(define/contract
  (registerfile-integer-ref rf k signed)
  (registerfile? (or/c symbol? exact-nonnegative-integer?) boolean? . -> . exact-integer?)
  (integer-bytes->integer (registerfile-ref rf k) word-size signed))

;; set a single register
(define/contract
  (registerfile-set rf k v)
  (registerfile? (or/c symbol? exact-nonnegative-integer?) bytes? . -> . registerfile?)
  (registerfile (hash-set (registerfile-_impl rf) k v)))


;; helper to set registerfile from an integer
(define/contract
  (registerfile-integer-set rf k v signed)
  (registerfile? (or/c symbol? exact-nonnegative-integer?) exact-integer? boolean? . -> . registerfile?)
  (registerfile-set rf k (integer->integer-bytes v word-size signed)))

;; helper to set multiple values frmo an integer
(define/contract
  (registerfile-integer-set* rf k v signed . kvs)
  (registerfile? (or/c symbol? exact-nonnegative-integer?) exact-integer? boolean? . -> . registerfile?)
  (registerfile-set* rf
		     k
		     (integer->integer-bytes v word-size signed)
		     (for ([i (range (length kvs))][j kvs])
		       (cond [(even? i) j]
			     [else (integer->integer-bytes j word-size signed)]))))

  ;; set multiple registers
  (define/contract
    (registerfile-set* rf k v . kvs)
    ; TODO is there a more constrained contract for `rest` key-value pairs?
    (->*
      (registerfile? (or/c symbol? exact-nonnegative-integer?) bytes?)
      ()
      #:rest (listof (or/c bytes? symbol? exact-nonnegative-integer?))
      registerfile?)
  (registerfile (hash-set* (registerfile-_impl rf) k v)))

