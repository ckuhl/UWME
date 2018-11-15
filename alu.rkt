#lang racket/base

; ALU: Mathematical actions on the registerfile

(provide name-to-function) ; decode opcode names to functions

(require racket/contract
         racket/format ; ~r

         "constants.rkt" ; magic numbers
         "memory.rkt" ; memory
         "registerfile.rkt" ; registers
         "word.rkt") ; word


; global configuration
(define show-binary (make-parameter #f))


;; Look up ALU functions by their name
;; Hash of: Identifier -> ((word rf memoryfile) -> (list rf memoryfile))
(define/contract
  name-to-function
  (hash/c symbol? (word? rf? memory? . -> . (list/c rf? memory?)))
  (make-immutable-hash
    (list

      ; add :: $d = $s + $t
      (cons
        'add
        (lambda (w rf mem)
          (list
            (rf-set
              rf
              (word-rd w)
              (signed->bytes
                (+ (bytes->signed (rf-ref rf (word-rs w)))
                   (bytes->signed (rf-ref rf (word-rt w))))))
            mem)))


      ; sub :: $d = $s - $t
      (cons
        'sub
        (lambda
          (w rf mem)
          (list
            (rf-set
              rf
              (word-rd w)
              (signed->bytes (- (bytes->signed (rf-ref rf (word-rs w)))
                                (bytes->signed (rf-ref rf (word-rt w))))))
            mem)))


      ;; mult :: $HI:$LO = $rs * $rd
      (cons
        'mult
        (lambda (w rf mem)
          (define s (bytes->signed (rf-ref rf (word-rs w))))
          (define t (bytes->signed (rf-ref rf (word-rt w))))
          (list
            (rf-set-swap
              rf
              'HI
              (signed->bytes (arithmetic-shift (bitwise-and (* s t) hi-result-mask) ; mask off LO
                                               (- (* word-size 8)))) ; Shift to fit word
              'LO
              (signed->bytes (bitwise-and (* s t) lo-result-mask)))
            mem)))


      ;; multu :: $HI:$LO = $rs * $rt
      (cons
        'multu
        (lambda (w rf mem)
          (define s (bytes->unsigned (rf-ref rf (word-rs w))))
          (define t (bytes->unsigned (rf-ref (word-rt w))))
          (list
            (rf-set-swap
              rf
              'HI (signed->bytes (arithmetic-shift (bitwise-and (* s t) hi-result-mask) (- (* word-size 8))))
              'LO (signed->bytes (bitwise-and (* s t) lo-result-mask)))
            mem)))


      ;; div :: $LO = $s / $t, $HI = $s % $t
      (cons
        'div
        (lambda (w rf mem)
          (define s (bytes->signed (rf-ref rf (word-rs w))))
          (define t (bytes->signed (rf-ref rf (word-rt w))))
          (when (zero? t) (raise-user-error "CPU error: Division by zero"))
          (list
            (rf-set-swap
              rf
              'HI (unsigned->bytes (remainder s t))
              'LO (unsigned->bytes (quotient s t)))
            mem)))


      ;; divu :: $LO = $s / $t, $HI = $s % $t
      (cons
        'divu
        (lambda (w rf mem)
          (define s (bytes->unsigned (rf-ref rf (word-rs w))))
          (define t (bytes->unsigned (rf-ref rf (word-rt w))))
          (when (zero? t) (raise-user-error "CPU error: Division by zero"))
          (list
            (rf-set-swap
              rf
              'HI (unsigned->bytes (remainder s t))
              'LO (unsigned->bytes (quotient s t)))
            mem)))


      ;; mfhi :: $d = $HI
      (cons
        'mfhi
        (lambda (w rf mem)
          (list (rf-set rf (word-rd w) (rf-ref rf 'HI)) mem)))


      ;; mflo :: $d = $LO
      (cons
        'mflo
        (lambda (w rf mem)
          (list (rf-set rf (word-rd w) (rf-ref rf 'LO)) mem)))


      ;; lis :: d = MEM[pc]; pc += 4
      (cons
        'lis
        (lambda (w rf mem)
          (define new-rf
            (rf-set-swap
              rf
              (word-rd w)
              (memory-ref mem (bytes->unsigned (rf-ref rf 'PC)))
              'PC
              (unsigned->bytes
                (+ word-size
                   (bytes->unsigned (rf-ref rf 'PC))))))

          (when (show-binary)
            (printf "~a: ~a~n"
                    (word->hex-string (bytes->word (rf-ref new-rf 'PC)))
                    (word->binary-string (bytes->word (rf-ref new-rf (word-rd w))))))

          (list new-rf mem)))


      ;; slt :: $d = 1 if $s < $t; 0 otherwise
      (cons
        'slt
        (lambda (w rf mem)
          (define s (bytes->signed (rf-ref rf (word-rs w))))
          (define t (bytes->signed (rf-ref rf (word-rt w))))
          (list
            (rf-set rf
                    (word-rd w)
                    (unsigned->bytes (if (< s t) 1 0)))
            mem)))


      ;; sltu :: $d = 1 if $s < $t; 0 otherwise
      (cons
        'sltu
        (lambda (w rf mem)
          (define s (bytes->unsigned (rf-ref rf (word-rs w))))
          (define t (bytes->unsigned (rf-ref rf (word-rt w))))
          (list
            (rf-set rf
                    (word-rd w)
                    (unsigned->bytes (if (< s t) 1 0)))
            mem)))


      ;; jr :: pc = $s
      (cons
        'jr
        (lambda (w rf mem)
          (when (not (zero? (word-rt w)))
            (raise-user-error 'jr "$rt is expected to be zero for opcode jr"))

          (when (not (zero? (word-rd w)))
            (raise-user-error 'jr "$rd is expected to be zero for opcode jr"))

          (list
            (rf-set rf 'PC (rf-ref rf (word-rs w)))
            mem)))


      ;; jalr :: temp = $s; $31 = pc; $PC = temp
      (cons
        'jalr
        (lambda (w rf mem)
          (list
            (rf-set-swap
              rf
              (word-rs w) (rf-ref rf 'PC)
              'PC (rf-ref rf (word-rs w)))
            mem)))

      )))
