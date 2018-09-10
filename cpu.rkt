#lang racket

; CPU: fetch / decode / execute the bytecode

(provide fetch decode execute)

(require "output.rkt" ; printing
	 "constants.rkt" ; magic numbers
	 "alu.rkt" ; ALU functions
	 "ops.rkt" ; Operations
	 "sparse-list.rkt" ; accessing MEM
	 "predicates.rkt" ; simplify contracts
	 "byte-tools.rkt") ; operating on bytes

; fetch
(define/contract
  (fetch registers mem)
  (immutable-hash? sparse-list? . -> . void?)
  (cond
    [(equal? (hash-ref registers 'PC) return-address)
     (eprint-registers registers)
     (exit 0)]
    [else
      (define next-ir
	(+
	  (arithmetic-shift (sparse-list-ref mem (+ 0 (hash-ref registers 'PC))) 24)
	  (arithmetic-shift (sparse-list-ref mem (+ 1 (hash-ref registers 'PC))) 16)
	  (arithmetic-shift (sparse-list-ref mem (+ 2 (hash-ref registers 'PC)))  8)
	  (arithmetic-shift (sparse-list-ref mem (+ 3 (hash-ref registers 'PC)))  0)))

      ; TODO should there be a switch to output line-by-line execution?
      ; (eprint-word next-ir) ; output each word to stderr

      (decode
	(hash-set
	  (hash-set registers
		    'IR
		    next-ir)
	  'PC
	  (+ (hash-ref registers 'PC) word-size))
	mem)]))

; decode
(define/contract
  (decode registers mem)
  (immutable-hash? sparse-list? . -> . void?)
  (execute
    (make-decoded (hash-ref registers 'IR))
    registers
    mem))

(define/contract
  (execute current registers mem)
  (decoded? immutable-hash? sparse-list? . -> . void?)

  (define op (decoded-opcode current))
  (define fu (decoded-funct current))

  (cond
    [(equal? op r-type-opcode) ; ALU
     (if (not (equal? (decoded-shamt current) 0)) (raise-user-error 'CPU "`shamt` must be #b00000 for R-type operations, got ~b instead" (decoded-shamt current)) #t)
     (fetch
       (cond
	 [(equal? fu add-funct)
	  (add (decoded-rs current)
	       (decoded-rt current)
	       (decoded-rd current)
	       registers)]
	 [(equal? fu sub-funct)
	  (sub (decoded-rs current)
	       (decoded-rt current)
	       (decoded-rd current)
	       registers)]
	 [(equal? fu mult-funct)
	  (if (not (equal? (decoded-rd current) 0)) (raise-user-error 'CPU "`rd` must be #b0000 for multu operation") #t)
	  (mult (decoded-rs current)
		(decoded-rt current)
		registers)]
	 [(equal? fu multu-funct)
	  (if (not (equal? (decoded-rd current) 0)) (raise-user-error 'CPU "`rd` must be #b0000 for multu operation") #t)
	  (multu (decoded-rs current)
		 (decoded-rt current)
		 registers)]
	 [(equal? fu div-funct)
	  (if (not (equal? (decoded-rd current) 0)) (raise-user-error 'CPU "`rd` must be #b0000 for div operation") #t)
	  (div (decoded-rs current)
	       (decoded-rt current)
	       registers)]
	 [(equal? fu divu-funct)
	  (if (not (equal? (decoded-rd current) 0)) (raise-user-error 'CPU "`rd` must be #b0000 for divu operation") #t)
	  (divu (decoded-rs current)
		(decoded-rt current)
		registers)]
	 [(equal? fu mfhi-funct)
	  (if (not (equal? (decoded-rs current) 0)) (raise-user-error 'CPU "`rs` must be #b0000 for mfhi operation") #t)
	  (if (not (equal? (decoded-rt current) 0)) (raise-user-error 'CPU "`rt` must be #b0000 for mfhi operation") #t)
	  (mfhi (decoded-rd current) registers)]
	 [(equal? fu mflo-funct)
	  (if (not (equal? (decoded-rs current) 0)) (raise-user-error 'CPU "`rs` must be #b0000 for mflo operation") #t)
	  (if (not (equal? (decoded-rt current) 0)) (raise-user-error 'CPU "`rt` must be #b0000 for mflo operation") #t)
	  (mflo (decoded-rd current) registers)]
	 [(equal? fu lis-funct)
	  (if (not (equal? (decoded-rs current) 0)) (raise-user-error 'CPU "`rs` must be #b0000 for lis operation") #t)
	  (if (not (equal? (decoded-rt current) 0)) (raise-user-error 'CPU "`rt` must be #b0000 for lis operation") #t)
	  (lis (decoded-rd current) registers mem)]
	 [(equal? fu slt-funct)
	  (slt (decoded-rs current)
	       (decoded-rt current)
	       (decoded-rd current)
	       registers)]
	 [(equal? fu sltu-funct)
	  (sltu (decoded-rs current)
		(decoded-rt current)
		(decoded-rd current)
		registers)]
	 [(equal? fu jr-funct)
	  (if (not (equal? (decoded-rt current) 0)) (raise-user-error 'CPU ": `rt` must be #b0000 for jr operation") #t)
	  (if (not (equal? (decoded-rd current) 0)) (raise-user-error 'CPU ": `rd` must be #b0000 for jr operation") #t)
	  (jr (decoded-rs current) registers)]
	 [(equal? fu jalr-funct)
	  ((if (not (equal? (decoded-rt current) 0)) (raise-user-error 'CPU ": `rt` must be #b0000 for jalr operation") #t)
	   (if (not (equal? (decoded-rd current) 0)) (raise-user-error 'CPU ": `rd` must be #b0000 for jalr operation") #t)
	   jalr (decoded-rs current) registers)]
	 [else
	   (raise-user-error 'ALU "given funct ~b does not exist" (decoded-funct current))])
       mem)]
    [(equal? op lw-opcode)
     (apply fetch
	    (lw (decoded-rs current)
		(decoded-rt current)
		(decoded-immediate current)
		registers
		mem))]
    [(equal? op sw-opcode)
     (apply fetch
	    (sw (decoded-rs current)
		(decoded-rt current)
		(decoded-immediate current)
		registers
		mem))]
    [(equal? op beq-opcode)
     (fetch
       (beq (decoded-rs current)
	    (decoded-rt current)
	    (decoded-immediate current)
	    registers)
       mem)]
    [(equal? op bne-opcode)
     (fetch
       (bne (decoded-rs current)
	    (decoded-rt current)
	    (decoded-immediate current)
	    registers)
       mem)]
    [else (raise-user-error 'CPU "given opcode ~b does not exist" (decoded-opcode current))]))

