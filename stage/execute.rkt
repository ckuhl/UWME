#lang racket/base

(provide execute)

(require racket/match
         "../vm.rkt"
         "../bytes.rkt"
         "decode.rkt")

;; Execute an instruction -- i.e. calculate a value
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
    (define source (get-register machine rs))
    (define target (get-register machine rt))
    (define calculated (unsigned->word
                         (+ (bytes->unsigned source)
                            (bytes->unsigned target))))
    (register-set machine rd calculated)))


;; Subtract
(define (sub rs rt rd)
  (lambda (machine)
    (define source (get-register machine rs))
    (define target (get-register machine rt))
    (define calculated (unsigned->word
                         (- (bytes->unsigned source)
                            (bytes->unsigned target))))
    (register-set machine rd calculated)))


;; Multiply (signed)
(define (mult rs rt)
  (lambda (machine)
    (define source (get-register machine rs))
    (define target (get-register machine rt))
    (define calculated (signed->dword
                         (*  (bytes->signed source)
                             (bytes->signed target))))
    (register-set 'HILO calculated)))

;; Multiply unsigned
(define (multu rs rt)
  (lambda (machine)

    (define source (get-register machine rs))
    (define target (get-register machine rt))
    (define calculated (unsigned->dword
                         (*  (bytes->unsigned source)
                             (bytes->unsigned target))))
    (register-set rf 'HILO calculated)))


;; Divide (signed)
(define (div rs rt)
  (lambda (machine)
    (define source (get-register machine rs))
    (define target (get-register machine rt))
    (define hi (signed->dword
                 (quotient (bytes->signed source)
                           (bytes->signed target))))
    (define lo (signed->dword
                 (remainder (bytes->signed source)
                            (bytes->signed target))))
    (register-set 'HILO (bytes-append hi lo))))


;; Divide unsigned
(define (divu rs rt)
  (lambda (machine)
    (define source (get-register machine rs))
    (define target (get-register machine rt))
    (define hi (unsigned->dword
                 (quotient (bytes->unsigned source)
                           (bytes->unsigned target))))
    (define lo (unsigned->dword
                 (remainder (bytes->unsigned source)
                            (bytes->unsigned target))))
    (register-set machine 'HILO (bytes-append hi lo))))


;; Move from $HI
(define (mfhi rd)
  (lambda (machine)
    (define hi (subbytes (get-register machine 'HILO) 0 4))
    (register-set machine rd hi)))


;; Move from $LO
(define (mflo rd)
  (lambda (machine)
    (define lo (subbytes (get-register machine 'HILO) 4 8))
    (register-set machine rd lo)))


;; Load immediate (and) skip
;;   NOTE: This is neither an immediate type instruction, nor does it load
;;   the immediate value
(define (lis rd)
  (lambda (machine)
    (define mem (vm-mem machine))
    (define pc (get-register machine 'PC))
    (define loaded (hash-ref mem (bytes->unsigned pc)))
    (define next-pc (unsigned->word (+ 4 (bytes->signed pc))))

    (register-set (register-set machine rd loaded) 'PC next-pc)))


;; Load word (from memory)
(define (lw rs rt i)
  (lambda (machine)
    (define source (get-register machine rs))
    (define address (+ (bytes->unsigned source) i))
    (define loaded (memory-get address))
    (register-set rt loaded)))


;; Store word (to memory)
(define (sw rs rt i)
  (lambda (machine)
    (define source (get-register machine rs))
    (define target (get-register machine rt))
    (define address (+ (bytes->unsigned source) i))
    (memory-set address target)))


;; Set (if) less than
(define (slt rs rt rd)
  (lambda (machine)
    (define source (get-register machine rs))
    (define target (get-register machine rt))
    (define result
      (if (< (bytes->signed source) (bytes->signed target))
        (bytes 0 0 0 1)
        (bytes 0 0 0 0)))
    (register-set rd result)))


;; Set (if) less than; unsigned
(define (sltu rs rt rd)
  (lambda (machine)
    (define source (get-register machine rs))
    (define target (get-register machine rt))
    (define result
      (if (< (bytes->unsigned source) (bytes->unsigned target))
        (bytes 0 0 0 1)
        (bytes 0 0 0 0)))
    (register-set rd result)))


;; Break (if) equal
(define (beq rs rt i)
  (lambda (machine)
    (define source (get-register machine rs))
    (define target (get-register machine rt))
    (define pc (get-register machine 'PC))
    (define new-pc
      (if (equal? source target)
        (unsigned->word (+ (* 4 i) (bytes->unsigned pc)))
        pc))
    (register-set'PC new-pc))


  ;; Break (if) not equal
  (define (bne rs rt i)
    (lambda (machine)
      (define source (get-register machine rs))
      (define target (get-register machine rt))
      (define pc (get-register machine 'PC))
      (define new-pc
        (if (equal? source target)
          pc
          (unsigned->word (+ (* 4 i) (bytes->unsigned pc)))))
      (register-set machine 'PC new-pc))


    ;; Jump register
    (define (jr rs)
      (lambda (machine)
        (define source (get-register machine rs))

        (define return-address (bytes #x81 #x23 #x45 #x6c))
        (when (equal? source return-address) (exit))
        (register-set 'PC source)))


    ;; Jump and link register
    (define (jalr rs)
      (lambda (machine)
        (define source (get-register machine rs))
        (define pc-value (get-register machine 'PC)))
      (register-set (register-set machine 'PC source) rs pc-value)))
