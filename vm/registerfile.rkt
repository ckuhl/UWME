#lang racket/base

; implement the registerfile of a MIPS processor


(provide initialize-registerfile ; set to default values
	 registerfile? ; predicate
	 registerfile-ref ; get register value
	 registerfile-integer-ref ; get register value as an int
	 registerfile-set ; set register value
	 registerfile-integer-set ; set register value from an int
	 registerfile-set-swap ; set two register values at once
	 registerfile-integer-set-swap ; set two reg values at once from ints

	 format-registerfile) ; pretty-print the registers


(require racket/contract
	 racket/list
	 racket/string
	 racket/format

	 "constants.rkt") ; magic numbers


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
      (append (for/list ([i (range 1 30)]) (cons i default))
	      (list
		(cons 0 (bytes 0 0 0 0))
		(cons 30 (integer->integer-bytes stack-pointer word-size #f #t))
		(cons 31 (integer->integer-bytes return-address word-size #f #t))
		(cons 'HI default)
		(cons 'LO default)
		(cons 'PC (integer->integer-bytes pc word-size #f #t))
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
  (integer-bytes->integer (registerfile-ref rf k) signed #t))

;; set a single register
(define/contract
  (registerfile-set rf k v)
  (registerfile? (or/c symbol? exact-nonnegative-integer?) bytes? . -> . registerfile?)
  (cond
    [(equal? 0 k) rf] ; writing to $0 doesn't change the value of zero
    [else (registerfile (hash-set (registerfile-_impl rf) k v))]))


;; helper to set registerfile from an integer
(define/contract
  (registerfile-integer-set rf k v signed)
  (registerfile? (or/c symbol? exact-nonnegative-integer?) exact-integer? boolean? . -> . registerfile?)
  (registerfile-set rf k (integer->integer-bytes v word-size signed #t)))

;; set multiple registers
(define/contract
  (registerfile-set-swap rf k1 v1 k2 v2)
  (registerfile?
    (or/c symbol? exact-nonnegative-integer?)
    bytes?
    (or/c symbol? exact-nonnegative-integer?)
    bytes?
    . -> .
    registerfile?)
  ; throw if trying to set the same register to two values (doesn't make sense!)
  (when (and (equal? k1 k2) (not (equal? v1 v2)))
    (raise-user-error 'registerfile "Cannot swap a register with itself"))
  (registerfile-set
    (registerfile-set rf k1 v1)
    k2
    v2))

;; set multiple registers from integer values
(define/contract
  (registerfile-integer-set-swap rf signed? k1 v1 k2 v2)
  (registerfile?
    boolean?
    (or/c symbol? exact-nonnegative-integer?)
    exact-integer?
    (or/c symbol? exact-nonnegative-integer?)
    exact-integer?
    . -> .
    registerfile?)
  (registerfile-set-swap
    rf
    k1
    (integer->integer-bytes v1 word-size signed? #t)
    k2
    (integer->integer-bytes v2 word-size signed? #t)))

(define/contract
  (format-registerfile rf)
  (registerfile? . -> . string?)
  (string-join
    (for/list ([i (range 1 32)])
      (format "$~a = 0x~a   ~a"
	      (~r i
		  #:sign #f
		  #:base 10
		  #:min-width 2
		  #:pad-string "0")
	      (~r (integer-bytes->integer (registerfile-ref rf i) #f #t)
		  #:sign #f
		  #:base 16
		  #:min-width 8
		  #:pad-string "0")
	      (if (zero? (modulo i 4)) "\n" ""))) ""))

