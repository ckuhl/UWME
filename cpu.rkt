#lang racket

; CPU: Modifies registers and memory

(provide fetch
	 decode
	 execute)

(require "output.rkt" ; writing out memory contents
	 "constants.rkt" ; magic numbers
	 "sparse-list.rkt" ; accessing MEM
	 "predicates.rkt" ; simplify contracts
	 "byte-tools.rkt") ; operating on bytes


;; fetch :: get next instruction from memory and update $PC
(define/contract
  (fetch registers mem)
  (immutable-hash? sparse-list? . -> . void?)
  (cond
    [(equal? (hash-ref registers 'PC) return-address)
     (eprint-registers registers)
     (exit 0)]
    [else
      (define next-ir (read-word-from-memory mem (hash-ref registers 'PC)))

      ; TODO add a switch to output line-by-line execution
      ; (eprint-word next-ir) ; output each word to stderr

      (decode
	(hash-set
	  (hash-set registers 'IR next-ir)
	  'PC
	  (+ (hash-ref registers 'PC) word-size))
	mem)]))

;; decode :: interpret the current instruction
(define/contract
  (decode registers mem)
  (immutable-hash? sparse-list? . -> . void?)
  (execute (make-decoded (hash-ref registers 'IR)) registers mem))

;; execute :: update registers and/or memory based on instruction
(define/contract
  (execute instr registers mem)
  (decoded? immutable-hash? sparse-list? . -> . void?)
  (apply
    fetch
    (apply
      (hash-ref opcodes (decoded-opcode instr)
		(lambda () (raise-user-error
			     'CPU
			     "given opcode ~b does not exist"
			     (decoded-opcode instr))))
      (list instr registers mem))))


;; ===========================================================================
; Operations (i.e. switching on `opcode`)

;; R-type
(define/contract
  (r-type instr registers mem)
  (decoded? immutable-hash? sparse-list? . -> . (list/c immutable-hash? sparse-list?))
  (apply (hash-ref
	   functs
	   (decoded-funct instr)
	   (lambda () (raise-user-error
			'ALU
			"given funct ~b does not exist"
			(decoded-funct instr))))
	 (list instr registers mem)))

;; lw :: $t = MEM [$s + i]
(define/contract
  (lw instr registers mem)
  (decoded? immutable-hash? sparse-list? . -> . (list/c immutable-hash? sparse-list?))
  (define addr (+ (hash-ref registers (decoded-rs instr)) (decoded-immediate instr)))
  (if (not (zero? (modulo addr word-size))) (raise-user-error 'CPU "Unaligned memory access") #t)
  (if (and
	(or (negative? addr)
	    (> addr MEMORY-SIZE))
	(not (equal? addr mmio-read-address)))
    (raise-user-error 'CPU "Out of bounds memory access at address 0x~x" addr) #t)
  (cond
    [(equal? addr mmio-read-address)
     (list (hash-set registers (decoded-rt instr) (bitwise-and (read-byte) lsb-mask) mem))]
    [else (list (hash-set registers (decoded-rt instr) (sparse-list-ref mem addr)) mem)]))

;; sw :: MEM [$s + i] = $t
(define/contract
  (sw instr registers mem)
  (decoded? immutable-hash? sparse-list? . -> . (list/c immutable-hash? sparse-list?))
  (define addr (+ (signed->unsigned (hash-ref registers (decoded-rs instr)) 32) (decoded-immediate instr)))
  (if (not (zero? (modulo addr word-size))) (raise-user-error 'CPU "Unaligned memory access") #t)
  (if (and
	(or (negative? addr)
	    (> addr MEMORY-SIZE))
	(not (equal? addr mmio-write-address)))
    (raise-user-error 'CPU "Out of bounds memory access at address 0x~x" addr) #t)
  (cond
    [(equal? addr mmio-write-address)
     (mmio-write (hash-ref registers (decoded-rt instr)))
     (list registers mem)]
    [else (list registers (sparse-list-set mem addr (decoded-rt instr)))]))

;; beq :: if ($s == $t) pc += i * 4
(define/contract
  (beq instr registers mem)
  (decoded? immutable-hash? sparse-list? . -> . (list/c immutable-hash? sparse-list?))
  (list
    (cond [(equal? (decoded-rs instr) (decoded-rt instr))
	   (hash-set registers
		     'PC
		     (+ (hash-ref registers 'PC)
			(* (decoded-immediate instr) word-size)))]
	  [else registers])
    mem))

;; bne :: if ($s != $t) pc += i * 4
(define/contract
  (bne instr registers mem)
  (decoded? immutable-hash? sparse-list? . -> . (list/c immutable-hash? sparse-list?))
  (list
    (cond [(not (equal? (decoded-rs instr) (decoded-rt instr)))
	   (hash-set registers
		     'PC
		     (+ (hash-ref registers 'PC)
			(* (decoded-immediate instr) word-size)))]
	  [else registers])
    mem))


;; funct table
(define functs
  (make-immutable-hash
    (list (cons add-funct add)
	  (cons sub-funct sub)
	  (cons mult-funct mult)
	  (cons multu-funct multu)
	  (cons div-funct div)
	  (cons divu-funct divu)
	  (cons mfhi-funct mfhi)
	  (cons mflo-funct mflo)
	  (cons lis-funct lis)
	  (cons slt-funct slt)
	  (cons sltu-funct sltu)
	  (cons jr-funct jr)
	  (cons jalr-funct jalr))))



; ============================================================================
; Functions (i.e. switching based on `funct`)

;; `decoded` field order:: opcode rs rt rd shamt funct immediate jump
(define three-operand  (struct/c decoded zero? number? number? number? zero? any/c any/c any/c))
(define two-operand    (struct/c decoded zero? number? number? zero?   zero? any/c any/c any/c))
(define one-operand-rs (struct/c decoded zero? number? zero?   zero?   zero? any/c any/c any/c))
(define one-operand-rd (struct/c decoded zero? zero?   zero?   number? zero? any/c any/c any/c))


; add :: $d = $s + $t
(define/contract
  (add instr registers mem)
  (three-operand immutable-hash? sparse-list? . -> . (list/c immutable-hash? sparse-list?))
  (list
    (hash-set registers
	      (decoded-rd instr)
	      (+ (hash-ref registers (decoded-rs instr))
		 (hash-ref registers (decoded-rt instr))))
    mem))

; sub :: $d = $s - $t
(define/contract
  (sub instr registers mem)
  (three-operand immutable-hash? sparse-list? . -> . (list/c immutable-hash? sparse-list?))
  (define s (hash-ref registers (decoded-rs instr)))
  (define t (hash-ref registers (decoded-rt instr)))
  (list
    (hash-set registers (decoded-rd instr) (- s t))
    mem))

;; mult :: $HI:$LO = $rs * $rd
(define/contract
  (mult instr registers mem)
  (two-operand immutable-hash? sparse-list? . -> . (list/c immutable-hash? sparse-list?))
  (define s (hash-ref registers (decoded-rs instr)))
  (define t (hash-ref registers (decoded-rt instr)))
  (list
    (hash-set
      (hash-set
	registers
	'HI
	(arithmetic-shift (bitwise-and (* s t) hi-result-mask) -32))
      'LO
      (bitwise-and (* s t) lo-result-mask))
    mem))

;; multu :: $HI:$LO = $rs * $rt
(define/contract
  (multu instr registers mem)
  (two-operand immutable-hash? sparse-list? . -> . (list/c immutable-hash? sparse-list?))
  (define s (signed->unsigned (hash-ref registers (decoded-rs instr)) 32))
  (define t (signed->unsigned (hash-ref registers (decoded-rt instr)) 32))
  (list
    (hash-set
      (hash-set
	registers
	'HI
	(arithmetic-shift (bitwise-and (* s t) hi-result-mask) -32))
      'LO
      (bitwise-and (* s t) lo-result-mask))
    mem))

;; div :: $LO = $s / $t, $HI = $s % $t
(define/contract
  (div instr registers mem)
  (two-operand immutable-hash? sparse-list? . -> . (list/c immutable-hash? sparse-list?))
  (define s (hash-ref registers (decoded-rs instr)))
  (define t (hash-ref registers (decoded-rt instr)))
  (if (zero? t)
    (raise-user-error "CPU error: Division by zero") #t)
  (list
    (hash-set
      (hash-set 'HI (remainder s t))
      'LO
      (quotient s t))
    mem))

;; divu :: $LO = $s / $t, $HI = $s % $t
(define/contract
  (divu instr registers mem)
  (two-operand immutable-hash? sparse-list? . -> . (list/c immutable-hash? sparse-list?))
  (define s (signed->unsigned (hash-ref registers (decoded-rs instr)) 32))
  (define t (signed->unsigned (hash-ref registers (decoded-rt instr)) 32))
  (if (zero? t) (raise-user-error "CPU error: Division by zero") #t)
  (list
    (hash-set
      (hash-set 'HI (remainder s t))
      'LO
      (quotient s t))
    mem))

;; mfhi :: $d = $HI
(define/contract
  (mfhi instr registers mem)
  (one-operand-rd immutable-hash? sparse-list? . -> . (list/c immutable-hash? sparse-list?))
  (list (hash-set registers (decoded-rd instr) (hash-ref 'HI)) mem))

;; mflo :: $d = $LO
(define/contract
  (mflo instr registers mem)
  (one-operand-rd immutable-hash? sparse-list? . -> . (list/c immutable-hash? sparse-list?))
  (list (hash-set registers (decoded-rd instr) (hash-ref 'LO)) mem))

;; lis :: d = MEM[pc]; pc += 4
(define/contract
  (lis instr registers mem)
  (one-operand-rd immutable-hash? sparse-list? . -> . (list/c immutable-hash? sparse-list?))
  (define pc (hash-ref registers 'PC))
  (define loaded
    (unsigned->signed (read-word-from-memory mem (hash-ref registers 'PC)) 32))
  (list
    (hash-set
      (hash-set registers (decoded-rd instr) loaded)
      'PC
      (+ word-size (hash-ref registers 'PC)))
    mem))

;; slt :: $d = 1 if $s < $t; 0 otherwise
(define/contract
  (slt instr registers mem)
  (three-operand immutable-hash? sparse-list? . -> . (list/c immutable-hash? sparse-list?))
  (define s (hash-ref registers (decoded-rs instr)))
  (define t (hash-ref registers (decoded-rt instr)))
  (list
    (hash-set registers
	      (decoded-rd instr)
	      (if (< s t) 1 0))
    mem))

;; sltu :: $d = 1 if $s < $t; 0 otherwise
(define/contract
  (sltu instr registers mem)
  (three-operand immutable-hash? sparse-list? . -> . (list/c immutable-hash? sparse-list?))
  (define s (signed->unsigned (hash-ref registers (decoded-rs instr)) 32))
  (define t (signed->unsigned (hash-ref registers (decoded-rt instr)) 32))
  (list
    (hash-set registers
	      (decoded-rd instr)
	      (if (< s t) 1 0))
    mem))

;; jr :: pc = $s
(define/contract
  (jr instr registers mem)
  (one-operand-rs immutable-hash? sparse-list? . -> . (list/c immutable-hash? sparse-list?))
  (list
    (hash-set registers
	      'PC
	      (hash-ref registers (decoded-rs instr)))
    mem))

;; jalr :: temp = $s; $31 = pc; $PC = temp
(define/contract
  (jalr instr registers mem)
  (one-operand-rs immutable-hash? sparse-list? . -> . (list/c immutable-hash? sparse-list?))
  (define rs (decoded-rs instr))
  (list
    (hash-set
      (hash-set registers rs (hash-ref registers 'PC))
      'PC
      (hash-ref registers rs))
    mem))


;; opcode table
(define opcodes
  (make-immutable-hash
    (list (cons r-type-opcode r-type)
	  (cons lw-opcode lw)
	  (cons sw-opcode sw)
	  (cons beq-opcode beq)
	  (cons bne-opcode bne))))

