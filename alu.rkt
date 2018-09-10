#lang racket

(provide add sub mult multu div divu mfhi mflo lis slt sltu jr jalr unsigned->signed signed->unsigned)

(require racket/format ; output
	 "constants.rkt" ; magic numbers
	 "predicates.rkt" ; contract simplification
	 "sparse-list.rkt") ; for operating on MEM

(define one-reg-contract ((unsigned-number-size-n? 5) immutable-hash? . -> . immutable-hash?))
(define two-reg-contract ((unsigned-number-size-n? 5) (unsigned-number-size-n? 5) immutable-hash? . -> . immutable-hash?))
(define three-reg-contract ((unsigned-number-size-n? 5) (unsigned-number-size-n? 5) (unsigned-number-size-n? 5) immutable-hash? . -> . immutable-hash?))

;; Concert a decimal number representing an unsigned binary value to the
;equivalent value if the binary was signed
(define/contract
  (unsigned->signed number size)
  (->i ([x (y) (unsigned-number-size-n? y)]
	[y exact-positive-integer?])
       [result integer?])
  (cond
    [(>= number (expt 2 (sub1 size)))
     (- number (arithmetic-shift 1 size))]
    [else number]))

(define/contract
  (signed->unsigned number size)
  (->i ([x (y) (signed-number-size-n? y)]
	[y exact-positive-integer?])
       [result integer?])
  (cond
    [negative?
      (+ number (arithmetic-shift 1 size))]
    [else number]))

; add :: $d = $s + $t
(define/contract
  (add rs rt rd registers)
  three-reg-contract
  (hash-set registers
	    rd
	    (+ (hash-ref registers rs)
	       (hash-ref registers rt))))

; sub :: $d = $s - $t
(define/contract
  (sub rs rt rd registers)
  three-reg-contract
  (hash-set registers
	    rd
	    (- (hash-ref rs)
	       (hash-ref rt))))

;; mult :: $HI:$LO = $rs * $rd
(define/contract
  (mult rs rt registers)
  two-reg-contract
  (define s (hash-ref registers rs))
  (define t (hash-ref registers rt))
  (hash-set
    (hash-set
      registers
      'HI
      (arithmetic-shift (bitwise-and (* s t) hi-result-mask) -32))
    'LO
    (bitwise-and (* s t) lo-result-mask)))

;; multu :: $HI:$LO = $rs * $rt
(define/contract
  (multu rs rt registers)
  two-reg-contract
  (define s (signed->unsigned (hash-ref registers rs) 32))
  (define t (signed->unsigned (hash-ref registers rt) 32))
  (hash-set
    (hash-set
      registers
      'HI
      (arithmetic-shift (bitwise-and (* s t) hi-result-mask) -32))
    'LO
    (bitwise-and (* s t) lo-result-mask)))

;; div :: $LO = $s / $t, $HI = $s % $t
(define/contract
  (div rs rt registers)
  two-reg-contract
  (if (= rt 0) (raise-user-error "CPU error: Division by zero") #t)
  (hash-set
    (hash-set 'HI (remainder rs rt))
    'LO
    (quotient rs rt)))

;; divu :: $LO = $s / $t, $HI = $s % $t
(define/contract
  (divu rs rt registers)
  two-reg-contract
  (define s (signed->unsigned (hash-ref registers rs) 32))
  (define t (signed->unsigned (hash-ref registers rt) 32))
  (if (= t 0) (raise-user-error "CPU error: Division by zero") #t)
  (hash-set
    (hash-set 'HI (remainder s t))
    'LO
    (quotient s t)))

;; mfhi :: $d = $HI
(define/contract
  (mfhi rd registers)
  one-reg-contract
  (hash-set registers rd (hash-ref 'HI)))

;; mflo :: $d = $LO
(define/contract
  (mflo rd registers)
  one-reg-contract
  (hash-set registers rd (hash-ref 'LO)))


;; lis :: d = MEM[pc]; pc += 4
(define/contract
  (lis rd registers mem)
  ((unsigned-number-size-n? 5) immutable-hash? sparse-list? . -> . immutable-hash?)
  (define loaded
    (unsigned->signed
      (+
	(arithmetic-shift (sparse-list-ref mem (+ 0 (hash-ref registers 'PC))) 24)
	(arithmetic-shift (sparse-list-ref mem (+ 1 (hash-ref registers 'PC))) 16)
	(arithmetic-shift (sparse-list-ref mem (+ 2 (hash-ref registers 'PC)))  8)
	(arithmetic-shift (sparse-list-ref mem (+ 3 (hash-ref registers 'PC)))  0)) 32))
  (hash-set
    (hash-set registers rd loaded)
    'PC
    (+ 4 (hash-ref registers 'PC))))

;; slt :: $d = 1 if $s < $t; 0 otherwise
(define/contract
  (slt rs rt rd registers)
  three-reg-contract
  (hash-set registers
	    rd
	    (cond
	      [(< rs rt) 1]
	      [else 0])))

;; sltu :: $d = 1 if $s < $t; 0 otherwise
(define/contract
  (sltu rs rt rd registers)
  three-reg-contract
  (define s (signed->unsigned (hash-ref registers rs) 32))
  (define t (signed->unsigned (hash-ref registers rt) 32))
  (hash-set registers
	    rd
	    (cond
	      [(< s t) 1]
	      [else 0])))

;; jr :: pc = $s
(define/contract
  (jr rs registers)
  one-reg-contract
  (hash-set registers
	    'PC
	    (hash-ref registers rs)))

;; jalr :: temp = $s; $31 = pc; $PC = temp
(define/contract
  (jalr rs registers)
  one-reg-contract
  (hash-set
    (hash-set registers rs (hash-ref registers 'PC))
    'PC
    (hash-ref registers rs)))

