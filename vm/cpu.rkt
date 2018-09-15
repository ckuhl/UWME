#lang racket

; CPU: Modifies rf and memory

(provide run-cpu)

(require "constants.rkt" ; magic numbers
	 "memory.rkt" ; memory
	 "registerfile.rkt" ; registers
	 "word.rkt") ; word

;; wrapper function to run everything
(define/contract
  (run-cpu rf mem)
  (registerfile? memory? . -> . void?)
  (fetch rf mem))


;; fetch :: get next instruction from memory and update $PC
(define/contract
  (fetch rf mem)
  (registerfile? memory? . -> . void?)
  (define pc-contents (registerfile-ref rf 'PC #f))
  (cond
    [(equal? pc-contents return-address)
     (printf "~a~n" rf)
     (exit 0)]
    [else

      ; TODO add a switch to output line-by-line execution?

      (decode
	(registerfile-set*
	  rf
	  'IR (memory-ref mem pc-contents)
	  'PC (memory-ref mem (+ pc-contents 4)))
	mem)]))

;; decode :: interpret the current instruction
(define/contract
  (decode rf mem)
  (registerfile? memory? . -> . void?)
  ; just printing out what we have right now
  (printf "~a~n" (bytes->word (registerfile-ref rf 'IR)))

  (execute (bytes->word (registerfile-ref rf 'IR)) rf mem))


;; execute :: update rf and/or memory based on instruction
(define/contract
  (execute w rf mem)
  (word? registerfile? memory? . -> . void?)
  (apply
    fetch
    (apply
      (hash-ref opcodes (word-op w)
		(lambda () (raise-user-error
			     'CPU
			     "given opcode ~b does not exist"
			     (word-op w))))
      (list w rf mem))))


;; helpers
(define/contract (compute-offset-addr word)
(word? . -> . exact-integer?)
  (+ (registerfile-integer-ref rf (word-rs w) #f))
     (word-i w))


;; ===========================================================================
; Operations (i.e. switching on `opcode`)

;; R-type
(define/contract
  (r-type w rf mem)
  (word? registerfile? memory? . -> . (list/c registerfile? memory?))
  (apply (hash-ref
	   functs
	   (word-fn w)
	   (lambda () (raise-user-error
			'ALU
			"given funct ~a does not exist"
			(format-funct (word-fn w)))))
	 (list w rf mem)))

;; lw :: $t = MEM [$s + i]
(define/contract
  (lw w rf mem)
  (word? registerfile? memory? . -> . (list/c registerfile? memory?))
  (define addr (compute-offset-addr w))
  (cond
    ; reading from MMIO
    [(equal? addr mmio-read-address)
     (list (registerfile-set rf (word-rt w) (bitwise-and (read-byte) lsb-mask)) mem)]
    ; reading from memory
     [else
       (list (registerfile-set rf (word-rt w) (memory-ref mem addr)) mem)]))

;; sw :: MEM [$s + i] = $t
(define/contract
  (sw w rf mem)
  (word? registerfile? memory? . -> . (list/c registerfile? memory?))
  (define addr (compute-offset-addr w))
  (cond
    ; writing to MMIO
    [(equal? addr mmio-write-address)
     (begin (write-byte (registerfile-ref rf (word-rt w))) (list rf mem))]
    ; write to memory from register
    [else
      (list rf (memory-set mem addr (registerfile-ref rf (word-rt w))))]))

;; beq :: if ($s == $t) pc += i * 4
(define/contract
  (beq w rf mem)
  (word? registerfile? memory? . -> . (list/c registerfile? memory?))
  (list
    (cond
      [(equal? (word-rs w) (word-rt w))
       (registerfile-integer-set
	 rf
	 'PC (+ (registerfile-integer-ref rf 'PC #f) (* (word-i w) word-size)))]
      [else reg])
    mem))

;; bne :: if ($s != $t) pc += i * 4
(define/contract
  (bne w rf mem)
  (word? registerfile? memory? . -> . (list/c registerfile? memory?))
  (list
    (cond
      [(not (equal? (word-rs instr) (word-rt instr)))
       (registerfile-integer-set
	 rf
	 'PC
	 (+ (registerfile-integer-ref rf 'PC #f)
	    (* (word-i instr) word-size)))]
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
  (add w rf mem)
  (three-operand registerfile? memory? . -> . (list/c registerfile? memory?))
  (list
    (registerfile-integer-set
      reg
      (word-rd w)
      (+ (registerfile-integer-ref rf (word-rs w))
	 (registerfile-integer-ref rf (word-rt w))))
    mem))

; sub :: $d = $s - $t
(define/contract
  (sub w rf mem)
  (three-operand registerfile? memory? . -> . (list/c registerfile? memory?))
  (define s (registerfile-integer-ref rf (word-rs w)))
  (define t (registerfile-integer-ref rf (word-rt w)))
  (list
    (registerfile-integer-set rf (word-rd w) (- s t))
    mem))

;; mult :: $HI:$LO = $rs * $rd
(define/contract
  (mult w rf mem)
  (two-operand registerfile? memory? . -> . (list/c registerfile? memory?))
  (define s (registerfile-integer-ref rf (word-rs w) #t))
  (define t (registerfile-integer-ref rf (word-rt w) #t))
  (list
  (registerfile-integer-set*
    rf
    'HI (arithmetic-shift (bitwise-and (* s t) hi-result-mask) (- (* word-width 8)))
     #t ; todo handle weird position for `signed` parameter
    'LO (bitwise-and (* s t) lo-result-mask))
    mem))

;; multu :: $HI:$LO = $rs * $rt
(define/contract
  (multu w rf mem)
  (two-operand registerfile? memory? . -> . (list/c registerfile? memory?))
  (define s (registerfile-integer-ref rf (word-rs w) #f))
  (define t (registerfile-integer-ref rf (word-rt w) #f))
  (list
    (registerfile-integer-set*
      rf
      'HI (arithmetic-shift (bitwise-and (* s t) hi-result-mask) (- (* word-width 8)))
      #f ; todo handle weird position for `signed` parameter
      'LO (bitwise-and (* s t) lo-result-mask))
    mem))

;; div :: $LO = $s / $t, $HI = $s % $t
(define/contract
  (div w rf mem)
  (two-operand registerfile? memory? . -> . (list/c registerfile? memory?))
  (define s (registerfile-integer-ref rf (word-rs w)) #t)
  (define t (registerfile-integer-ref rf (word-rt w)) #t)
  (when (zero? t) (raise-user-error "CPU error: Division by zero"))
  (list
    (register-integer-set
      rf
      'HI (remainder s t)
      #t
      'LO (quotient s t))
    mem))

;; divu :: $LO = $s / $t, $HI = $s % $t
(define/contract
  (divu w rf mem)
  (two-operand registerfile? memory? . -> . (list/c registerfile? memory?))
  (define s (registerfile-integer-ref rf (word-rs w)) #f)
  (define t (registerfile-integer-ref rf (word-rt w)) #f)
  (when (zero? t) (raise-user-error "CPU error: Division by zero"))
  (list
    (registerfile-integer-set
      rf
      'HI (remainder s t)
      #f
      'LO (quotient s t))
    mem))

;; mfhi :: $d = $HI
(define/contract
  (mfhi w rf mem)
  (one-operand-rd registerfile? memory? . -> . (list/c registerfile? memory?))
  (list (registerfile-set rf (word-rd instr) (registerfile-ref rf 'HI)) mem))

;; mflo :: $d = $LO
(define/contract
  (mflo w rf mem)
  (one-operand-rd registerfile? memory? . -> . (list/c registerfile? memory?))
  (list (registerfile-set rf (word-rd instr) (registerfile-ref rf 'LO)) mem))

;; lis :: d = MEM[pc]; pc += 4
(define/contract
  (lis w rf mem)
  (one-operand-rd registerfile? memory? . -> . (list/c registerfile? memory?))
  (list
    (registerfile-set
      rf
      (word-rd w) (registerfile-ref rf 'PC)
      #f
      'PC (integer->integer-bytes (+ word-size
				     (registerfile-integer-ref rf 'PC #f))
				  word-size
				  #f))
    mem))

;; slt :: $d = 1 if $s < $t; 0 otherwise
(define/contract
  (slt w rf mem)
  (three-operand registerfile? memory? . -> . (list/c registerfile? memory?))
  (define s (registerfile-integer-ref rf (word-rs w) #t))
  (define t (registerfile-integer-ref rf (word-rt w) #t))
  (list
    (registerfile-integer-set (word-rd instr) (if (< s t) 1 0) #f)
    mem))

;; sltu :: $d = 1 if $s < $t; 0 otherwise
(define/contract
  (sltu w rf mem)
  (three-operand registerfile? memory? . -> . (list/c registerfile? memory?))
  (define s (registerfile-integer-ref rf (word-rs w) #f))
  (define t (registerfile-integer-ref rf (word-rt w) #f))
  (list
    (registerfile-integer-set rf (word-rd instr) (if (< s t) 1 0) #f)
    mem))

;; jr :: pc = $s
(define/contract
  (jr w rf mem)
  (one-operand-rs registerfile? memory? . -> . (list/c registerfile? memory?))
  (list
    (registerfile-set rf 'PC (registerfile-integer-ref rf (word-rs instr) #f))
    mem))

;; jalr :: temp = $s; $31 = pc; $PC = temp
(define/contract
  (jalr w rf mem)
  (one-operand-rs registerfile? memory? . -> . (list/c registerfile? memory?))
  (define rs (word-rs instr))
  (list
    (registerfile-set*
      rf
      rs (registerfile-ref rf 'PC)
      'PC (registerfile-ref rf rs))
    mem))


;; funct table
(define functs
  (make-immutable-hash
    (list (cons add-funct  add)
	  (cons sub-funct   sub)
	  (cons mult-funct  mult)
	  (cons multu-funct multu)
	  (cons div-funct   div)
	  (cons divu-funct  divu)
	  (cons mfhi-funct  mfhi)
	  (cons mflo-funct  mflo)
	  (cons lis-funct   lis)
	  (cons slt-funct   slt)
	  (cons sltu-funct  sltu)
	  (cons jr-funct    jr)
	  (cons jalr-funct  jalr))))

