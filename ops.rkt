#lang racket
(require "constants.rkt")
(provide (all-defined-out))


;; lw :: $t = MEM [$s + i]
(define (lw rs rt i registers mem)
  (hash-set registers
	    rt
	    (list-ref mem (+ (hash-ref registers rs) i))))

;; sw :: MEM [$s + i] = $t
(define (sw rs rt i registers mem)
  (list-set mem
	    (+ (hash-ref registers rs) i)
	    rt))

;; beq :: if ($s == $t) pc += i * 4
(define (beq rs rt i registers)
  (cond [(equal? rs rt)
	 (hash-set registers
		   'PC
		   (+ (hash-ref registers 'PC)
		      (* i word-size)))]
	[else registers]))

;; bne :: if ($s != $t) pc += i * 4
(define (bne rs rt i registers)
  (cond [(not (equal? rs rt))
	 (hash-set registers
		   'PC
		   (+ (hash-ref registers 'PC)
		      (* i word-size)))]
	[else registers]))

