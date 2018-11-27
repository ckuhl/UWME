#lang racket/base


(provide bytes->integer
         integer->bytes
         bytes-apply)


;; Wrapper for integer-bytes->integer, with project defaults set
(define (bytes->integer bstr
                        #:signed? signed?
                        #:big-endian? [big-endian? #t])
  (integer-bytes->integer bstr signed? big-endian?))

(module+ test
  (require rackunit)
  (test-case
    (check-equal?
      (bytes->integer (bytes #xff #xff #xff #xff) #:signed? #t)
      -1
      ; should wrap to 4294967296
      "largest unsigned integer"))
  (test-case
    (check-equal?
      (bytes->integer (bytes #x00 #x00 #x00 #x00) #:signed? #t)
      0
      "smallest unsigned integer"))
  (test-case
    (check-equal?
      (bytes->integer (bytes #x7f #xff #xff #xff) #:signed? #t)
      2147483647
      "largest signed integer"))
  (test-case
    (check-equal?
      (bytes->integer (bytes #x80 #x00 #x00 #x00) #:signed? #t)
      -2147483648
      "smallest signed integer"))
  (test-case
    (check-equal?
      (bytes->integer (bytes #xff #xff #xff #xff) #:signed? #f)
      4294967296
      "largest unsigned integer"))
  (test-case
    (check-equal?
      (bytes->integer (bytes #x00 #x00 #x00 #x00) #:signed? #f)
      0
      "smallest unsigned integer"))
  (test-case
    (check-equal?
      (bytes->integer (bytes #x7f #xff #xff #xff) #:signed? #f)
      2147483647
      "largest signed integer"))
  (test-case
    (check-equal?
      (bytes->integer (bytes #x80 #x00 #x00 #x00) #:signed? #f)
      2147483648
      "smallest signed integer")))

;; Wrapper for integer->integer-bytes, with project defaults set
(define (integer->bytes n
                        #:size-n [size-n 4]
                        #:signed? signed?
                        #:big-endian? [big-endian? #t])
  (integer->integer-bytes n size-n signed? big-endian?))


;; Apply the operation [op] to [signed?] [bstrs], and output a bstr of [size-n]
(define (bytes-apply op
                     #:signed? signed?
                     #:size-n [size-n 4]
                     #:big-endian? [big-endian? #t]
                     . bstrs)
  ;; Convert bytes to integers
  (define mapper (lambda (x) (integer-bytes->integer x signed? big-endian?)))
  ;; Apply operation to integers
  (define output (apply op (map mapper bstrs)))
  ;; Convert integers to bytes
  (integer->integer-bytes output size-n signed? big-endian?))
