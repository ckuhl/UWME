#lang racket/base


(provide (struct-out vm)
         register-get
         register-set
         memory-get
         memory-set
         vm-eprint)


(require racket/format ; ~r
         racket/string ; string-join
         racket/list ; range

         "bytes.rkt")


;; Wrapper for registers / memory / PC
(define-struct vm (rf mem) #:transparent)


;; Internal helper for testing
;; (listof pair?) listof pair? -> vm?
(define (vm-create #:registers register-values #:memory memory-cells)
  (make-vm (make-immutable-hash register-values)
           (make-immutable-hash memory-cells)))


;; get the value of [register] from [machine]
;; NOTE: It is assumed register will be in the range [0, 32)
(define (register-get machine register)
  (hash-ref (vm-rf machine) register))


(module+ test
  (require rackunit)
  (test-equal?
    "Get register"
    (register-get (vm-create #:registers (list (cons 1 1)) #:memory empty)
                  1)
    1))


;; Set [register] to [value] and return updated [machine]
(define (register-set machine register value)
  (cond
    [(zero? register) machine]
    [else (struct-copy
            vm machine
            [rf (hash-set (vm-rf machine) register value)])]))


(module+ test
  (require rackunit)
  (test-equal?
    "Set standard register"
    (register-set (vm-create #:registers (list (cons 1 1)) #:memory empty)
                  1 2)
    (vm-create #:registers (list (cons 1 2)) #:memory empty))

  (test-equal?
    "Set zero register (doesn't change value)"
    (register-set (vm-create #:registers (list (cons 0 0)) #:memory empty)
    0 1)
  (vm-create #:registers (list (cons 0 0)) #:memory empty)))


;; the value at [address] in the [machine]'s memory
(define (memory-get machine address)
  (hash-ref (vm-mem machine) address))


;; set [address] in the [machine]'s memory to [value]
(define (memory-set machine address value)
  (struct-copy
    vm machine
    [mem (hash-set (vm-mem machine) address value)]))


;; Print out the contents of the registers to stderr
(define (vm-eprint machine)
  (define (format-register r)
    (~r r
        #:sign #f
        #:base 10
        #:min-width 2
        #:pad-string "0"))
  (define (format-bytes machine r)
    (~r (bytes->integer (register-get machine r) #:signed? #f)
        #:sign #f
        #:base 16
        #:min-width 8
        #:pad-string "0"))
  (eprintf
    "~A~n"
    (string-join
      (for/list ([i (range 1 32)])
        (format "$~a = 0x~a   ~a"
                (format-register i)
                (format-bytes machine i)
                (if (zero? (modulo i 4)) "\n" ""))) "")))
