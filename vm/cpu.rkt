#lang racket

; CPU: Modifies reg and memory

(provide fetch
	 decode
	 execute)

(require "output.rkt" ; writing out memory contents
	 "constants.rkt" ; magic numbers
	 "memory.rkt" ; memory
	 "registers.rkt" ; registers
	 "word.rkt") ; word


;; fetch :: get next instruction from memory and update $PC
(define/contract
  (fetch reg mem)
  (registers? memory? . -> . void?)
  (cond
    [(equal? (integer-bytes->integer (hash-ref reg 'PC) #f) return-address)
     (eprint-registers reg)
     (exit 0)]
    [else
      (define next-ir (word-raw (bytes->word (hash-ref reg 'PC))))

      ; TODO add a switch to output line-by-line execution
      ; (eprint-word next-ir) ; output each word to stderr

      (decode
	(hash-set
	  (hash-set reg 'IR (memory-ref mem next-ir))
	  'PC
	  (integer->integer-bytes (+ (integer-bytes->integer (hash-ref reg 'PC) #f word-size)) 4 #f))
	mem)]))

;; decode :: interpret the current instruction
(define/contract
  (decode reg mem)
  (registers? memory? . -> . void?)
  (printf "~a~n" (bytes->word (hash-ref reg 'IR)))
  (execute (bytes->word (hash-ref reg 'IR)) reg mem))

;; execute :: update reg and/or memory based on instruction
(define/contract
  (execute w reg mem)
  (word? registers? memory? . -> . void?)
  (apply
    fetch
    (apply
      (hash-ref opcodes (word-op w)
		(lambda () (raise-user-error
			     'CPU
			     "given opcode ~b does not exist"
			     (word-op w))))
      (list w reg mem))))


;; ===========================================================================
; Operations (i.e. switching on `opcode`)

;; R-type
(define/contract
  (r-type w reg mem)
  (word? registers? memory? . -> . (list/c registers? memory?))
  (apply (hash-ref
	   functs
	   (word-fn w)
	   (lambda () (raise-user-error
			'ALU
			"given funct ~a does not exist"
			(format-funct (word-fn w)))))
	 (list w reg mem)))

;; lw :: $t = MEM [$s + i]
(define/contract
  (lw w reg mem)
  (word? registers? memory? . -> . (list/c registers? memory?))
  (define addr (+ (integer-bytes->integer (hash-ref reg (word-rs w)) #t) (word-i w)))

  (cond
    [(equal? addr mmio-read-address)
     (list (hash-set reg (word-rt w) (bitwise-and (read-byte (current-input-port)) lsb-mask) mem))]
    [(and (not (negative? addr)) (< addr MEMORY-SIZE))
     (list (hash-set reg (word-rt w) (memory-ref mem addr)) mem)]
    [else
    (raise-user-error 'CPU "Out of bounds memory access at address ~X" addr)]))

;; sw :: MEM [$s + i] = $t
(define/contract
  (sw w reg mem)
  (word? registers? memory? . -> . (list/c registers? memory?))
  (define addr (+ (integer-bytes->integer (hash-ref reg (word-rs w)) #t) (word-i w)))
  (if (not (zero? (modulo addr word-size))) (raise-user-error 'CPU "Unaligned memory access") #t)
  (if (and (or (negative? addr) (> addr MEMORY-SIZE))
	   (not (equal? addr mmio-write-address)))
    (raise-user-error 'CPU "Out of bounds memory access at address 0x~x" addr) #t)
  (cond
    [(equal? addr mmio-write-address)
     (mmio-write (hash-ref reg (word-rt w)))
     (list reg mem)]
    [else (list reg (memory-set mem addr (word-rt w)))]))

;; beq :: if ($s == $t) pc += i * 4
(define/contract
  (beq instr reg mem)
  (word? registers? memory? . -> . (list/c registers? memory?))
  (list
    (cond [(equal? (word-rs instr) (word-rt instr))
	   (hash-set reg
		     'PC
		     (+ (hash-ref reg 'PC)
			(* (word-i instr) word-size)))]
	  [else reg])
    mem))

;; bne :: if ($s != $t) pc += i * 4
(define/contract
  (bne instr reg mem)
  (word? registers? memory? . -> . (list/c registers? memory?))
  (list
    (cond [(not (equal? (word-rs instr) (word-rt instr)))
	   (hash-set reg
		     'PC
		     (integer->integer-bytes
		       (+ (integer-bytes->integer (hash-ref reg 'PC) #f)
			  (* (word-i instr) word-size))
		     4 #f))]
	  [else reg])
    mem))


;; opcode table
(define opcodes
  (make-immutable-hash
    (list (cons r-type-opcode r-type)
	  (cons lw-opcode lw)
	  (cons sw-opcode sw)
	  (cons beq-opcode beq)
	  (cons bne-opcode bne))))



; ============================================================================
; Functions (i.e. switching based on `funct`)

;; `word` field order:: opcode rs rt rd shamt funct immediate jump
; todo
(define three-operand word?)
(define two-operand word?)
(define one-operand-rs word?)
(define one-operand-rd word?)


; add :: $d = $s + $t
(define/contract
  (add instr reg mem)
  (three-operand registers? memory? . -> . (list/c registers? memory?))
  (list
    (hash-set reg
	      (word-rd instr)
	      (+ (hash-ref reg (word-rs instr))
		 (hash-ref reg (word-rt instr))))
    mem))

; sub :: $d = $s - $t
(define/contract
  (sub instr reg mem)
  (three-operand registers? memory? . -> . (list/c registers? memory?))
  (define s (hash-ref reg (word-rs instr)))
  (define t (hash-ref reg (word-rt instr)))
  (list
    (hash-set reg (word-rd instr) (- s t))
    mem))

;; mult :: $HI:$LO = $rs * $rd
(define/contract
  (mult instr reg mem)
  (two-operand registers? memory? . -> . (list/c registers? memory?))
  (define s (hash-ref reg (word-rs instr)))
  (define t (hash-ref reg (word-rt instr)))
  (list
    (hash-set
      (hash-set
	reg
	'HI
	(arithmetic-shift (bitwise-and (* s t) hi-result-mask) -32))
      'LO
      (bitwise-and (* s t) lo-result-mask))
    mem))

;; multu :: $HI:$LO = $rs * $rt
(define/contract
  (multu instr reg mem)
  (two-operand registers? memory? . -> . (list/c registers? memory?))
  (define s (integer-bytes->integer (hash-ref reg (word-rs instr)) #t))
  (define t (integer-bytes->integer (hash-ref reg (word-rt instr)) #t))
  (list
    (hash-set
      (hash-set
	reg
	'HI
	(arithmetic-shift (bitwise-and (* s t) hi-result-mask) -32))
      'LO
      (bitwise-and (* s t) lo-result-mask))
    mem))

;; div :: $LO = $s / $t, $HI = $s % $t
(define/contract
  (div instr reg mem)
  (two-operand registers? memory? . -> . (list/c registers? memory?))
  (define s (hash-ref reg (word-rs instr)))
  (define t (hash-ref reg (word-rt instr)))
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
  (divu instr reg mem)
  (two-operand registers? memory? . -> . (list/c registers? memory?))
  (define s (integer-bytes->integer (hash-ref reg (word-rs instr)) #t))
  (define t (integer-bytes->integer (hash-ref reg (word-rt instr)) #t))
  (if (zero? t) (raise-user-error "CPU error: Division by zero") #t)
  (list
    (hash-set
      (hash-set reg 'HI (remainder s t))
      'LO
      (quotient s t))
    mem))

;; mfhi :: $d = $HI
(define/contract
  (mfhi instr reg mem)
  (one-operand-rd registers? memory? . -> . (list/c registers? memory?))
  (list (hash-set reg (word-rd instr) (hash-ref 'HI)) mem))

;; mflo :: $d = $LO
(define/contract
  (mflo instr reg mem)
  (one-operand-rd registers? memory? . -> . (list/c registers? memory?))
  (list (hash-set reg (word-rd instr) (hash-ref 'LO)) mem))

;; lis :: d = MEM[pc]; pc += 4
(define/contract
  (lis instr reg mem)
  (one-operand-rd registers? memory? . -> . (list/c registers? memory?))
  (define pc (hash-ref reg 'PC))
  (define loaded
    (integer-bytes->integer (memory-ref (hash-ref reg 'PC)) #t))
  (list
    (hash-set
      (hash-set reg (word-rd instr) loaded)
      'PC
      (+ word-size (hash-ref reg 'PC)))
    mem))

;; slt :: $d = 1 if $s < $t; 0 otherwise
(define/contract
  (slt instr reg mem)
  (three-operand registers? memory? . -> . (list/c registers? memory?))
  (define s (hash-ref reg (word-rs instr)))
  (define t (hash-ref reg (word-rt instr)))
  (list
    (hash-set reg
	      (word-rd instr)
	      (if (< s t) 1 0))
    mem))

;; sltu :: $d = 1 if $s < $t; 0 otherwise
(define/contract
  (sltu instr reg mem)
  (three-operand registers? memory? . -> . (list/c registers? memory?))
  (define s (integer-bytes->integer (hash-ref reg (word-rs instr)) #t))
  (define t (integer-bytes->integer (hash-ref reg (word-rt instr)) #t))
  (list
    (hash-set reg
	      (word-rd instr)
	      (if (< s t) 1 0))
    mem))

;; jr :: pc = $s
(define/contract
  (jr instr reg mem)
  (one-operand-rs registers? memory? . -> . (list/c registers? memory?))
  (list
    (hash-set reg
	      'PC
	      (hash-ref reg (word-rs instr)))
    mem))

;; jalr :: temp = $s; $31 = pc; $PC = temp
(define/contract
  (jalr instr reg mem)
  (one-operand-rs registers? memory? . -> . (list/c registers? memory?))
  (define rs (word-rs instr))
  (list
    (hash-set
      (hash-set reg rs (hash-ref reg 'PC))
      'PC
      (hash-ref reg rs))
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

