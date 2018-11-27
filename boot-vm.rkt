#lang racket/base

(provide default-vm
         load-file
         load-twoints
         load-array)

(require racket/list
         racket/hash

         "vm.rkt"
         "binary-loader.rkt"
         "bytes.rkt")


;; static memory hash
(define (memory-hash filename)
  (file->hash filename))


;; Static register hash
(define stack-pointer  #x01000000)
(define return-address #x8123456c)
(define register-hash
  (make-immutable-hash
    (append (for/list ([i (range 1 30)]) (cons i (make-bytes 4 0)))
            (list
              (cons 0 (make-bytes 4 0))
              (cons 30 (integer->bytes stack-pointer #:size-n 4 #:signed? #f))
              (cons 31 (integer->bytes return-address #:size-n 4 #:signed? #f))
              (cons 'PC (make-bytes 4 0))
              (cons 'MAR (make-bytes 4 0))
              (cons 'MDR (make-bytes 4 0))
              (cons 'HILO (make-bytes 8 0))))))

(define default-vm (make-vm register-hash (make-immutable-hash)))

;; Update memory with the file addesses
(define (load-file filename machine)
  (struct-copy
    vm machine
    [mem (hash-union (vm-mem machine)
                     (memory-hash filename))]))


;; Load two integers into registers $1 and $2 from CLI
(define (load-twoints machine)
    (register-set
      (register-set
        machine
        1
        (begin (eprintf "Enter value for register 1: ")
               (integer->bytes (read) #:size-n 4 #:signed? #t)))
      2
      (begin (eprintf "Enter value for register 2: ")
             (integer->bytes (read) #:size-n 4 #:signed? #t))))


;; Load array into vm from CLI
(define (load-array machine)
  (define mem (vm-mem machine))

  (define array-size (begin (eprintf "Enter length of array: ") (read)))
  (define array-offset (+ 4 (max (hash-keys mem))))

  (define pairs
    (for/list ([i (range 0 array-size)])
      (eprintf "Enter array element ~a: " i)
      (cons
        (+ array-offset (* array-size 4))
        (integer->bytes (read) #:size-n 4 #:signed? #t))))

  (struct-copy
    vm machine
    [rf (hash-set
          (vm-rf machine)
          #b00001 (integer->bytes array-offset #:size-n 4 #:signed? #t)
          #b00010 (integer->bytes array-size #:size-n 4 #:signed? #t))]
    [mem (hash-set mem pairs)]))
