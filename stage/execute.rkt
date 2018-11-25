#lang racket/base

(provide execute)

(require racket/match
         "../boot-vm.rkt"
         "../bytes.rkt"
         "decode.rkt")

;; Execute an instruction -- i.e. calculate a value
(define/match (execute instr)
  [((decoded #b000000 rs rt rd 0 #b100000 _)) (three + rs rt rd)]
  [((decoded #b000000 rs rt rd 0 #b100010 _)) (three - rs rt rd)]
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


;; add / sub
(define (three op rs rt rd)
  (lambda (machine)
    (define rf (vm-rf machine))

    (define source (hash-ref rf rs))
    (define target (hash-ref rf rt))
    (define calculated (unsigned->word
                         (op (bytes->unsigned source)
                             (bytes->unsigned target))))

    (struct-copy
      vm machine
      [rf (hash-set rf rd calculated)])))

;; mult
(define (mult rs rt)
  (lambda (machine)
    (define rf (vm-rf machine))

    (define source (hash-ref rf rs))
    (define target (hash-ref rf rt))
    (define calculated (signed->dword
                         (*  (bytes->signed source)
                             (bytes->signed target))))

    (struct-copy
      vm machine
      [rf (hash-set rf 'HILO calculated)])))

;; multu
(define (multu rs rt)
  (lambda (machine)
    (define rf (vm-rf machine))

    (define source (hash-ref rf rs))
    (define target (hash-ref rf rt))
    (define calculated (unsigned->dword
                         (*  (bytes->unsigned source)
                             (bytes->unsigned target))))

    (struct-copy
      vm machine
      [rf (hash-set rf 'HILO calculated)])))

;; div
(define (div rs rt)
  (lambda (machine)
    (define rf (vm-rf machine))

    (define source (hash-ref rf rs))
    (define target (hash-ref rf rt))

    (define hi (signed->dword
                 (quotient (bytes->signed source)
                           (bytes->signed target))))
    (define lo (signed->dword
                 (remainder (bytes->signed source)
                            (bytes->signed target))))
    (struct-copy
      vm machine
      [rf (hash-set rf 'HILO (bytes-append hi lo))])))

;; divu
(define (divu rs rt)
  (lambda (machine)
    (define rf (vm-rf machine))

    (define source (hash-ref rf rs))
    (define target (hash-ref rf rt))

    (define hi (unsigned->dword
                 (quotient (bytes->unsigned source)
                           (bytes->unsigned target))))
    (define lo (unsigned->dword
                 (remainder (bytes->unsigned source)
                            (bytes->unsigned target))))
    (struct-copy
      vm machine
      [rf (hash-set rf 'HILO (bytes-append hi lo))])))

;; mfhi
(define (mfhi rd)
  (lambda (machine)
    (define rf (vm-rf machine))
    (define hi (subbytes (hash-ref rf 'HILO) 0 4))
    (struct-copy
      vm machine
      [rf (hash-set rf rd hi)])))

;; mflo
(define (mflo rd)
  (lambda (machine)
    (define rf (vm-rf machine))
    (define lo (subbytes (hash-ref rf 'HILO) 4 8))
    (struct-copy
      vm machine
      [rf (hash-set rf rd lo)])))

;; lis
(define (lis rd)
  (lambda (machine)
    (define rf (vm-rf machine))

    (define mem (vm-mem machine))
    (define pc (hash-ref rf 'PC))
    (define loaded (hash-ref mem (bytes->unsigned pc)))
    (define next-pc (unsigned->word (+ 4 (bytes->signed pc))))

    (struct-copy
      vm machine
      [rf (hash-set* rf
                     rd loaded
                     'PC next-pc)])))

(define (lw rs rt i)
  (lambda (machine)
    (define rf (vm-rf machine))
    (define mem (vm-mem machine))

    (define source (hash-ref rf rs))
    (define address (+ (bytes->unsigned source) i))
    (define loaded (hash-ref mem address))

    (struct-copy
      vm machine
      [rf (hash-set rf rt loaded)])))

(define (sw rs rt i)
  (lambda (machine)
    (define rf (vm-rf machine))
    (define mem (vm-mem machine))

    (define source (hash-ref rf rs))
    (define target (hash-ref rf rt))
    (define address (+ (bytes->unsigned source) i))

    (struct-copy
      vm machine
      [mem (hash-set mem address target)])))

;; slt
(define (slt rs rt rd)
  (lambda (machine)
    (define rf (vm-rf machine))

    (define source (hash-ref rf rs))
    (define target (hash-ref rf rt))

    (define result
      (if (< (bytes->signed source) (bytes->signed target))
        (bytes 0 0 0 1)
        (bytes 0 0 0 0)))

    (struct-copy
      vm machine
      [rf (hash-set rf rd result)])))


;; sltu
(define (sltu rs rt rd)
  (lambda (machine)
    (define rf (vm-rf machine))

    (define source (hash-ref rf rs))
    (define target (hash-ref rf rt))

    (define result
      (if (< (bytes->unsigned source) (bytes->unsigned target))
        (bytes 0 0 0 1)
        (bytes 0 0 0 0)))

    (struct-copy
      vm machine
      [rf (hash-set rf rd result)])))

;; beq
(define (beq rs rt i)
  (lambda (machine)
    (define rf (vm-rf machine))

    (define source (hash-ref rf rs))
    (define target (hash-ref rf rt))
    (define pc (hash-ref rf 'PC))

    (define new-pc
      (if (equal? source target)
        (unsigned->word (+ (* 4 i) (bytes->unsigned pc)))
        pc))

    (struct-copy
      vm machine
      [rf (hash-set rf 'PC new-pc)])))


;; bne
(define (bne rs rt i)
  (lambda (machine)
    (define rf (vm-rf machine))

    (define source (hash-ref rf rs))
    (define target (hash-ref rf rt))
    (define pc (hash-ref rf 'PC))

    
    (define new-pc
      (if (equal? source target)
        pc
        (unsigned->word (+ (* 4 i) (bytes->unsigned pc)))))

    (struct-copy
      vm machine
      [rf (hash-set rf 'PC new-pc)])))

(define (jr rs)
  (lambda (machine)
    (define rf (vm-rf machine))

    (define source (hash-ref rf rs))

    (define return-address (bytes #x81 #x23 #x45 #x6c))
    (when (equal? source return-address) (exit))

    (struct-copy
      vm machine
      [rf (hash-set rf 'PC source)])))

(define (jalr rs)
  (lambda (machine)
    (define rf (vm-rf machine))

    (define source (hash-ref rf rs))
    (define pc-value (hash-ref rf 'PC))

    (struct-copy
      vm machine
      [rf (hash-set* rf 'PC source rs pc-value)])))
