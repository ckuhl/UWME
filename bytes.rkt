#lang racket/base


(provide (all-defined-out))


;; Byte conversion helpers
(define (bytes->signed b)
  (integer-bytes->integer b #t #t))

(module+ test
  (require rackunit)
  (test-case
    (check-equal?
      (bytes->signed (bytes #xff #xff #xff #xff))
      -1
      ;4294967296
      "largest unsigned integer"))
  (test-case
    (check-equal?
      (bytes->signed (bytes #x00 #x00 #x00 #x00))
      0
      "smallest unsigned integer"))
  (test-case
    (check-equal?
      (bytes->signed (bytes #x7f #xff #xff #xf))
      2147483647
      "largest signed integer"))
  (test-case
    (check-equal?
      (bytes->signed (bytes #x80 #x00 #x00 #x00))
      -2147483648
      "smallest signed integer")))

(define (bytes->unsigned b)
  (integer-bytes->integer b #f #t))

(module+ test
  (require rackunit)
  (test-case
    (check-equal?
      (bytes->unsigned (bytes #xff #xff #xff #xff))
      4294967296
      "largest unsigned integer"))
  (test-case
    (check-equal?
      (bytes->unsigned (bytes #x00 #x00 #x00 #x00))
      0
      "smallest unsigned integer"))
  (test-case
    (check-equal?
      (bytes->unsigned (bytes #x7f #xff #xff #xf))
      2147483647
      "largest signed integer"))
  (test-case
    (check-equal?
      (bytes->unsigned (bytes #x80 #x00 #x00 #x00))
      2147483648
      "smallest signed integer")))

(define (signed->word n)
  (integer->integer-bytes n 4 #t #t))

(define (unsigned->word n)
  (integer->integer-bytes n 4 #f #t))

(define (signed->dword n)
  (integer->integer-bytes n 8 #t #t))

(define (unsigned->dword n)
  (integer->integer-bytes n 8 #f #t))
