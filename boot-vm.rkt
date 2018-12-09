#lang racket/base

(provide default-vm
         load-file
         load-twoints
         load-array)

(require racket/list
         racket/hash

         "vm.rkt"
         "binary-loader.rkt"
         "bytes.rkt"
         "decoded.rkt")

;; Constants
(define stack-pointer  (bytes #x01 #x00 #x00 #x00))
(define return-address (bytes #x81 #x23 #x45 #x6c))

;; Default register setup
(define default-registers
  (make-immutable-hash
    (append (for/list ([i (range 0 30)]) (cons i (make-bytes 4 0)))
            (list
              (cons    30 stack-pointer)
              (cons    31 return-address)
              (cons   'PC (make-bytes 4 0))
              (cons  'MAR (make-bytes 4 0))
              (cons  'MDR (make-bytes 4 0))
              (cons 'HILO (make-bytes 8 0))))))


;; Default register values
(define default-vm (make-vm default-registers (make-immutable-hash) empty-decoded))


;; Update memory with the file addesses
(define (load-file filename machine)
  (struct-copy
    vm machine
    [mem (hash-union (vm-mem machine)
                     (file->hash filename))]))


;; Load integers into $1 and $2 from the command line
(define (load-twoints machine)
  (struct-copy
    vm machine
    [rf (hash-set*
          (vm-rf machine)
          #b00001 (begin (eprintf "Enter value for register 1: ")
                         (integer->bytes (read) #:size-n 4 #:signed? #t))
          #b00010 (begin (eprintf "Enter value for register 2: ")
                         (integer->bytes (read) #:size-n 4 #:signed? #t)))]))


;; Load array into vm from CLI
(define (load-array machine)
  (define array-size (begin (eprintf "Enter length of array: ") (read)))
  (define array-offset (+ 4 (max (hash-keys (vm-mem machine)))))

  (define pairs
    (for/list ([i (range 0 array-size)])
      (eprintf "Enter array element ~a: " i)
      (cons
        (+ array-offset (* array-size 4))
        (integer->bytes (read) #:size-n 4 #:signed? #t))))

  (struct-copy
    vm machine
    [rf (hash-set*
          (vm-rf machine)
          #b00001 (integer->bytes array-offset #:size-n 4 #:signed? #t)
          #b00010 (integer->bytes array-size #:size-n 4 #:signed? #t))]
    [mem (hash-set (vm-mem machine) pairs)]))
