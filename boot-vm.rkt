#lang racket/base

(provide (struct-out vm)
         default-vm
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
    (append (for/list ([i (range 1 30)]) (cons i (bytes 0 0 0 0)))
            (list
              (cons 0 (bytes 0 0 0 0))
              (cons 30 (unsigned->word stack-pointer))
              (cons 31 (unsigned->word return-address))
              (cons 'PC (bytes 0 0 0 0))
              (cons 'MAR (bytes 0 0 0 0))
              (cons 'MDR (bytes 0 0 0 0))
              (cons 'HILO (bytes 0 0 0 0 0 0 0 0))))))

(define default-vm (make-vm register-hash (make-immutable-hash)))

;; Update memory with the file addesses
(define (load-file filename machine)
  (struct-copy
    vm machine
    [mem (hash-union (vm-mem machine)
                     (memory-hash filename))]))


;; Load two integers into registers $1 and $2 from CLI
(define (load-twoints machine)
  (define new-rf
    (set-register
      (set-register
        machine
        1
        (begin (eprintf "Enter value for register 1: ")
               (signed->word (read))))
      2
      (begin (eprintf "Enter value for register 2: ")
             (signed->word (read))))))


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
        (signed->word (read)))))

  (struct-copy
    vm machine
    [rf (hash-set
          (vm-rf machine)
          #b00001 (signed->word array-offset)
          #b00010 (signed->word array-size))]
    [mem (hash-set mem pairs)]))
