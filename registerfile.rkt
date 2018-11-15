#lang racket/base

; implement the registerfile of a MIPS processor

(provide initialize-rf ; set to default values
         rf? ; predicate
         rf-ref ; get register value
         rf-set ; set register value
         rf-set-swap ; set two register values at once

         format-rf) ; pretty-print the registers


(require racket/contract
         racket/list
         racket/string
         racket/format

         "constants.rkt"
         "word.rkt") ; magic numbers


;; Constants
(define stack-pointer  #x01000000)


;; registerfile container
; k: default key value
; _impl: internal representation of registers
(struct rf (_impl))


; Initialize registers
(define/contract
  (initialize-rf [pc 0] [default (bytes 0 0 0 0)])
  (() (exact-nonnegative-integer? bytes?) . ->* . rf?)
  (rf
    (make-immutable-hash
      (append (for/list ([i (range 1 30)]) (cons i default))
              (list
                (cons 0 (bytes 0 0 0 0))
                (cons 30 (unsigned->bytes stack-pointer))
                (cons 31 (unsigned->bytes return-address))
                (cons 'HI default)
                (cons 'LO default)
                (cons 'PC (unsigned->bytes pc))
                (cons 'IR default)
                (cons 'MAR default)
                (cons 'MDR default))))))


;; get the value of a single register
(define/contract
  (rf-ref rf k)
  (rf? (or/c symbol? exact-nonnegative-integer?) . -> . bytes?)
  (hash-ref (rf-_impl rf) k))


;; set a single register
(define/contract
  (rf-set r k v)
  (rf? (or/c symbol? exact-nonnegative-integer?) bytes? . -> . rf?)
  (cond
    [(equal? 0 k) rf] ; writing to $0 doesn't change the value of zero
    [else (rf (hash-set (rf-_impl r) k v))]))


;; set multiple registers
(define/contract
  (rf-set-swap rf k1 v1 k2 v2)
  (rf? (or/c symbol? exact-nonnegative-integer?) bytes? (or/c symbol? exact-nonnegative-integer?) bytes? . -> . rf?)

  ; throw if trying to set the same register to two values (doesn't make sense!)
  (when (and (equal? k1 k2))
    (raise-user-error 'rf "Cannot swap a register with itself"))

  (rf-set
    (rf-set rf k1 v1)
    k2
    v2))

;; Format registerfile for pretty-printing
(define/contract
  (format-rf rf)
  (rf? . -> . string?)
  (string-join
    (for/list ([i (range 1 32)])
      (format "$~a = 0x~a   ~a"
              (~r i
                  #:sign #f
                  #:base 10
                  #:min-width 2
                  #:pad-string "0")
              (~r (integer-bytes->integer (rf-ref rf i) #f #t)
                  #:sign #f
                  #:base 16
                  #:min-width 8
                  #:pad-string "0")
              (if (zero? (modulo i 4)) "\n" ""))) ""))

