#lang racket/base

; CPU: Modifies register and memory

(provide run-cpu ; run the processor

	 ;; global variables
	 show-binary
	 show-more
	 start-time
	 show-verbose

	 ;; export for testing
	 (prefix-out cpu: add)
	(prefix-out cpu: sub)
	(prefix-out cpu: mult)
	(prefix-out cpu: multu)
	(prefix-out cpu: div)
	(prefix-out cpu: divu)
	(prefix-out cpu: mfhi)
	(prefix-out cpu: mflo)
	(prefix-out cpu: lis)
	(prefix-out cpu: lw)
	(prefix-out cpu: sw)
	(prefix-out cpu: slt)
	(prefix-out cpu: sltu)
	(prefix-out cpu: beq)
	(prefix-out cpu: bne)
	(prefix-out cpu: jr)
	(prefix-out cpu: jalr))

(require racket/contract
	 racket/format ; ~r
	 racket/math ; exact-round

	 "constants.rkt" ; magic numbers
	 "memory.rkt" ; memory
	 "registerfile.rkt" ; registers
	 "word.rkt") ; word

; global configuration
(define show-binary (make-parameter #f))
(define show-more (make-parameter #f))
(define show-verbose (make-parameter #f))

(define start-time (make-parameter (current-inexact-milliseconds)))
(define cycle-timer (make-parameter (current-inexact-milliseconds)))
(define cycle-count (make-parameter 0))

;; wrapper function to run everything
(define/contract
  (run-cpu rf mem)
  (registerfile? memory? . -> . void?)
  (fetch rf mem))

;; fetch :: get next instruction from memory and update $PC
(define/contract
  (fetch rf mem)
  (registerfile? memory? . -> . void?)

  ;; TODO remove? global state for loop timer =================================
  (when (show-verbose)
    (printf "Cycle #~a, time: ~ams~n"
	    (cycle-count)
	    (/ (round (* 1000
			 (- (current-inexact-milliseconds)
			    (cycle-timer))))
	       1000)))
  (cycle-timer (current-inexact-milliseconds))
  (cycle-count (add1 (cycle-count)))
  ;; ==========================================================================

  (define pc-value (registerfile-integer-ref rf 'PC #f))
  (cond
    [(equal? pc-value return-address)
     (begin
       (eprintf "MIPS program completed normally.~n")
       (when (show-more)
	 (eprintf "~a cycles in ~as, VM freq. ~akHz~n"
		  (cycle-count)
		  (/ (round (- (current-inexact-milliseconds) (start-time))) 1000)
		  (/ (cycle-count) (- (current-inexact-milliseconds) (start-time)))))) ; Hz / ms == kHz / s
     (eprintf "~a~n" (format-registerfile rf))
     (exit 0)] ; quit gracefully
    [else
      (begin
	(when (show-binary)
	  (printf "~a: ~a~n"
		  (format-word-hex (bytes->word (registerfile-ref rf 'PC)))
		  (format-word-binary (bytes->word (memory-ref mem pc-value)))))

	(decode
	  (registerfile-set-swap
	    rf
	    'IR (memory-ref mem pc-value)
	    'PC (integer->integer-bytes (+ pc-value 4) word-size #f #t))
	  mem))]))

;; decode :: interpret the current instruction
(define/contract (decode rf mem)
		 (registerfile? memory? . -> . void?)
		 (execute (bytes->word (registerfile-ref rf 'IR)) rf mem))


;; execute :: update rf and/or memory based on instruction
(define/contract
  (execute w rf mem)
  (word? registerfile? memory? . -> . void?)
  (apply
    fetch
    (apply
      (hash-ref opcodes
		(word-op w)
		(lambda () (raise-user-error
			     'CPU
			     "given opcode ~b does not exist"
			     (~r (word-op w) #:sign #f #:base 2 #:min-width 6 #:pad-string "0"))))
      (list w rf mem))))


;; helpers
(define/contract (compute-offset-addr rf w)
		 (registerfile? word? . -> . exact-integer?)
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
			(~r (word-fn w) #:sign #f #:base 2 #:min-width 6 #:pad-string "0"))))
	 (list w rf mem)))

;; lw :: $t = MEM [$s + i]
(define/contract
  (lw w rf mem)
  (word? registerfile? memory? . -> . (list/c registerfile? memory?))
  (define addr (compute-offset-addr rf w))
  (cond
    ; reading from MMIO
    [(equal? addr mmio-read-address)
     (list (registerfile-set rf (word-rt w) (bitwise-and (read-byte (current-input-port)) lsb-mask)) mem)]
    ; reading from memory
    [else
      (list (registerfile-set rf (word-rt w) (memory-ref mem addr)) mem)]))

;; sw :: MEM [$s + i] = $t
(define/contract
  (sw w rf mem)
  (word? registerfile? memory? . -> . (list/c registerfile? memory?))
  (define addr (compute-offset-addr rf w))
  (cond
    ; writing to MMIO
    [(equal? addr mmio-write-address)
     (begin (write-byte (registerfile-ref rf (word-rt w) (current-output-port)))
	    (list rf mem))]
    ; write to memory from register
    [else
      (list rf (memory-set mem addr (registerfile-ref rf (word-rt w))))]))

;; beq :: if ($s == $t) pc += i * 4
(define/contract
  (beq w rf mem)
  (word? registerfile? memory? . -> . (list/c registerfile? memory?))
  (list
    (cond
      [(equal? (registerfile-ref rf (word-rs w))
	       (registerfile-ref rf (word-rt w)))
       (registerfile-integer-set
	 rf
	 'PC
	 (+ (registerfile-integer-ref rf 'PC #f) (* (word-i w) word-size))
	 #f)]
      [else rf])
    mem))

;; bne :: if ($s != $t) pc += i * 4
(define/contract
  (bne w rf mem)
  (word? registerfile? memory? . -> . (list/c registerfile? memory?))
  (list
    (cond
      [(not (equal? (registerfile-ref rf (word-rs w))
		    (registerfile-ref rf (word-rt w))))
       (registerfile-integer-set
	 rf
	 'PC (+ (registerfile-integer-ref rf 'PC #f)
		(* (word-i w) word-size))
	 #f)]
      [else rf])
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
; TODO define better contracts for operands?
;  i.e. enforce empty fields (e.g. shamt)
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
      rf
      (word-rd w)
      (+ (registerfile-integer-ref rf (word-rs w) #t)
	 (registerfile-integer-ref rf (word-rt w) #t))
      #t)
    mem))

; sub :: $d = $s - $t
(define/contract
  (sub w rf mem)
  (three-operand registerfile? memory? . -> . (list/c registerfile? memory?))
  (list
    (registerfile-integer-set
      rf
      (word-rd w)
      (- (registerfile-integer-ref rf (word-rs w) #t)
	 (registerfile-integer-ref rf (word-rt w) #t))
      #t)
    mem))

;; mult :: $HI:$LO = $rs * $rd
(define/contract
  (mult w rf mem)
  (two-operand registerfile? memory? . -> . (list/c registerfile? memory?))
  (define s (registerfile-integer-ref rf (word-rs w) #t))
  (define t (registerfile-integer-ref rf (word-rt w) #t))
  (list
    (registerfile-integer-set-swap
      rf
      #t
      'HI
      (arithmetic-shift (bitwise-and (* s t) hi-result-mask) ; mask off LO
			(- (* word-size 8))) ; Shift to fit word
      'LO
      (bitwise-and (* s t) lo-result-mask))
    mem))

;; multu :: $HI:$LO = $rs * $rt
(define/contract
  (multu w rf mem)
  (two-operand registerfile? memory? . -> . (list/c registerfile? memory?))
  (define s (registerfile-integer-ref rf (word-rs w) #f))
  (define t (registerfile-integer-ref rf (word-rt w) #f))
  (list
    (registerfile-integer-set-swap
      rf
      #t
      'HI (arithmetic-shift (bitwise-and (* s t) hi-result-mask) (- (* word-size 8)))
      'LO (bitwise-and (* s t) lo-result-mask))
    mem))

;; div :: $LO = $s / $t, $HI = $s % $t
(define/contract
  (div w rf mem)
  (two-operand registerfile? memory? . -> . (list/c registerfile? memory?))
  (define s (registerfile-integer-ref rf (word-rs w) #t))
  (define t (registerfile-integer-ref rf (word-rt w) #t))
  (when (zero? t) (raise-user-error "CPU error: Division by zero"))
  (list
    (registerfile-integer-set-swap
      rf
      #f
      'HI (remainder s t)
      'LO (quotient s t))
    mem))

;; divu :: $LO = $s / $t, $HI = $s % $t
(define/contract
  (divu w rf mem)
  (two-operand registerfile? memory? . -> . (list/c registerfile? memory?))
  (define s (registerfile-integer-ref rf (word-rs w) #f))
  (define t (registerfile-integer-ref rf (word-rt w) #f))
  (when (zero? t) (raise-user-error "CPU error: Division by zero"))
  (list
    (registerfile-integer-set
      rf #f
      'HI (remainder s t)
      'LO (quotient s t))
    mem))

;; mfhi :: $d = $HI
(define/contract
  (mfhi w rf mem)
  (one-operand-rd registerfile? memory? . -> . (list/c registerfile? memory?))
  (list (registerfile-set rf (word-rd w) (registerfile-ref rf 'HI)) mem))

;; mflo :: $d = $LO
(define/contract
  (mflo w rf mem)
  (one-operand-rd registerfile? memory? . -> . (list/c registerfile? memory?))
  (list (registerfile-set rf (word-rd w) (registerfile-ref rf 'LO)) mem))

;; lis :: d = MEM[pc]; pc += 4
(define/contract
  (lis w rf mem)
  (one-operand-rd registerfile? memory? . -> . (list/c registerfile? memory?))
  (define new-rf
    (registerfile-set-swap
      rf
      (word-rd w) (memory-ref
		    mem
		    (integer-bytes->integer (registerfile-ref rf 'PC) #f #t))
      'PC (integer->integer-bytes
	    (+ word-size
	       (registerfile-integer-ref rf 'PC #f))
	    word-size
	    #f
	    #t)))

  (when (show-binary)
    (printf "~a: ~a~n"
	    (format-word-hex (bytes->word (registerfile-ref new-rf 'PC)))
	    (format-word-binary (bytes->word (registerfile-ref new-rf (word-rd w))))))

  (list new-rf mem))

;; slt :: $d = 1 if $s < $t; 0 otherwise
(define/contract
  (slt w rf mem)
  (three-operand registerfile? memory? . -> . (list/c registerfile? memory?))
  (define s (registerfile-integer-ref rf (word-rs w) #t))
  (define t (registerfile-integer-ref rf (word-rt w) #t))
  (list
    (registerfile-integer-set (word-rd w) (if (< s t) 1 0) #f)
    mem))

;; sltu :: $d = 1 if $s < $t; 0 otherwise
(define/contract
  (sltu w rf mem)
  (three-operand registerfile? memory? . -> . (list/c registerfile? memory?))
  (define s (registerfile-integer-ref rf (word-rs w) #f))
  (define t (registerfile-integer-ref rf (word-rt w) #f))
  (list
    (registerfile-integer-set rf (word-rd w) (if (< s t) 1 0) #f)
    mem))

;; jr :: pc = $s
(define/contract
  (jr w rf mem)
  (one-operand-rs registerfile? memory? . -> . (list/c registerfile? memory?))
  (list
    (registerfile-set rf 'PC (registerfile-ref rf (word-rs w)))
    mem))

;; jalr :: temp = $s; $31 = pc; $PC = temp
(define/contract
  (jalr w rf mem)
  (one-operand-rs registerfile? memory? . -> . (list/c registerfile? memory?))
  (list
    (registerfile-set-swap
      rf
      (word-rs w) (registerfile-ref rf 'PC)
      'PC (registerfile-ref rf (word-rs w)))
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

