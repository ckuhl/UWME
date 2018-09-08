#lang racket
(provide (all-defined-out))


; add :: $d = $s + $t
(define (add rs rt rd registers)
  (hash-set registers
	    rd
	    (+ (hash-ref registers rs)
	       (hash-ref registers rt))))

; sub :: $d = $s - $t
(define (sub rs rt rd registers)
  (hash-set registers
	    rd
	    (- (hash-ref rs)
	       (hash-ref rt))))

;; mult :: $HI:$LO = $rs * $rd
;; TODO
;; Determine how to do un/signed math differently in Racket
(define (mult rs rt registers)
  (hash-set
    (hash-set
      'HI
      (bitwise-and #xffffffff00000000
		   (* rs rt)))
    'LO
    (bitwise-and #x00000000ffffffff
		 (* rs rt))))

;; multu :: $HI:$LO = $rs * $rt
;; TODO
;; Determine how to do un/signed math differently in Racket
(define (multu rs rt registers)
  (hash-set
    (hash-set
      'HI
      (bitwise-and #xffffffff00000000
		   (* rs rt)))
    'LO
    (bitwise-and #x00000000ffffffff
		 (* rs rt))))

;; div :: $LO = $s / $t, $HI = $s % $t
;; TODO
;; Determine how to do un/signed math differently in Racket
(define (div rs rt registers)
  (if (= rt 0) (raise-user-error "CPU error: Division by zero") #t)
  (hash-set
    (hash-set 'HI (remainder rs rt))
    'LO
    (quotient rs rt)))

;; divu :: $LO = $s / $t, $HI = $s % $t
;; TODO
;; Determine how to do un/signed math differently in Racket
(define (divu rs rt registers)
  (if (= rt 0) (raise-user-error "CPU error: Division by zero") #t)
  (hash-set
    (hash-set 'HI (remainder rs rt))
    'LO
    (quotient rs rt)))

;; mfhi :: $d = $HI
(define (mfhi rd registers)
  (hash-set registers rd (hash-ref 'HI)))

;; mflo :: $d = $LO
(define (mflo rd registers)
  (hash-set registers rd (hash-ref 'LO)))


;; lis :: d = MEM[pc]
;; TODO
(define (lis rd registers mem)
  (hash-set registers rd (list-ref mem (hash-ref 'PC))))

;; slt :: $d = 1 if $s < $t; 0 otherwise
;; TODO
;; Determine how to do un/signed math differently in Racket
(define (slt rs rt rd registers)
  (hash-set registers
	    rd
	    (cond
	      [(< rs rt) 1]
	      [else 0])))

;; sltu :: $d = 1 if $s < $t; 0 otherwise
;; TODO
;; Determine how to do un/signed math differently in Racket
(define (sltu rs rt rd registers)
  (hash-set registers
	    rd
	    (cond
	      [(< rs rt) 1]
	      [else 0])))

;; jr :: pc = $s
(define (jr rs registers)
  (hash-set registers
	    'PC
	    (hash-ref registers rs)))

;; jalr :: temp = $s; $31 = pc; $PC = temp
(define (jalr rs registers)
  (hash-set
    (hash-set registers rs (hash-ref registers 'PC))
    'PC
    (hash-ref registers rs)))

