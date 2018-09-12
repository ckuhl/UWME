#lang racket

(provide eprint-word ; print a hex-formatted wrd to stderr
	 eprint-registers ; print registers to stderr
	 mmio-write ; write a single byte out
	 format-funct)

(require "constants.rkt" ; magic numbers
	 "registers.rkt" ; registers
	 "word.rkt") ; signed->unsigned


(define/contract
  (eprint-word word)
  (exact-nonnegative-integer? . -> . void?)
  (eprintf
    "~a~n"
    (string-join
      (for/list ([i (reverse (range 0 32 8))]
		 [j (reverse (list #x000000ff #x0000ff00 #x00ff0000 #xff000000))])
	(~r
	  (arithmetic-shift (bitwise-and word j) (- i))
	  #:sign #f
	  #:base 2
	  #:min-width 8
	  #:pad-string "0"))
      " ")))

(define/contract
  (insert-every-n lst v n [c 0])
  ((list? any/c exact-positive-integer?) (exact-nonnegative-integer?) . ->* . list?)
  (cond
    [(empty? lst) empty]
    [(equal? n c) (cons v (insert-every-n lst v n 0))]
    [else (cons (car lst) (insert-every-n (cdr lst) v n (add1 c)))]))

(define/contract
  (eprint-registers registers)
  (registers? . -> . void?)
  (eprintf
    "~a"
    (string-join
      (insert-every-n
	(for/list ([i (append (range 0 32) (list 'PC 'IR 'HI 'LO))])
	  (format "~A: ~A"
		  (~a "$" i #:min-width 3 #:align 'right #:left-pad-string " ")
		  (format-register (hash-ref registers i))))
	"\n"
	4)
      "  "
      #:before-first "  "  ; What the heck. This will gladly overwrite stdout
      #:after-last "\n")))

(define/contract
  (mmio-write byte)
  (byte? . -> . void?)
  (printf "~C" (integer->char byte)))

(define/contract
  (format-register w)
  (exact-integer? . -> . string?)
  (format "0x~a"
	  (~r w
	      #:sign #f
	      #:base 16
	      #:min-width 8
	      #:pad-string "0")))

(define/contract
  (format-funct v)
  (exact-integer? . -> . string?)
  (format "~a"
	  (~r v
	      #:sign #f
	      #:base 2
	      #:min-width 6
	      #:pad-string "0")))

