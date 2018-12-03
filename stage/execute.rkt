#lang racket/base

(provide execute)

(require racket/match
         "../vm.rkt"
         "../bytes.rkt"
         "decode.rkt")

;; Execute an instruction
;;  Presently, this covers the EX / MEM / WB stages
(define/match (execute instr)
  [((decoded #b000000 rs rt rd 0 #b100000 _)) (add rs rt rd)]
  [((decoded #b000000 rs rt rd 0 #b100010 _)) (sub rs rt rd)]
  [((decoded #b000000 rs rt  0 0 #b011000 _)) (mult rs rt)]
  [((decoded #b000000 rs rt  0 0 #b011001 _)) (multu rs rt)]
  [((decoded #b000000 rs rt  0 0 #b011010 _)) (div rs rt)]
  [((decoded #b000000 rs rt  0 0 #b011011 _)) (divu rs rt)]
  [((decoded #b000000  0  0 rd 0 #b010000 _)) (mfhi rd)]
  [((decoded #b000000  0  0 rd 0 #b010010 _)) (mflo rd)]
  [((decoded #b000000  0  0 rd 0 #b010100 _)) (lis rd)]
  [((decoded #b100011 rs rt  _ _        _ i)) (lw rs rt i)]
  [((decoded #b101011 rs rt  _ _        _ i)) (sw rs rt i)]
  [((decoded #b000000 rs rt rd 0 #b101010 _)) (slt rs rt rd)]
  [((decoded #b000000 rs rt rd 0 #b101011 _)) (sltu rs rt rd)]
  [((decoded #b000100 rs rt  _ _        _ i)) (beq rs rt i)]
  [((decoded #b000101 rs rt  _ _        _ i)) (bne rs rt i)]
  [((decoded #b000000 rs  0  0 0 #b001000 _)) (jr rs)]
  [((decoded #b000000 rs  0  0 0 #b001001 _)) (jalr rs)]

  ;; catch any bad instructions
  [(unknown) (raise-user-error 'EX "Unknown instruction ~V~n" unknown)])


;; add
(define (add rs rt rd)
  (lambda (machine)
    (define source (register-get machine rs))
    (define target (register-get machine rt))
    (define calculated (bytes-apply + #:signed? #f source target))
    (register-set machine rd calculated)))


;; Subtract
(define (sub rs rt rd)
  (lambda (machine)
    (define source (register-get machine rs))
    (define target (register-get machine rt))
    (define calculated (bytes-apply - #:signed? #f source target))
    (register-set machine rd calculated)))


;; Multiply (signed)
(define (mult rs rt)
  (lambda (machine)
    (define source (register-get machine rs))
    (define target (register-get machine rt))
    (define calculated (bytes-apply * #:signed? #t #:size-n 8 source target))
    (register-set machine 'HILO calculated)))

;; Multiply unsigned
(define (multu rs rt)
  (lambda (machine)
    (define source (register-get machine rs))
    (define target (register-get machine rt))
    (register-set machine 'HILO
                  (bytes-apply * #:signed? #f #:size-n 8 source target))))


;; Divide (signed)
(define (div rs rt)
  (lambda (machine)
    (define source (register-get machine rs))
    (define target (register-get machine rt))
    (define hi (bytes-apply quotient #:signed? #t source target))
    (define lo (bytes-apply remainder #:signed? #t source target))
    (register-set machine 'HILO (bytes-append hi lo))))


;; Divide unsigned
(define (divu rs rt)
  (lambda (machine)
    (define source (register-get machine rs))
    (define target (register-get machine rt))
    (define hi (bytes-apply quotient #:signed? #f source target))
    (define lo (bytes-apply remainder #:signed? #f source target))
    (register-set machine 'HILO (bytes-append hi lo))))


;; Move from $HI
(define (mfhi rd)
  (lambda (machine)
    (define hi (subbytes (register-get machine 'HILO) 0 4))
    (register-set machine rd hi)))


;; Move from $LO
(define (mflo rd)
  (lambda (machine)
    (define lo (subbytes (register-get machine 'HILO) 4 8))
    (register-set machine rd lo)))


;; Load immediate (and) skip
;;   NOTE: This is neither an immediate type instruction, nor does it load
;;   the immediate value
(define (lis rd)
  (lambda (machine)
    (define pc (register-get machine 'PC))
    (define loaded (memory-get machine (bytes->integer pc #:signed? #f)))
    (define next-pc (bytes-apply + #:signed? #t (bytes 4) pc))

    (register-set (register-set machine rd loaded) 'PC next-pc)))


;; Load word (from memory)
(define (lw rs rt i)
  (lambda (machine)
    (define source (register-get machine rs))
    (define address (+ (bytes->integer source #:signed? #f) i))
    (register-set machine rt (memory-get address))))


;; Store word (to memory)
(define (sw rs rt i)
  (lambda (machine)
    (define source (register-get machine rs))
    (define target (register-get machine rt))
    (define address (+ (bytes->integer source #:signed? #f) i))
    (memory-set machine address target)))


;; Set (if) less than
(define (slt rs rt rd)
  (lambda (machine)
    (define source (register-get machine rs))
    (define target (register-get machine rt))
    (define result
      (if (< (bytes->integer source #:signed? #t)
             (bytes->integer target #:signed? #t))
        (bytes 0 0 0 1)
        (bytes 0 0 0 0)))
    (register-set machine rd result)))


;; Set (if) less than; unsigned
(define (sltu rs rt rd)
  (lambda (machine)
    (define source (register-get machine rs))
    (define target (register-get machine rt))
    (define result
      (if (bytes<? source target)
        (bytes 0 0 0 1)
        (bytes 0 0 0 0)))
    (register-set machine rd result)))


;; Break (if) equal
(define (beq rs rt i)
  (lambda (machine)
    (define pc (bytes->integer (register-get machine 'PC) #:signed? #f))
    (define offset
      (cond
        [(equal? (register-get machine rs)
                 (register-get machine rt)) (* 4 i)]
        [else 0]))
    (define new-pc (integer->bytes (+ pc offset) #:size-n 4 #:signed? #f))
    (register-set machine 'PC new-pc)))


;; Break (if) not equal
(define (bne rs rt i)
  (lambda (machine)
    (define pc (bytes->integer (register-get machine 'PC) #:signed? #f))
    (define offset
      (cond
        [(equal? (register-get machine rs)
                 (register-get machine rt)) 0]
        [else (* 4 i)]))
    (define new-pc (integer->bytes (+ pc offset) #:size-n 4 #:signed? #f))
    (register-set machine 'PC new-pc)))


;; Jump register
(define (jr rs)
  (lambda (machine)
    (define source (register-get machine rs))
    (define return-address (bytes #x81 #x23 #x45 #x6c))
    (when (equal? source return-address) (exit))
    (register-set machine 'PC source)))


;; Jump and link register
(define (jalr rs)
  (lambda (machine)
    (define source (register-get machine rs))
    (define pc-value (register-get machine 'PC))
    (register-set (register-set machine 'PC source) rs pc-value)))
