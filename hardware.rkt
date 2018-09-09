#lang racket

; Stores the "hardware" (= registers and MEM)

(provide initialize-registers initialize-memory load-bytes-from-stdin)

(require "constants.rkt" ; magic numbers
"sparse-list.rkt" ; operating on MEM
"alu.rkt") ; ALU operations

; Initialize registers
(define/contract
  (initialize-registers pc)
  (exact-nonnegative-integer? . -> . (and/c hash? hash-equal? immutable?))
  (make-immutable-hash (append (for/list ([i (range 0 30)]) (cons i 0))
			       (list
				 (cons 30 stack-pointer)
				 (cons 31 return-address)
				 (cons 'HI 0)
				 (cons 'LO 0)
				 (cons 'PC pc)
				 (cons 'IR 0)
				 (cons 'MAR 0)
				 (cons 'MDR 0)))))

;; Initialize memory
(define/contract
  (initialize-memory payload
		     [memory (make-sparse-list MEMORY-SIZE MEMORY-LOAD-OFFSET)]
		     [offset 0])
  (((listof byte?)) (sparse-list? exact-nonnegative-integer?) . ->* . sparse-list?)
  (cond
    [(empty? payload) memory]
    [else (initialize-memory (cdr payload)
			     (sparse-list-set memory offset (car payload))
			     (+ 1 offset))]))

(define/contract
  (load-bytes-from-stdin)
  (-> (listof byte?))
  (define next (read-byte))
  (cond
    [(eof-object? next) empty]
    [else (cons next (load-bytes-from-stdin))]))

