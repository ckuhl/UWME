#lang racket

(require racket/format) ; Output while running

(require "constants.rkt") ; numeric constants, bit masks, etc.
(require "alu.rkt") ; ALU operations for R-type instructions
(require "ops.rkt") ; CPU operations
(require "sparse-list.rkt") ; Custom list data structure (access list as array)


(define MEMORY-SIZE #x01000000)
(define MEMORY-LOAD-OFFSET #x00000000)

; Initialize registers
(define registers
  (make-immutable-hash (append (for/list ([i (range 0 30)]) (cons i 0))
			       (list
				 (cons 30 stack-pointer)
				 (cons 31 return-address)
				 (cons 'HI 0)
				 (cons 'LO 0)
				 (cons 'PC 0) ; TODO Change initial $PC by CLI args
				 (cons 'IR 0)
				 (cons 'MAR 0)
				 (cons 'MDR 0)))))

;; Initialize memory
(define m (make-sparse-list MEMORY-SIZE MEMORY-LOAD-OFFSET))

;; Copy payload over memory at region given by offset
(define (mem-loader memory payload [offset 0])
  (cond
    [(empty? payload) memory]
    [else (mem-loader (sparse-list-set memory offset (car payload))
		      (cdr payload)
		      (+ 1 offset))]))

(struct decoded (opcode rs rt rd shamt funct immediate address)
  #:transparent)

(define (decode-word value)
  (decoded
    (arithmetic-shift (bitwise-and opcode-mask value) opcode-offset)
    (arithmetic-shift (bitwise-and rs-mask value) rs-offset)
    (arithmetic-shift (bitwise-and rt-mask value) rt-offset)
    (arithmetic-shift (bitwise-and rd-mask value) rd-offset)
    (arithmetic-shift (bitwise-and shamt-mask value) shamt-offset)
    (arithmetic-shift (bitwise-and funct-mask value) funct-offset)
    (arithmetic-shift (bitwise-and immediate-mask value) immediate-offset)
    (arithmetic-shift (bitwise-and address-mask value) address-offset)
    ))

; fetch
(define (fetch registers mem)
  (if (equal? (hash-ref registers 'PC) return-address) (exit 0) #t)

  (define next-ir
    (+
      (arithmetic-shift (sparse-list-ref mem (+ 0 (hash-ref registers 'PC))) 24)
      (arithmetic-shift (sparse-list-ref mem (+ 1 (hash-ref registers 'PC))) 16)
      (arithmetic-shift (sparse-list-ref mem (+ 2 (hash-ref registers 'PC)))  8)
      (arithmetic-shift (sparse-list-ref mem (+ 3 (hash-ref registers 'PC)))  0)))

  (printf "~a ~n" (~r next-ir #:base 2 #:min-width 32 #:pad-string "0")) ; Output while running

  (decode
    (hash-set
      (hash-set registers
		'IR
		next-ir)
      'PC
      (+ (hash-ref registers 'PC) word-size))
    mem))

; decode output = execute input
(define (decode registers mem)
  (execute
    (decode-word (hash-ref registers 'IR))
    registers
    mem))

; execute output = fetch input
(define (execute current registers mem)
  (define op (decoded-opcode current))
  (define fu (decoded-funct current))
  (cond
    [(equal? op r-type-opcode) ; ALU
     (if (not (equal? (decoded-shamt current) 0)) (raise-user-error 'CPU "`shamt` must be #b00000 for R-type operations") #t)
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
     (fetch
       (lw (decoded-rs current)
	   (decoded-rt current)
	   (decoded-immediate current)
	   registers
	   mem))]
    [(equal? op sw-opcode)
     (fetch (sw (decoded-rs current)
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

(define example (list
		  #x00 #x22 #x20 #x2a
		  #x10 #x04 #x00 #x02
		  #x00 #x01 #x18 #x20
		  #x03 #xe0 #x00 #x08
		  #x00 #x02 #x18 #x20
		  #x03 #xe0 #x00 #x08
		  ))

(fetch registers (mem-loader m example))

