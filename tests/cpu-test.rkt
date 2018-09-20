#lang racket/base


(require racket/contract
	 rackunit
	 "../vm/constants.rkt"
	 "../vm/cpu.rkt"
	 "../vm/registerfile.rkt"
	 "../vm/memory.rkt"
	 "../vm/word.rkt")


;; Prepare memory
(define/contract (prepare-memory . kvps)
		 (() () #:rest (listof (cons/c exact-nonnegative-integer? bytes?)) . ->* . memory?)
		 (for/fold ([mem (initialize-memory)])
		   ([kvp kvps])
		   (memory-set mem (car kvp) (cdr kvp))))

;; Prepare registerfile
(define/contract (prepare-registerfile . kvps)
		 (() () #:rest (listof (cons/c (or/c symbol? exact-nonnegative-integer?) bytes?)) . ->* . registerfile?)
		 (for/fold ([rf (initialize-registerfile)])
		   ([kvp kvps])
		   (registerfile-set rf (car kvp) (cdr kvp))))

;; a shim that loads registers, performs an ALU operation, and then returns the value
(define/contract
  (alu-shim aluop r1 r2)
  ((word? registerfile? memory? . -> . (list/c registerfile? memory?)) bytes? bytes? . -> . bytes?)
  (define rf (prepare-registerfile (cons 1 r1) (cons 2 r2)))
  (define mem (make-memory #b01000000 (bytes 0 0 0 0)))
  ; TODO should I look up actual funct for accuracy?
  (define w (make-r-type-word 1 2 3 #b000000))

  (registerfile-ref (car (aluop w rf mem))
		    3))


; add
;; zero identity
(check-equal? (bytes 0 0 0 0)
	      (alu-shim cpu:add (bytes 0 0 0 0) (bytes 0 0 0 0)))

;; negative cancellation
(check-equal? (bytes 0 0 0 0)
	      (alu-shim cpu:add (bytes 255 255 255 255) (bytes 0 0 0 1)))


; sub


; mult


; multu


; div


; divu


; mfhi


; mflo


; lis


; lw


; sw


; slt


; sltu


; beq


; bne


; jr


; jalr

