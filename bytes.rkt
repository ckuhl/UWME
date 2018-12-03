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
  (test-equal?
    "largest unsigned 32 bit integer"
    (bytes->integer (bytes #xff #xff #xff #xff) #:signed? #t)
    -1)
  (test-equal?
    "smallest unsigned 32 bit integer"
    (bytes->integer (bytes #x00 #x00 #x00 #x00) #:signed? #t)
    0)
  (test-equal?
    "largest signed 32 bit integer"
    (bytes->integer (bytes #x7f #xff #xff #xff) #:signed? #t)
    2147483647)
  (test-equal?
    "smallest signed 32 bit integer"
    (bytes->integer (bytes #x80 #x00 #x00 #x00) #:signed? #t)
    -2147483648)
  (test-equal?
    "largest unsigned 32 bit integer"
    (bytes->integer (bytes #xff #xff #xff #xff) #:signed? #f)
    4294967296)
  (test-equal?
    "smallest unsigned 32 bit integer"
    (bytes->integer (bytes #x00 #x00 #x00 #x00) #:signed? #f)
    0)
  (test-equal?
    "largest signed 32 bit integer"
    (bytes->integer (bytes #x7f #xff #xff #xff) #:signed? #f)
    2147483647)
  (test-equal?
    "smallest signed 32 bit integer"
    (bytes->integer (bytes #x80 #x00 #x00 #x00) #:signed? #f)
    2147483648))


;; Wrapper for integer->integer-bytes, with project defaults set
(define (integer->bytes n
                        #:size-n [size-n 4]
                        #:signed? signed?
                        #:big-endian? [big-endian? #t])
  (integer->integer-bytes n size-n signed? big-endian?))

(module+ test
  (require rackunit)
  (test-equal?
    "largest unsigned 32 bit integer"
    (bytes->integer -1 #:signed? #t #:size 2)
    (bytes #xff #xff))
  (test-equal?
    "smallest unsigned 32 bit integer"
    (bytes->integer 0 #:signed? #t #:size 1)
    (bytes #x00))
  (test-equal?
    "largest signed 32 bit integer"
    (bytes->integer 2147483647 #:signed? #t)
    (bytes #x7f #xff #xff #xff))
  (test-equal?
    "smallest signed 32 bit integer"
    (bytes->integer -2147483648 #:signed? #t)
    (bytes #x80 #x00 #x00 #x00))
  (test-equal?
    "largest unsigned 32 bit integer"
    (bytes->integer 4294967296 #:signed? #f)
    (bytes #xff #xff #xff #xff))
  (test-equal?
    "smallest unsigned 32 bit integer"
    (bytes->integer 0 #:signed? #f)
    (bytes #x00 #x00 #x00 #x00))
  (test-equal?
    "largest signed 32 bit integer"
    (bytes->integer 2147483647 #:signed? #f)
    (bytes #x7f #xff #xff #xff))
  (test-equal?
    "smallest signed 32 bit integer"
    (bytes->integer 2147483648 #:signed? #f)
    (bytes #x80 #x00 #x00 #x00)))


;; Apply the operation [op] to [signed?] [bstrs], and output a bstr of [size-n]
(define (bytes-apply op
                     #:signed? signed?
                     #:size-n [size-n 4]
                     #:big-endian? [big-endian? #t]
                     . bstrs)
  ;; Create mappable function (to apply to list of bytestrings)
  (define bytes-converter (lambda (x) (integer-bytes->integer x signed? big-endian?)))
  ;; Apply operation to integer list
  (define integer-result (apply op (map bytes-converter bstrs)))
  ;; Convert integer result back to bytes
  (integer->integer-bytes integer-result size-n signed? big-endian?))

(module+ test
  (require rackunit)
  (test-equal?
    "Unsigned and size of 1"
    (bytes-apply + #:signed? #f #:size? 1 (bytes 50) (bytes 25) (bytes 15) (bytes 10))
    (bytes 100))
  (test-equal?
    "Signed and default size"
    (bytes-apply - #:signed? #t (bytes 50) (bytes 25) (bytes 15) (bytes 10))
    (bytes 0 0 0 0))
  (test-equal?
    "Unsigned and multi-byte bytestrings"
    (bytes-apply + #:signed? #f (bytes 10 0 0 0) (bytes 10 0 0) (bytes 10 0) (bytes 10))
    (bytes 10 10 10 10)))
