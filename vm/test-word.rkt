#lang racket

(require rackunit)

(require "word.rkt")

; bytes->integer =============================================================
; basic
(check-equal? (bytes->integer (bytes 0 0 0 0)) 0)

; unsigned
(check-equal? (bytes->integer (bytes #x7f #xff #xff #xff)) (sub1 (expt 2 31)))
(check-equal? (bytes->integer (bytes #xff #xff #xff #xff)) (sub1 (expt 2 32)))
(check-equal? (bytes->integer (bytes #x80 #x00 #x00 #x00)) (expt 2 31))
(check-equal? (bytes->integer (bytes #x80 #x00 #x00 #x00) #f) (expt 2 31))

; signed
(check-equal? (bytes->integer (bytes #x7f #xff #xff #xff) #t) (sub1 (expt 2 31)))
(check-equal? (bytes->integer (bytes #xff #xff #xff #xff) #t) (- (expt 2 32) (expt 2 32) 1))
(check-equal? (bytes->integer (bytes #x80 #x00 #x00 #x00) #t) (- (sub1 (expt 2 32))))

; integer->bytes =============================================================
;; zero
(check-equal? (integer->bytes 0) (bytes 0))

;; zero extended
(check-equal? (integer->bytes 0 4) (bytes 0 0 0 0))

;; positive
(check-equal? (integer->bytes 15) (bytes #b00001111))

;; positive extended
(check-equal? (integer->bytes 15 2) (bytes #x000f))

;; negative
(check-equal? (integer->bytes -15) (bytes #b11110001))

;; negative extended
(check-equal? (integer->bytes -15 2) (bytes #xff #xf1))

; extract-bits ===============================================================
(check-equal? (extract-bits (bytes #b00111100) 2 6) 15)
(check-equal? (extract-bits (bytes #xff) 0 8) #xff)

;; spanning multiple bytes
(check-equal? (extract-bits (bytes #xff #xff #xff #xff) 0 32) #xffffffff)

;; spanning byte boundaries
(check-equal? (extract-bits (bytes #xff #x0f #xf0 #xff) 12 20) #xff)

