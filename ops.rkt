#lang racket

(provide lw sw beq bne)

(require "alu.rkt") ; signed->unsigned
(require "constants.rkt")
(require "sparse-list.rkt")

;; lw :: $t = MEM [$s + i]
(define/contract
  (lw rs rt i registers mem)
  (exact-nonnegative-integer? exact-nonnegative-integer? exact-nonnegative-integer? (and/c hash? hash-equal? immutable?) sparse-list? . -> . (list/c (and/c hash? hash-equal? immutable?) sparse-list?))
  (define addr (+ (hash-ref registers rs) i))
  (if (not (zero? (modulo addr 4))) (raise-user-error 'CPU "Unaligned memory access") #t)
  (if (and
	(or (negative? addr)
	    (> addr MEMORY-SIZE))
	(not (equal? addr mmio-read-address)))
    (raise-user-error 'CPU "Out of bounds memory access at address 0x~x" addr) #t)
  (cond
    [(equal? addr mmio-read-address)
     (list (hash-set registers rt (bitwise-and (read-byte) lsb-mask) mem))]
    [else (list (hash-set registers rt (sparse-list-ref mem addr) mem))]))

;; sw :: MEM [$s + i] = $t
(define/contract
  (sw rs rt i registers mem)
  (exact-nonnegative-integer? exact-nonnegative-integer? exact-nonnegative-integer? (and/c hash? hash-equal? immutable?) sparse-list? . -> . (list/c (and/c hash? hash-equal? immutable?) sparse-list?))
  (define addr (+ (signed->unsigned (hash-ref registers rs) 32) i))
  (if (not (zero? (modulo addr 4))) (raise-user-error 'CPU "Unaligned memory access") #t)
  (if (and
	(or (negative? addr)
	    (> addr MEMORY-SIZE))
	(not (equal? addr mmio-write-address)))
    (raise-user-error 'CPU "Out of bounds memory access at address 0x~x" addr) #t)
  (cond
    [(equal? addr mmio-write-address)
     (write-byte (bitwise-and (hash-ref registers rt) #x000000ff) (current-output-port))
     (list registers mem)]
    [else (list registers (sparse-list-set mem addr rt))]))

;; beq :: if ($s == $t) pc += i * 4
(define/contract
  (beq rs rt i registers)
  (exact-nonnegative-integer? exact-nonnegative-integer? exact-nonnegative-integer? (and/c hash? hash-equal? immutable?) . -> . (and/c hash? hash-equal? immutable?))
  (cond [(equal? rs rt)
	 (hash-set registers
		   'PC
		   (+ (hash-ref registers 'PC)
		      (* i word-size)))]
	[else registers]))

;; bne :: if ($s != $t) pc += i * 4
(define/contract
  (bne rs rt i registers)
  (exact-nonnegative-integer? exact-nonnegative-integer? exact-nonnegative-integer? (and/c hash? hash-equal? immutable?) . -> . (and/c hash? hash-equal? immutable?))
  (cond [(not (equal? rs rt))
	 (hash-set registers
		   'PC
		   (+ (hash-ref registers 'PC)
		      (* i word-size)))]
	[else registers]))

