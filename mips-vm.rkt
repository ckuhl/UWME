#lang racket

(require "constants.rkt")
(require "alu.rkt")
(require "ops.rkt")

;; TODO Style of the program
; - modularize the code more
; - documentation
; - Racket best practices(?)
; - create better error handling functionality

;; TODO Structure of the program
; 0 [X] Define necessary tools
; 0.1 [X] Constants
; 0.2 [X] Structs
; 1 [X] Set up
; 1.1 [X] Initialize "hardware"
; 1.1.0 [ ] Take command-line arguments (https://docs.racket-lang.org/reference/Command-Line_Parsing.html)
; 1.1.1 [X] Create `registers`
; 1.1.2 [X] Update intial register values
; 1.1.3 [X] Set $31 to contain exit address
; 1.1.4 [X] Set $30 to point past MEM[n] (i.e. stack pointer):q
; 1.1.5 [X] Create Memory
; 1.1.6 [ ] Update initial memory contents from binary file (https://docs.racket-lang.org/binaryio/index.html)
; 2 [X] Fetch
; 2.1 [X] $IR <- MEM[$PC]
; 2.2 [X] $PC <- PC + 4
; 3 [X] Decode
; 3.1 [X] Split word in $IR into fields
; 4. [X] Execute (recurse)
; 4.1 [X] Switch on `opcode` field
; 4.1.1 [X] [IF `opcode` = ALUop] Switch on `funct` field
; 4.1.1.1 [ ] [IF `funct` = `lw`] Handle `lw` for MMIO
; 4.1.1.2 [ ] [IF `funct` = `sw`] Handle `sw` for MMIO
; 4.2 [X] Perform operation as necessary
; 5 [ ] Wind down
; 5.1 [ ] Print out registers
; 5.2 [ ] Print output (error message / nothing)
; 5.3 [ ] Return code


;; Initialize registers
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
(define m (make-list 1000000 0))
;; Copy payload over memory at region given by offset
(define (mem-loader memory payload [offset 0])
  (cond
    [(empty? payload) memory]
    [else (mem-loader (list-set memory offset (car payload))
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
  (decode
    (hash-set
      (hash-set registers
		'IR
		(+
		  (arithmetic-shift (list-ref mem (+ 0 (hash-ref registers 'PC))) 24)
		  (arithmetic-shift (list-ref mem (+ 1 (hash-ref registers 'PC))) 16)
		  (arithmetic-shift (list-ref mem (+ 2 (hash-ref registers 'PC)))  8)
		  (arithmetic-shift (list-ref mem (+ 3 (hash-ref registers 'PC)))  0)))
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

